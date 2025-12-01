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
from selenium.webdriver.chrome.options import Options

import firebase_admin
from firebase_admin import credentials, firestore

# -------------------------
# Config
# -------------------------
FIREBASE_CRED_PATH = "firebase_config.json"   
BASE_URL = "https://voterportal.sos.la.gov/PropositionText"
HEADLESS = True
IMPLICIT_WAIT = 8
PAGE_LOAD_WAIT = 1.0

# -------------------------
# Init Firebase
# -------------------------
try:
    firebase_admin.get_app()
except ValueError:
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

def clean_proposition_text(text: str) -> str:
    """Clean up proposition text - remove navigation links and extra whitespace"""
    # Remove common navigation phrases
    nav_phrases = [
        r'back to proposition list',
        r'return to.*',
        r'click here.*',
        r'view.*election.*',
        r'home\s*>\s*proposition',
        r'breadcrumb.*',
    ]
    
    for phrase in nav_phrases:
        text = re.sub(phrase, '', text, flags=re.IGNORECASE)
    
    # Remove extra whitespace
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)  # Multiple newlines to double
    text = re.sub(r' +', ' ', text)  # Multiple spaces to single
    
    return text.strip()

def extract_proposition_title(soup: BeautifulSoup, fallback_title: str) -> str:
    """Extract clean proposition title from the page"""
    # Try to find the main title
    # Louisiana SOS usually has title in h1, h2, or strong tags
    
    # Method 1: Look for specific patterns like "Proposition No. X"
    title_pattern = re.compile(r'(.*Proposition.*(?:No\.|Number)\s*\d+.*|.*Fire.*District.*|.*School.*System.*)', re.IGNORECASE)
    
    for tag in ['h1', 'h2', 'h3', 'strong', 'b']:
        elements = soup.find_all(tag)
        for elem in elements:
            text = elem.get_text(strip=True)
            if title_pattern.search(text) and len(text) < 150:
                # Clean the title
                clean_title = text.replace('Proposition Text', '').strip()
                clean_title = re.sub(r':\s*$', '', clean_title)  # Remove trailing colon
                if clean_title:
                    return clean_title
    
    # Method 2: Use the first h1 or h2
    for tag in ['h1', 'h2']:
        elem = soup.find(tag)
        if elem:
            text = elem.get_text(strip=True)
            if text and len(text) < 150 and text.lower() not in ['proposition text', 'home']:
                return text
    
    # Fallback
    return fallback_title

def get_driver():
    options = Options()
    if HEADLESS:
        options.add_argument("--headless=new")
        options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument('--disable-blink-features=AutomationControlled')
    
    driver = webdriver.Chrome(options=options)
    driver.implicitly_wait(IMPLICIT_WAIT)
    return driver

def get_parish_code_from_name(parish_name: str) -> str:
    """Convert parish name to format expected by dropdown"""
    parish_codes = {
        'ACADIA': '01', 'ALLEN': '02', 'ASCENSION': '03', 'ASSUMPTION': '04',
        'AVOYELLES': '05', 'BEAUREGARD': '06', 'BIENVILLE': '07', 'BOSSIER': '08',
        'CADDO': '09', 'CALCASIEU': '10', 'CALDWELL': '11', 'CAMERON': '12',
        'CATAHOULA': '13', 'CLAIBORNE': '14', 'CONCORDIA': '15', 'DE SOTO': '16',
        'EAST BATON ROUGE': '17', 'EAST CARROLL': '18', 'EAST FELICIANA': '19',
        'EVANGELINE': '20', 'FRANKLIN': '21', 'GRANT': '22', 'IBERIA': '23',
        'IBERVILLE': '24', 'JACKSON': '25', 'JEFFERSON': '26', 'JEFFERSON DAVIS': '27',
        'LAFAYETTE': '28', 'LAFOURCHE': '29', 'LA SALLE': '30', 'LINCOLN': '31',
        'LIVINGSTON': '32', 'MADISON': '33', 'MOREHOUSE': '34', 'NATCHITOCHES': '35',
        'ORLEANS': '36', 'OUACHITA': '37', 'PLAQUEMINES': '38', 'POINTE COUPEE': '39',
        'RAPIDES': '40', 'RED RIVER': '41', 'RICHLAND': '42', 'SABINE': '43',
        'ST. BERNARD': '44', 'ST. CHARLES': '45', 'ST. HELENA': '46', 'ST. JAMES': '47',
        'ST. JOHN THE BAPTIST': '48', 'ST. LANDRY': '49', 'ST. MARTIN': '50',
        'ST. MARY': '51', 'ST. TAMMANY': '52', 'TANGIPAHOA': '53', 'TENSAS': '54',
        'TERREBONNE': '55', 'UNION': '56', 'VERMILION': '57', 'VERNON': '58',
        'WASHINGTON': '59', 'WEBSTER': '60', 'WEST BATON ROUGE': '61',
        'WEST CARROLL': '62', 'WEST FELICIANA': '63', 'WINN': '64',
    }
    
    parish_upper = parish_name.strip().upper()
    code = parish_codes.get(parish_upper)
    
    if code:
        return f"{parish_upper} - {code}"
    else:
        print(f"[WARN] Parish code not found for: {parish_name}, using as-is")
        return parish_name

