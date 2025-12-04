#!/usr/bin/env python3
"""
Background Scraper Service
Monitors Firestore for new users and automatically runs scrapers
"""

import time
import subprocess
import threading
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate("firebase_config.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Configuration
CHECK_INTERVAL = 60  # Check every 60 seconds

# Your actual scraper file names
VOTER_SCRAPER_PATH = "fetch_voter_info.py"
BALLOT_SCRAPER_PATH = "scraper_voting.py"

# Parish code mapping for auto-fixing
PARISH_CODES = {
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

class ScraperService:
    def __init__(self):
        self.running = True
        self.processed_users = set()  # Keep track of processed users
        
        # Verify scraper files exist
        import os
        print("\n🔍 Checking for scraper files...")
        if not os.path.exists(VOTER_SCRAPER_PATH):
            print(f"❌ Voter scraper not found: {VOTER_SCRAPER_PATH}")
            print(f"   Current directory: {os.getcwd()}")
        else:
            print(f"✅ Found voter scraper: {VOTER_SCRAPER_PATH}")
            
        if not os.path.exists(BALLOT_SCRAPER_PATH):
            print(f"❌ Ballot scraper not found: {BALLOT_SCRAPER_PATH}")
        else:
            print(f"✅ Found ballot scraper: {BALLOT_SCRAPER_PATH}")
        print()
        
    def load_processed_users(self):
        """Load list of users we've already processed"""
        try:
            # Check scraper_log collection for already processed users
            logs = db.collection('scraper_log').stream()
            for log in logs:
                data = log.to_dict()
                if data.get('status') == 'completed':
                    self.processed_users.add(data['user_id'])
            print(f"Loaded {len(self.processed_users)} processed users")
        except Exception as e:
            print(f"Error loading processed users: {e}")
    
    def fix_parish_format(self, user_id):
        """Automatically fix parish format after scraping"""
        try:
            user_ref = db.collection('users').document(user_id)
            user_doc = user_ref.get()
            
            if not user_doc.exists:
                return False
            
            user_data = user_doc.to_dict()
            current_parish = user_data.get('voter_parish')
            
            if not current_parish:
                return False
            
            # Check if already in correct format
            if ' - ' in current_parish:
                return True
            
            # Get parish code
            parish_upper = current_parish.strip().upper()
            code = PARISH_CODES.get(parish_upper)
            
            if not code:
                print(f"     ⚠️  Could not find code for parish: {current_parish}")
                return False
            
            # Create new format
            new_parish = f"{parish_upper} - {code}"
            
            # Update Firestore
            user_ref.update({'voter_parish': new_parish})
            print(f"     ✓ Fixed parish format: {current_parish} → {new_parish}")
            return True
            
        except Exception as e:
            print(f"     Error fixing parish format: {e}")
            return False
    
    def log_scraper_run(self, user_id, scraper_type, status, error=None):
        """Log scraper execution to Firestore"""
        try:
            db.collection('scraper_log').add({
                'user_id': user_id,
                'scraper_type': scraper_type,
                'status': status,
                'error': error,
                'timestamp': firestore.SERVER_TIMESTAMP,
            })
        except Exception as e:
            print(f"Error logging scraper run: {e}")
    
    def check_for_new_voter_info(self):
        """Check for users who need voter info scraped"""
        try:
            # Get ALL users (can't use multiple != filters in Firestore)
            users = db.collection('users').stream()
            
            for user_doc in users:
                user_id = user_doc.id
                user_data = user_doc.to_dict()
                
                # Skip if already processed
                if user_id in self.processed_users:
                    continue
                
                # Check if user has the required info
                has_zip = user_data.get('zip_code') is not None
                has_birth_month = user_data.get('birth_month') is not None
                has_birth_year = user_data.get('birth_year') is not None
                has_voter_parish = user_data.get('voter_parish') is not None
                
                # Only scrape if has ZIP + birth but NO voter_parish
                if has_zip and has_birth_month and has_birth_year and not has_voter_parish:
                    print(f"\n🔍 Found new user needing voter info: {user_id}")
                    print(f"   ZIP: {user_data.get('zip_code')}")
                    print(f"   Birth: {user_data.get('birth_month')}/{user_data.get('birth_year')}")
                    self.run_voter_scraper(user_id)
                
        except Exception as e:
            print(f"Error checking for new voter info: {e}")
    
    def check_for_new_ballot_needs(self):
        """Check for users who need ballot propositions scraped"""
        try:
            # Get users with voter_parish
            users = db.collection('users').stream()
            
            parishes_to_scrape = set()
            
            for user_doc in users:
                user_data = user_doc.to_dict()
                parish = user_data.get('voter_parish')
                
                if not parish:
                    continue
                
                # Check if we already decided to scrape this parish
                if parish in parishes_to_scrape:
                    continue
                
                # Check if propositions exist for this parish
                props = db.collection('ballot_propositions')\
                    .where('parish', '==', parish)\
                    .limit(1)\
                    .get()
                
                if not props:
                    print(f"\n🗳️  Found parish needing propositions: {parish}")
                    parishes_to_scrape.add(parish)
            
            # Scrape for each parish (use any user from that parish)
            if parishes_to_scrape:
                for parish in parishes_to_scrape:
                    # Find any user with this parish
                    users = db.collection('users').where('voter_parish', '==', parish).limit(1).get()
                    if users:
                        user_id = users[0].id
                        self.run_ballot_scraper(user_id)
                
        except Exception as e:
            print(f"Error checking for ballot needs: {e}")
    
    def run_voter_scraper(self, user_id):
        """Run voter info scraper for a user"""
        print(f"  ▶️  Starting voter scraper for {user_id}...")
        
        try:
            # Run without capturing output so we can see what's happening
            result = subprocess.run(
                ['python', VOTER_SCRAPER_PATH, user_id],
                timeout=120,  # 2 minute timeout
                # Don't capture output - let it print to console
                stdin=subprocess.PIPE,
                text=True
            )
            
            if result.returncode == 0:
                print(f"  ✅ Voter scraper completed for {user_id}")
                self.processed_users.add(user_id)
                self.log_scraper_run(user_id, 'voter_info', 'completed')
                
                # Verify data was actually saved to Firestore
                try:
                    user_doc = db.collection('users').document(user_id).get()
                    if user_doc.exists and user_doc.to_dict().get('voter_parish'):
                        print(f"     ✓ Verified: Parish saved to Firestore")
                        
                        # Auto-fix parish format
                        self.fix_parish_format(user_id)
                    else:
                        print(f"     ⚠️  Warning: No parish data in Firestore")
                except:
                    pass
            else:
                print(f"  ❌ Voter scraper failed for {user_id}")
                print(f"     Return code: {result.returncode}")
                self.log_scraper_run(user_id, 'voter_info', 'failed', f"Exit code {result.returncode}")
                
        except subprocess.TimeoutExpired:
            print(f"  ⏱️  Voter scraper timed out for {user_id}")
            self.log_scraper_run(user_id, 'voter_info', 'timeout')
        except Exception as e:
            print(f"  ❌ Error running voter scraper: {e}")
            self.log_scraper_run(user_id, 'voter_info', 'error', str(e))
    
    def run_ballot_scraper(self, user_id):
        """Run ballot proposition scraper for a user"""
        print(f"  ▶️  Starting ballot scraper for {user_id}...")
        
        try:
            result = subprocess.run(
                ['python', BALLOT_SCRAPER_PATH, user_id],
                timeout=180,  # 3 minute timeout
                stdin=subprocess.PIPE,
                text=True
            )
            
            if result.returncode == 0:
                print(f"  ✅ Ballot scraper completed for {user_id}")
                self.log_scraper_run(user_id, 'ballot_propositions', 'completed')
                
                # Verify propositions were saved
                try:
                    user_doc = db.collection('users').document(user_id).get()
                    if user_doc.exists:
                        parish = user_doc.to_dict().get('voter_parish')
                        if parish:
                            props = db.collection('ballot_propositions').where('parish', '==', parish).limit(1).get()
                            if props:
                                print(f"     ✓ Verified: {len(props)} proposition(s) in Firestore")
                            else:
                                print(f"     ⚠️  Warning: No propositions found for {parish}")
                except:
                    pass
            else:
                print(f"  ❌ Ballot scraper failed for {user_id}")
                print(f"     Return code: {result.returncode}")
                self.log_scraper_run(user_id, 'ballot_propositions', 'failed', f"Exit code {result.returncode}")
                
        except subprocess.TimeoutExpired:
            print(f"  ⏱️  Ballot scraper timed out for {user_id}")
            self.log_scraper_run(user_id, 'ballot_propositions', 'timeout')
        except Exception as e:
            print(f"  ❌ Error running ballot scraper: {e}")
            self.log_scraper_run(user_id, 'ballot_propositions', 'error', str(e))
    
    def run(self):
        """Main service loop"""
        print("="*60)
        print("🚀 SCRAPER SERVICE STARTING")
        print("="*60)
        
        # Show what scrapers were found
        if VOTER_SCRAPER_PATH:
            print(f"✅ Voter scraper: {VOTER_SCRAPER_PATH}")
        else:
            print("❌ Voter scraper: NOT FOUND")
            print("   Please ensure voter scraper is in this directory")
            
        if BALLOT_SCRAPER_PATH:
            print(f"✅ Ballot scraper: {BALLOT_SCRAPER_PATH}")
        else:
            print("❌ Ballot scraper: NOT FOUND")
            print("   Please ensure ballot scraper is in this directory")
        
        print(f"Checking for new users every {CHECK_INTERVAL} seconds")
        print("Press Ctrl+C to stop")
        print("="*60)
        
        # Load previously processed users
        self.load_processed_users()
        
        while self.running:
            try:
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print(f"\n[{timestamp}] 🔄 Checking for new scrapers to run...")
                
                # Check for users needing voter info
                self.check_for_new_voter_info()
                
                # Check for users needing ballot propositions
                self.check_for_new_ballot_needs()
                
                print(f"[{timestamp}] ✓ Check complete. Sleeping {CHECK_INTERVAL}s...")
                
                # Sleep with periodic heartbeat
                for i in range(CHECK_INTERVAL):
                    time.sleep(1)
                    if i > 0 and i % 20 == 0:  # Print every 20 seconds
                        print(f"  ... still running ({CHECK_INTERVAL - i}s remaining)")
                
                print(f"\n{'='*60}")
                print(f"Processed {len(self.processed_users)} users so far")
                print(f"{'='*60}")
                
            except KeyboardInterrupt:
                print("\n\n🛑 Shutting down service...")
                self.running = False
            except Exception as e:
                print(f"\n❌ Error in main loop: {e}")
                time.sleep(CHECK_INTERVAL)
        
        print("👋 Service stopped")


def main():
    service = ScraperService()
    service.run()


if __name__ == "__main__":
    main()