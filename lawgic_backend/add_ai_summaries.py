"""
Generate AI Summaries for Ballot Propositions
Uses Google Gemini AI to create plain-language summaries
"""

import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.generativeai as genai
import sys
import time

# Import API key from config file
try:
    from config_key import GEMINI_API_KEY
except ImportError:
    GEMINI_API_KEY = None

# Initialize Firebase
try:
    firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate("firebase_config.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Initialize Gemini AI
# Validate API key
if not GEMINI_API_KEY or GEMINI_API_KEY == 'YOUR_GEMINI_API_KEY_HERE':
    print("="*60)
    print("ERROR: Gemini API key not found!")
    print("="*60)
    print("Please add your API key:")
    print()
    print("1. Open: lib/config/api_keys.dart")
    print("2. Copy your Gemini API key")
    print("3. Open: config_keys.py") 
    print("4. Paste the key: GEMINI_API_KEY = 'your_key_here'")
    print("5. Save and run this script again")
    print("="*60)
    sys.exit(1)

genai.configure(api_key=GEMINI_API_KEY)

# Use the latest Gemini model
# Options: 'gemini-1.5-flash' (faster, free) or 'gemini-1.5-pro' (better quality)
model = genai.GenerativeModel('gemini-1.5-flash')

def generate_summary(title: str, full_text: str) -> dict:
    """
    Generate a plain-language summary of a ballot proposition
    Returns dict with summary and key_points
    """
    print(f"  [AI] Generating summary for: {title[:50]}...")
    
    prompt = f"""You are helping voters understand ballot propositions. 

Proposition Title: {title}

Full Text:
{full_text[:3000]}  

Please provide:
1. A 2-3 sentence plain-language summary that explains what this proposition does
2. 3-5 key points voters should know
3. What a YES vote means
4. What a NO vote means

Format your response as:

SUMMARY:
[Your plain-language summary here]

KEY POINTS:
- [Point 1]
- [Point 2]
- [Point 3]

YES VOTE:
[What happens if proposition passes]

NO VOTE:
[What happens if proposition fails]

Keep language simple and objective. Avoid political bias."""

    try:
        response = model.generate_content(prompt)
        text = response.text
        
        # Parse the response
        sections = {}
        current_section = None
        current_text = []
        
        for line in text.split('\n'):
            line = line.strip()
            if line.startswith('SUMMARY:'):
                current_section = 'summary'
                current_text = []
            elif line.startswith('KEY POINTS:'):
                if current_section:
                    sections[current_section] = '\n'.join(current_text).strip()
                current_section = 'key_points'
                current_text = []
            elif line.startswith('YES VOTE:'):
                if current_section:
                    sections[current_section] = '\n'.join(current_text).strip()
                current_section = 'yes_vote'
                current_text = []
            elif line.startswith('NO VOTE:'):
                if current_section:
                    sections[current_section] = '\n'.join(current_text).strip()
                current_section = 'no_vote'
                current_text = []
            elif line:
                current_text.append(line)
        
        # Add last section
        if current_section:
            sections[current_section] = '\n'.join(current_text).strip()
        
        print(f"  [AI] ✓ Summary generated")
        return {
            'summary': sections.get('summary', ''),
            'key_points': sections.get('key_points', ''),
            'yes_vote': sections.get('yes_vote', ''),
            'no_vote': sections.get('no_vote', ''),
            'generated_at': firestore.SERVER_TIMESTAMP
        }
        
    except Exception as e:
        print(f"  [AI] Error generating summary: {e}")
        return None


def add_summaries_to_all_propositions():
    """Add AI summaries to all propositions that don't have them"""
    print("="*60)
    print("ADDING AI SUMMARIES TO BALLOT PROPOSITIONS")
    print("="*60)
    
    # Get all propositions in smaller batches to avoid timeout
    count = 0
    updated = 0
    skipped = 0
    failed = 0
    
    try:
        # Fetch in batches of 10 to avoid timeout
        batch_size = 10
        last_doc = None
        
        while True:
            # Query for next batch
            query = db.collection('ballot_propositions').limit(batch_size)
            
            if last_doc:
                query = query.start_after(last_doc)
            
            try:
                batch = query.get()
                
                if not batch:
                    break  # No more documents
                
                for prop_doc in batch:
                    count += 1
                    prop_id = prop_doc.id
                    prop_data = prop_doc.to_dict()
                    
                    # Skip if already has summary
                    if prop_data.get('ai_summary'):
                        print(f"\n[{count}] Skipping (already has summary): {prop_data.get('title', 'Unknown')[:50]}")
                        skipped += 1
                        continue
                    
                    print(f"\n[{count}] Processing: {prop_data.get('title', 'Unknown')[:50]}")
                    
                    # Generate summary
                    summary_data = generate_summary(
                        title=prop_data.get('title', ''),
                        full_text=prop_data.get('full_text', '')
                    )
                    
                    if summary_data:
                        # Update Firestore
                        try:
                            db.collection('ballot_propositions').document(prop_id).update({
                                'ai_summary': summary_data['summary'],
                                'ai_key_points': summary_data['key_points'],
                                'ai_yes_vote': summary_data['yes_vote'],
                                'ai_no_vote': summary_data['no_vote'],
                                'ai_generated_at': firestore.SERVER_TIMESTAMP
                            })
                            updated += 1
                            print(f"  [DB] ✓ Summary saved to Firestore")
                        except Exception as e:
                            print(f"  [DB] ✗ Error saving to Firestore: {e}")
                            failed += 1
                        
                        # Rate limiting - don't spam the API
                        time.sleep(2)
                    else:
                        print(f"  [DB] ✗ Failed to generate summary")
                        failed += 1
                    
                    last_doc = prop_doc
                
                # If batch was smaller than batch_size, we're done
                if len(batch) < batch_size:
                    break
                    
            except Exception as e:
                print(f"\n[ERROR] Error fetching batch: {e}")
                print("Continuing with next batch...")
                if last_doc:
                    continue
                else:
                    break
    
    except Exception as e:
        print(f"\n[ERROR] Fatal error: {e}")
    
    print("\n" + "="*60)
    print(f"COMPLETE: Processed {count} propositions")
    print(f"  Updated: {updated}")
    print(f"  Skipped: {skipped}")
    print(f"  Failed: {failed}")
    print("="*60)


def add_summary_to_proposition(proposition_id: str):
    """Add AI summary to a specific proposition"""
    print(f"Adding summary to proposition: {proposition_id}")
    
    prop_doc = db.collection('ballot_propositions').document(proposition_id).get()
    
    if not prop_doc.exists:
        print(f"[ERROR] Proposition not found: {proposition_id}")
        return False
    
    prop_data = prop_doc.to_dict()
    
    if prop_data.get('ai_summary'):
        print("[INFO] Proposition already has summary")
        return True
    
    # Generate summary
    summary_data = generate_summary(
        title=prop_data.get('title', ''),
        full_text=prop_data.get('full_text', '')
    )
    
    if summary_data:
        # Update Firestore
        db.collection('ballot_propositions').document(proposition_id).update({
            'ai_summary': summary_data['summary'],
            'ai_key_points': summary_data['key_points'],
            'ai_yes_vote': summary_data['yes_vote'],
            'ai_no_vote': summary_data['no_vote'],
            'ai_generated_at': firestore.SERVER_TIMESTAMP
        })
        print("[SUCCESS] Summary added!")
        return True
    else:
        print("[ERROR] Failed to generate summary")
        return False


if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Add summary to specific proposition
        proposition_id = sys.argv[1]
        add_summary_to_proposition(proposition_id)
    else:
        # Add summaries to all propositions
        add_summaries_to_all_propositions()