"""
Fix User Parish Format
Updates user's voter_parish to include parish code
"""

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
    print(f"❌ Error: {e}")
    sys.exit(1)

# Parish code mapping
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

def fix_user_parish(user_id):
    """Fix parish format for a specific user"""
    try:
        # Get user doc
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            print(f"❌ User not found: {user_id}")
            return False
        
        user_data = user_doc.to_dict()
        current_parish = user_data.get('voter_parish')
        
        if not current_parish:
            print("❌ User has no voter_parish field")
            return False
        
        print(f"Current parish: {current_parish}")
        
        # Get parish code
        parish_upper = current_parish.strip().upper()
        code = PARISH_CODES.get(parish_upper)
        
        if not code:
            print(f"⚠️  No code found for parish: {current_parish}")
            print("   Using parish as-is")
            return False
        
        # Create new format
        new_parish = f"{parish_upper} - {code}"
        
        if current_parish == new_parish:
            print(f"✅ Parish already in correct format: {new_parish}")
            return True
        
        print(f"Updating to: {new_parish}")
        
        # Update Firestore
        user_ref.update({'voter_parish': new_parish})
        
        print(f"✅ Updated voter_parish to: {new_parish}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def fix_all_users():
    """Fix parish format for all users"""
    try:
        users = db.collection('users').stream()
        
        count = 0
        updated = 0
        
        for user_doc in users:
            count += 1
            user_id = user_doc.id
            user_data = user_doc.to_dict()
            current_parish = user_data.get('voter_parish')
            
            if not current_parish:
                continue
            
            # Get parish code
            parish_upper = current_parish.strip().upper()
            code = PARISH_CODES.get(parish_upper)
            
            if not code:
                continue
            
            new_parish = f"{parish_upper} - {code}"
            
            if current_parish != new_parish:
                print(f"Updating {user_id}: {current_parish} → {new_parish}")
                db.collection('users').document(user_id).update({
                    'voter_parish': new_parish
                })
                updated += 1
        
        print(f"\n✅ Checked {count} users, updated {updated}")
        
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "--all":
            fix_all_users()
        else:
            user_id = sys.argv[1]
            fix_user_parish(user_id)
    else:
        user_id = input("Enter user ID (or '--all' for all users): ").strip()
        if user_id == "--all":
            fix_all_users()
        else:
            fix_user_parish(user_id)