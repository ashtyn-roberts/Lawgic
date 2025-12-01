"""
Complete Selenium-based Louisiana Voter Scraper
Gets voter registration info AND voting location
"""

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import time
import re
from typing import Dict, Optional


class CompleteVoterScraper:
    """Complete voter scraper - gets registration info AND voting location"""
    
    BASE_URL = "https://voterportal.sos.la.gov"
    SEARCH_URL = f"{BASE_URL}/Home/VoterLogin"
    
    def __init__(self, headless=False):
        self.headless = headless
        self.driver = None
        self.voter_uid = None
    
    def _setup_driver(self):
        """Setup Chrome WebDriver"""
        chrome_options = Options()
        
        if self.headless:
            chrome_options.add_argument('--headless=new')
        
        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        chrome_options.add_argument('--disable-gpu')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--window-size=1920,1080')
        chrome_options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    
    def _find_input_field(self, possible_names, possible_ids=None):
        """Try to find input field by multiple possible names/ids"""
        for name in possible_names:
            try:
                elem = self.driver.find_element(By.NAME, name)
                if elem:
                    return elem, name
            except NoSuchElementException:
                continue
        
        if possible_ids:
            for id_val in possible_ids:
                try:
                    elem = self.driver.find_element(By.ID, id_val)
                    if elem:
                        return elem, id_val
                except NoSuchElementException:
                    continue
        
        for name in possible_names:
            try:
                elem = self.driver.find_element(By.XPATH, f"//input[contains(@name, '{name.lower()}')]")
                if elem:
                    actual_name = elem.get_attribute('name')
                    return elem, actual_name
            except NoSuchElementException:
                continue
        
        return None, None
    
    def get_complete_voter_info(self, first_name: str, last_name: str,
                                zip_code: str, birth_month: int, birth_year: int) -> Dict:
        """Get voter registration info AND voting location"""
        try:
            print("🌐 Starting browser...")
            self._setup_driver()
            
            # Step 1: Login and get basic voter info
            print(f"📄 Loading {self.SEARCH_URL}...")
            self.driver.get(self.SEARCH_URL)
            time.sleep(2)
            
            print("✍️  Filling login form...")
            birth_date = f"{birth_month:02d}/{birth_year}"
            
            # Fill form
            first_name_field, _ = self._find_input_field(['FirstName'])
            last_name_field, _ = self._find_input_field(['LastName'])
            zip_field, _ = self._find_input_field(['ZipCode'])
            dob_field, _ = self._find_input_field(['MonthYear'])
            
            if not all([first_name_field, last_name_field, zip_field, dob_field]):
                return {"success": False, "error": "Could not find all form fields"}
            
            first_name_field.send_keys(first_name.strip().upper())
            last_name_field.send_keys(last_name.strip().upper())
            zip_field.send_keys(zip_code.strip())
            dob_field.send_keys(birth_date)
            
            print(f"  Name: {first_name.upper()} {last_name.upper()}")
            print(f"  ZIP: {zip_code}, DOB: {birth_date}")
            
            # Submit
            print("🔍 Submitting login...")
            submit_button = self.driver.find_element(By.CSS_SELECTOR, "button[type='submit'], input[type='submit']")
            submit_button.click()
            time.sleep(3)
            
            # Check for errors
            try:
                error_elem = self.driver.find_element(By.CLASS_NAME, "alert-danger")
                if error_elem and error_elem.is_displayed():
                    return {"success": False, "error": error_elem.text.strip()}
            except NoSuchElementException:
                pass
            
            # Step 2: Extract basic voter info from results page
            print("📊 Extracting voter registration info...")
            voter_info = self._extract_voter_info()
            
            if not voter_info:
                return {"success": False, "error": "Could not extract voter information"}
            
            # Step 3: Extract voter UID from page
            print("🔑 Looking for voter UID...")
            self.voter_uid = self._extract_voter_uid()
            
            if self.voter_uid:
                print(f"  ✓ Found voter UID: {self.voter_uid[:20]}...")
                
                # Step 4: Navigate to Election Day Voting Location page
                print("📍 Fetching voting location...")
                location_info = self._get_voting_location()
                
                if location_info:
                    voter_info.update(location_info)
                    print("  ✓ Voting location found!")
                else:
                    print("  ⚠️  Could not get voting location")
            else:
                print("  ⚠️  Could not find voter UID - skipping location lookup")
            
            voter_info['success'] = True
            return voter_info
            
        except Exception as e:
            print(f"❌ Error: {e}")
            if self.driver:
                self.driver.save_screenshot('error_screenshot.png')
            import traceback
            traceback.print_exc()
            return {"success": False, "error": f"Unexpected error: {str(e)}"}
        finally:
            if self.driver:
                print("🔒 Closing browser...")
                self.driver.quit()
    
    def _extract_voter_uid(self) -> Optional[str]:
        """Extract voter UID from current page"""
        try:
            # Method 1: Check URL for uid parameter
            current_url = self.driver.current_url
            uid_match = re.search(r'uid=([a-f0-9\-]+)', current_url)
            if uid_match:
                return uid_match.group(1)
            
            # Method 2: Look for links to voting pages
            links = self.driver.find_elements(By.TAG_NAME, "a")
            for link in links:
                href = link.get_attribute('href')
                if href and 'ElectionDayVoting' in href:
                    uid_match = re.search(r'uid=([a-f0-9\-]+)', href)
                    if uid_match:
                        return uid_match.group(1)
                if href and 'uid=' in href:
                    uid_match = re.search(r'uid=([a-f0-9\-]+)', href)
                    if uid_match:
                        return uid_match.group(1)
            
            # Method 3: Check page source
            page_source = self.driver.page_source
            uid_match = re.search(r'uid=([a-f0-9\-]+)', page_source)
            if uid_match:
                return uid_match.group(1)
            
            return None
            
        except Exception as e:
            print(f"Error extracting UID: {e}")
            return None
    
    def _get_voting_location(self) -> Optional[Dict]:
        """Navigate to ElectionDayVoting page and extract location"""
        if not self.voter_uid:
            return None
        
        try:
            location_url = f"{self.BASE_URL}/Voting/Index/ElectionDayVoting?uid={self.voter_uid}"
            print(f"  Loading: {location_url}")
            
            self.driver.get(location_url)
            time.sleep(2)
            
            # Extract location information
            location_info = {}
            
            # Get page text
            body_text = self.driver.find_element(By.TAG_NAME, "body").text
            
            # Look for all-caps location name followed by address
            lines = body_text.split('\n')
            
            for i, line in enumerate(lines):
                line = line.strip()
                
                if line.isupper() and len(line) > 5:
                    # Skip if it's the generic election day voting header
                    if 'ELECTION DAY VOTING' in line:
                        continue
                    # Skip if it's about polling hours
                    if 'POLLING' in line and ('OPEN' in line or 'HOUR' in line):
                        continue
                    
                    if i + 1 < len(lines):
                        next_line = lines[i + 1].strip()
                        # Street address pattern: starts with number
                        if next_line and next_line[0].isdigit():
                            location_info['voting_location_name'] = line
                            location_info['voting_location_address'] = next_line
                            
                            # Check if there's a city/state/zip line
                            if i + 2 < len(lines):
                                city_line = lines[i + 2].strip()
                                if ',' in city_line and any(state in city_line for state in ['LA', 'Louisiana']):
                                    # Append to address
                                    location_info['voting_location_address'] += f", {city_line}"
                            
                            break
            
            # Alternative method: Look for address pattern with regex
            if not location_info.get('voting_location_address'):
                # Look for street address followed by city/state/zip
                address_pattern = re.compile(
                    r'(\d+\s+[A-Z\s]+(?:RD|ROAD|ST|STREET|AVE|AVENUE|BLVD|BOULEVARD|DR|DRIVE|LN|LANE|WAY|BEND))\s*\n?\s*([A-Z\s]+,\s*LA\s+\d{5})',
                    re.IGNORECASE | re.MULTILINE
                )
                
                match = address_pattern.search(body_text)
                if match:
                    street = match.group(1).strip()
                    city_state_zip = match.group(2).strip()
                    location_info['voting_location_address'] = f"{street}, {city_state_zip}"
            
            # Try to extract location name from bold/header tags
            if not location_info.get('voting_location_name'):
                try:
                    # Look for strong/b tags or headers that might contain location name
                    bold_elements = self.driver.find_elements(By.CSS_SELECTOR, "strong, b, h1, h2, h3, h4")
                    for elem in bold_elements:
                        text = elem.text.strip()
                        # All caps, reasonable length, not generic text
                        if text.isupper() and 5 < len(text) < 100:
                            if 'ELECTION' not in text and 'POLLING PLACES' not in text and 'VOTING' not in text:
                                location_info['voting_location_name'] = text
                                break
                except:
                    pass
            
            # Debug: Print what is found
            print("  Debug - Page text sample:")
            # Print lines around where its expected to find location
            for i, line in enumerate(lines[:30]):  # First 30 lines
                if line.strip():
                    print(f"    Line {i}: {line.strip()[:80]}")
            
            # Debug: Save screenshot
            if not self.headless:
                self.driver.save_screenshot('voting_location_page.png')
                print("  📸 Saved screenshot: voting_location_page.png")
            
            # Print what was extracted
            if location_info.get('voting_location_address'):
                print(f"  ✓ Found address: {location_info['voting_location_address']}")
            
            if location_info.get('voting_location_name'):
                print(f"  ✓ Found name: {location_info['voting_location_name']}")
            
            return location_info if location_info else None
            
        except Exception as e:
            print(f"Error getting voting location: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def _extract_voter_info(self) -> Optional[Dict]:
        """Extract voter registration info from current page"""
        voter_info = {}
        
        try:
            body_text = self.driver.find_element(By.TAG_NAME, "body").text
            
            # Use regex to extract info
            name_match = re.search(r'Name[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)', body_text)
            if name_match:
                voter_info['name'] = name_match.group(1).strip()
            
            parish_match = re.search(r'Parish[:\s]+([A-Za-z\s]+?)(?=\s+Ward|Status|Party|Quick)', body_text)
            if parish_match:
                voter_info['parish'] = parish_match.group(1).strip()
            
            ward_match = re.search(r'Ward/Precinct[:\s]+(\d+/\d+)', body_text)
            if ward_match:
                voter_info['ward_precinct'] = ward_match.group(1).strip()
            
            status_match = re.search(r'Status[:\s]+(Active|Inactive)', body_text)
            if status_match:
                voter_info['status'] = status_match.group(1).strip()
            
            party_match = re.search(r'Party[:\s]+([A-Za-z\s]+?)(?=\s+Parish|Status|Ward|Quick)', body_text)
            if party_match:
                voter_info['party'] = party_match.group(1).strip()
            
            return voter_info if voter_info else None
            
        except Exception as e:
            print(f"Error extracting voter info: {e}")
            return None


def get_complete_voter_info(first_name: str, last_name: str, zip_code: str,
                            birth_month: int, birth_year: int, headless: bool = True) -> Dict:
    """Convenience function to get complete voter info including location"""
    scraper = CompleteVoterScraper(headless=headless)
    return scraper.get_complete_voter_info(first_name, last_name, zip_code, birth_month, birth_year)


if __name__ == "__main__":
    print("="*70)
    print("COMPLETE LOUISIANA VOTER SCRAPER")
    print("="*70)
    print()
    
    result = get_complete_voter_info(
        first_name="ASHTYN",
        last_name="ROBERTS",
        zip_code="70817",
        birth_month=7,
        birth_year=2003,
        headless=False  # Set to True to hide browser
    )
    
    print("\n" + "="*70)
    print("COMPLETE RESULT:")
    print("="*70)
    for key, value in result.items():
        print(f"{key}: {value}")