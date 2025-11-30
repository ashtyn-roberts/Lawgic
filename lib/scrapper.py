# scrape_propositions.py
import time
import re
from datetime import datetime
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.support.ui import Select, WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

import firebase_admin
from firebase_admin import credentials, firestore

# -------------------------
# Config
# -------------------------
FIREBASE_CRED_PATH = "firebase_config.json"   # <--- put your service account here
BASE_URL = "https://voterportal.sos.la.gov/PropositionText"
HEADLESS = True               # set False for debugging (shows browser)
IMPLICIT_WAIT = 8             # seconds
PAGE_LOAD_WAIT = 1.0

# -------------------------
# Init Firebase
# -------------------------
cred = credentials.Certificate(FIREBASE_CRED_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# -------------------------
# Utility helpers
# -------------------------
def sanitize_id(text: str) -> str:
    """Make a filesystem/firestore-friendly id."""
    text = re.sub(r'\s+', '_', text.strip())
    text = re.sub(r'[^A-Za-z0-9_\-]', '', text)
    return text.lower()[:200]

def get_driver():
    options = webdriver.ChromeOptions()
    if HEADLESS:
        options.add_argument("--headless=new")
        options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(ChromeDriverManager().install(), options=options)
    driver.implicitly_wait(IMPLICIT_WAIT)
    return driver

# -------------------------
# Main scraping function
# -------------------------
def scrape_parish_for_election(parish_name: str, election_date: str):
    """
    parish_name: EXACT text as appears in the 'Parish' dropdown on the page (example: "EAST BATON ROUGE - 17")
    election_date: EXACT value as appears in the 'Election' dropdown (example: "11/15/2025")
    """
    driver = get_driver()
    driver.get(BASE_URL)
    time.sleep(PAGE_LOAD_WAIT)

    try:
        wait = WebDriverWait(driver, 12)

        # 1) Select election date dropdown
        # Try to find a SELECT element for the election date
        try:
            select_election = Select(driver.find_element(By.ID, "MainContent_ddlElection"))
        except Exception:
            # fallback: find by name or first select
            selects = driver.find_elements(By.TAG_NAME, "select")
            select_election = Select(selects[0])

        # Set election option (matching visible text)
        found = False
        for option in select_election.options:
            if option.text.strip() == election_date:
                select_election.select_by_visible_text(option.text)
                found = True
                break
        if not found:
            print(f"[WARN] Election date '{election_date}' not found in dropdown. Using first option.")
            select_election.select_by_index(0)

        time.sleep(0.8)

        # 2) Select parish dropdown
        try:
            select_parish = Select(driver.find_element(By.ID, "MainContent_ddlParish"))
        except Exception:
            # fallback - try second select element
            selects = driver.find_elements(By.TAG_NAME, "select")
            if len(selects) > 1:
                select_parish = Select(selects[1])
            else:
                raise RuntimeError("Could not locate parish select element.")

        found = False
        for option in select_parish.options:
            if option.text.strip().upper() == parish_name.strip().upper():
                select_parish.select_by_visible_text(option.text)
                found = True
                break
        if not found:
            print(f"[WARN] Parish '{parish_name}' not found. Using first available parish.")
            select_parish.select_by_index(0)

        # Wait for the page to update proposition links (the page may use postback)
        time.sleep(1.2)
        # If the page triggers a server postback, we ensure new content is loaded:
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

        # 3) Parse the resulting proposition list area
        page_html = driver.page_source
        soup = BeautifulSoup(page_html, "html.parser")

        # Try to find the block that lists propositions (bullet list or links)
        # The site has links with <a> elements; search for likely anchors beneath the content area
        candidates = soup.select("div#MainContent_ContentPlaceHolder1, div#Content, div.ms-rtestate-field, div.content, div.container")
        link_elements = []

        # Collect anchors that look like proposition links
        for a in soup.find_all("a", href=True):
            txt = a.get_text(strip=True)
            # heuristics: names containing 'Proposition' or 'Parish' or contain 'Proposition No.' or look non-empty
            if txt and (("Proposition" in txt) or ("Proposed" in txt) or ("Parish" in txt) or ("Fire" in txt) or len(txt) < 120):
                # skip top nav links by checking href contains 'PropositionText' or points to a subsequent page
                href = a["href"]
                # keep relative or absolute links that go to a proposition page
                if "javascript" in href.lower():
                    continue
                link_elements.append((txt, href))

        # Deduplicate while preserving order
        seen = set()
        links = []
        for txt, href in link_elements:
            key = (txt, href)
            if key in seen:
                continue
            seen.add(key)
            links.append((txt, href))

        print(f"[INFO] Found {len(links)} candidate links.")

        # 4) Visit each link and extract full text
        for txt, href in links:
            # compute absolute url
            url = urljoin(BASE_URL, href)
            print(f"[INFO] Fetching proposition page: {txt} -> {url}")

            # we will use requests.get for simplicity (faster) and fall back to Selenium if needed
            try:
                r = requests.get(url, timeout=12)
                r.raise_for_status()
                prop_soup = BeautifulSoup(r.text, "html.parser")
            except Exception as e:
                print("[WARN] requests failed, falling back to Selenium:", e)
                driver.get(url)
                time.sleep(0.8)
                prop_soup = BeautifulSoup(driver.page_source, "html.parser")

            # Heuristic extraction of main content: look for article, div with id 'PropositionContent', 'content', or the longest <div>/<p> block
            selectors = [
                "div#MainContent_ContentPlaceHolder1", "div#MainContent", "div#ContentPlaceHolder1",
                "div#Content", "div.content", "article", "div.ms-rtestate-field", "div.container"
            ]
            main_text = None
            for sel in selectors:
                container = prop_soup.select_one(sel)
                if container:
                    text = container.get_text("\n", strip=True)
                    if len(text) > 80:
                        main_text = text
                        break

            if not main_text:
                # fallback: take the largest text block from <div> or <p>
                candidates = prop_soup.find_all(["div", "p"])
                best = ""
                for c in candidates:
                    t = c.get_text(" ", strip=True)
                    if len(t) > len(best):
                        best = t
                main_text = best or prop_soup.get_text(" ", strip=True)

            # Title extraction
            title_candidates = []
            for tag in ["h1", "h2", "h3", "strong", "title"]:
                el = prop_soup.find(tag)
                if el:
                    title_candidates.append(el.get_text(strip=True))
            title = title_candidates[0] if title_candidates else txt

            # Build Firestore document
            doc_id = sanitize_id(f"{parish_name}_{election_date}_{title}")
            data = {
                "title": title,
                "full_text": main_text,
                "full_text_url": url,
                "parish": parish_name,
                "election_date": election_date,
                "source": BASE_URL,
                "scraped_at": datetime.utcnow(),
            }

            # Save to Firestore
            print(f"[INFO] Writing to Firestore doc id: {doc_id}")
            db.collection("ballot_propositions").document(doc_id).set(data)
            time.sleep(0.25)

        print("[INFO] Scrape finished.")

    except Exception as err:
        print("ERROR during scraping:", err)
    finally:
        driver.quit()


# -------------------------
# Example usage
# -------------------------
if __name__ == "__main__":
    # For testing, set these values from your app:
    # parish_name must match the visible text in the parish dropdown (capitalization not strict)
    PARISH = "EAST BATON ROUGE - 17"     # replace with real value from dropdown in UI
    ELECTION = "11/15/2025"             # replace with the election date option

    scrape_parish_for_election(PARISH, ELECTION)
