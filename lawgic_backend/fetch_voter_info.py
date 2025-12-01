"""
Complete Voter Info Fetcher
Fetches voter information AND voting location, updates Firestore
"""

from scraper_user_info import get_complete_voter_info
import firebase_admin
from firebase_admin import credentials, firestore
import sys

# Initialize Firebase
try:
    cred = credentials.Certificate("firebase_config.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase initialized")
except Exception as e:
    print(f"❌ Error initializing Firebase: {e}")
    print("Make sure firebase_config.json is in the current directory")
    sys.exit(1)


def fetch_and_save_complete_info(user_id: str, first_name: str, last_name: str,
                                 zip_code: str, birth_month: int, birth_year: int):
    """
    Fetch complete voter info (registration + voting location) and save to Firestore
    """
    print("\n" + "="*60)
    print("FETCHING COMPLETE VOTER INFORMATION")
    print("="*60)
    print(f"User ID: {user_id}")
    print(f"Name: {first_name} {last_name}")
    print(f"ZIP: {zip_code}")
    print(f"Birth: {birth_month}/{birth_year}")
    print("="*60 + "\n")
    
    # Fetch voter info + location
    print("🔍 Scraping Louisiana SOS voter portal...")
    result = get_complete_voter_info(
        first_name=first_name,
        last_name=last_name,
        zip_code=zip_code,
        birth_month=birth_month,
        birth_year=birth_year,
        headless=True  # Set to False to see browser
    )
    
    if not result.get('success'):
        print(f"\n❌ Error: {result.get('error')}")
        return False
    
    # Display results
    print("\n✅ Voter information found!")
    print("\n📋 Voter Registration:")
    print(f"  Status: {result.get('status', 'N/A')}")
    print(f"  Parish: {result.get('parish', 'N/A')}")
    print(f"  Ward/Precinct: {result.get('ward_precinct', 'N/A')}")
    print(f"  Party: {result.get('party', 'N/A')}")
    
    if result.get('voting_location_name') or result.get('voting_location_address'):
        print("\n📍 Voting Location:")
        if result.get('voting_location_name'):
            print(f"  Name: {result['voting_location_name']}")
        if result.get('voting_location_address'):
            print(f"  Address: {result['voting_location_address']}")
    else:
        print("\n📍 Voting Location: Not found")
    
    # Update Firestore
    print("\n📝 Updating Firestore...")
    try:
        update_data = {}
        
        # Add voter registration fields
        if result.get('status'):
            update_data['voter_status'] = result['status']
        if result.get('parish'):
            update_data['voter_parish'] = result['parish']
        if result.get('ward_precinct'):
            update_data['voter_ward_precinct'] = result['ward_precinct']
        if result.get('party'):
            update_data['voter_party'] = result['party']
        if result.get('name'):
            update_data['voter_full_name'] = result['name']
        
        # Add voting location fields
        if result.get('voting_location_name'):
            update_data['voting_location_name'] = result['voting_location_name']
        if result.get('voting_location_address'):
            update_data['voting_location_address'] = result['voting_location_address']
        
        # Update timestamp
        update_data['voter_info_updated_at'] = firestore.SERVER_TIMESTAMP
        
        # Save to Firestore
        db.collection('users').document(user_id).update(update_data)
        print("✅ Firestore updated successfully!")
        
        print("\n" + "="*60)
        print("DONE! User's voter information has been saved.")
        print("="*60)
        print("\nFirestore fields updated:")
        for key, value in update_data.items():
            if key != 'voter_info_updated_at':
                print(f"  {key}: {value}")
        
        print("\nNext steps:")
        print("1. Open your Flutter app")
        print("2. Log in with this user account")  
        print("3. Go to the Map tab")
        print("4. You should see:")
        print(f"   - Ward: {result.get('ward_precinct', 'N/A')}")
        if result.get('voting_location_name'):
            print(f"   - Location: {result['voting_location_name']}")
        if result.get('voting_location_address'):
            print(f"   - Address: {result['voting_location_address']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error updating Firestore: {e}")
        return False


def fetch_from_firestore(user_id: str):
    """Get user data from Firestore and fetch complete voter info"""
    print(f"📖 Reading user data from Firestore for: {user_id}")
    
    try:
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            print(f"❌ User document not found: {user_id}")
            return False
        
        user_data = user_doc.to_dict()
        
        # Check if user has required fields
        required_fields = ['first_name', 'last_name', 'zip_code', 'birth_month', 'birth_year']
        missing_fields = [f for f in required_fields if f not in user_data]
        
        if missing_fields:
            print(f"❌ User is missing required fields: {', '.join(missing_fields)}")
            print("User needs to have: first_name, last_name, zip_code, birth_month, birth_year")
            return False
        
        # Fetch and save
        return fetch_and_save_complete_info(
            user_id=user_id,
            first_name=user_data['first_name'],
            last_name=user_data['last_name'],
            zip_code=user_data['zip_code'],
            birth_month=user_data['birth_month'],
            birth_year=user_data['birth_year']
        )
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def interactive_mode():
    """Interactive mode to enter user information"""
    print("\n" + "="*60)
    print("INTERACTIVE VOTER INFO FETCHER")
    print("="*60)
    print("\nEnter user information:\n")
    
    user_id = input("Firebase User ID (get from Firebase Console): ").strip()
    if not user_id:
        print("❌ User ID is required")
        return
    
    # Check if it should fetch from Firestore
    fetch_from_db = input("\nFetch user data from Firestore? (y/n): ").strip().lower()
    
    if fetch_from_db == 'y':
        fetch_from_firestore(user_id)
    else:
        first_name = input("First Name: ").strip()
        last_name = input("Last Name: ").strip()
        zip_code = input("ZIP Code (5 digits): ").strip()
        birth_month = int(input("Birth Month (1-12): ").strip())
        birth_year = int(input("Birth Year (YYYY): ").strip())
        
        fetch_and_save_complete_info(
            user_id, first_name, last_name, zip_code, birth_month, birth_year
        )


if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Command line mode
        user_id = sys.argv[1]
        fetch_from_firestore(user_id)
    else:
        # Interactive mode
        interactive_mode()