# -------------------------
# Main scraping function
# -------------------------
def scrape_parish_for_election(parish_name: str, election_date: str):
    """Scrape ballot propositions for a parish and election"""
    if ' - ' not in parish_name:
        parish_name = get_parish_code_from_name(parish_name)
    
    print(f"[INFO] Scraping propositions for: {parish_name}, Election: {election_date}")
    
    driver = get_driver()
    driver.get(BASE_URL)
    time.sleep(PAGE_LOAD_WAIT)

    try:
        wait = WebDriverWait(driver, 12)

        # 1) Select election date
        try:
            select_election = Select(driver.find_element(By.ID, "MainContent_ddlElection"))
        except Exception:
            selects = driver.find_elements(By.TAG_NAME, "select")
            select_election = Select(selects[0])

        found = False
        for option in select_election.options:
            if option.text.strip() == election_date:
                select_election.select_by_visible_text(option.text)
                found = True
                break
        if not found:
            print(f"[WARN] Election date '{election_date}' not found. Available:")
            for option in select_election.options:
                print(f"  - {option.text}")
            print("[INFO] Using first option.")
            select_election.select_by_index(0)

        time.sleep(0.8)

        # 2) Select parish
        try:
            select_parish = Select(driver.find_element(By.ID, "MainContent_ddlParish"))
        except Exception:
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
            print(f"[WARN] Parish '{parish_name}' not found.")
            return

        time.sleep(1.2)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

        # 3) Parse proposition links
        page_html = driver.page_source
        soup = BeautifulSoup(page_html, "html.parser")

        link_elements = []
        for a in soup.find_all("a", href=True):
            txt = a.get_text(strip=True)
            if txt and (("Proposition" in txt) or ("Proposed" in txt) or 
                       ("Parish" in txt) or ("Fire" in txt) or ("School" in txt)):
                href = a["href"]
                if "javascript" in href.lower():
                    continue
                link_elements.append((txt, href))

        # Deduplicate
        seen = set()
        links = []
        for txt, href in link_elements:
            key = (txt, href)
            if key in seen:
                continue
            seen.add(key)
            links.append((txt, href))

        print(f"[INFO] Found {len(links)} proposition links.")

        # 4) Visit each link and extract content
        for txt, href in links:
            url = urljoin(BASE_URL, href)
            print(f"[INFO] Fetching: {txt[:60]}...")

            try:
                r = requests.get(url, timeout=12)
                r.raise_for_status()
                prop_soup = BeautifulSoup(r.text, "html.parser")
            except Exception:
                print("[WARN] Using Selenium for this page")
                driver.get(url)
                time.sleep(0.8)
                prop_soup = BeautifulSoup(driver.page_source, "html.parser")

            # Extract main content
            selectors = [
                "div#MainContent_ContentPlaceHolder1",
                "div#MainContent",
                "div#ContentPlaceHolder1",
                "div#Content",
                "div.content",
                "article",
            ]
            
            main_text = None
            for sel in selectors:
                container = prop_soup.select_one(sel)
                if container:
                    # Remove navigation elements
                    for nav in container.select('nav, .breadcrumb, a[href*="PropositionText"]'):
                        nav.decompose()
                    
                    text = container.get_text("\n", strip=True)
                    if len(text) > 80:
                        main_text = clean_proposition_text(text)
                        break

            if not main_text:
                # Fallback
                all_text = prop_soup.get_text(" ", strip=True)
                main_text = clean_proposition_text(all_text)

            # Extract proper title
            title = extract_proposition_title(prop_soup, txt)

            print(f"  Title: {title}")
            print(f"  Text length: {len(main_text)} chars")

            # Save to Firestore
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

            print(f"  Saving to Firestore: {doc_id[:50]}...")
            db.collection("ballot_propositions").document(doc_id).set(data)
            time.sleep(0.25)

        print(f"[INFO] ✅ Scrape finished! Saved {len(links)} propositions.")

    except Exception as err:
        print(f"[ERROR] {err}")
        import traceback
        traceback.print_exc()
    finally:
        driver.quit()


def scrape_for_user(user_id: str, election_date: str = None):
    """Scrape for a specific user based on their parish"""
    print(f"[INFO] Fetching propositions for user: {user_id}")
    
    try:
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            print(f"[ERROR] User not found: {user_id}")
            return
        
        user_data = user_doc.to_dict()
        parish = user_data.get('voter_parish')
        
        if not parish:
            print("[ERROR] User has no voter_parish")
            return
        
        print(f"[INFO] User's parish: {parish}")
        
        if not election_date:
            election_date = "11/15/2025"
            print(f"[INFO] Using default election: {election_date}")
        
        scrape_parish_for_election(parish, election_date)
        
        print(f"[INFO] ✅ Done! Propositions saved for {parish}")
        
    except Exception as e:
        print(f"[ERROR] {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
        election_date = sys.argv[2] if len(sys.argv) > 2 else None
        scrape_for_user(user_id, election_date)
    else:
        PARISH = "EAST BATON ROUGE - 17"
        ELECTION = "11/15/2025"
        scrape_parish_for_election(PARISH, ELECTION)