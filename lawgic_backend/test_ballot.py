#!/usr/bin/env python3
"""
Quick test script for ballot proposition scraper
"""

from scraper_voting import scrape_for_user
import sys

def main():
    print("="*70)
    print("BALLOT PROPOSITION SCRAPER TEST")
    print("="*70)
    print()
    
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
    else:
        user_id = input("Enter Firebase User ID: ").strip()
    
    if not user_id:
        print("❌ User ID required")
        return
    
    election_date = input("Election date (press Enter for default '11/15/2025'): ").strip()
    if not election_date:
        election_date = None  # Will use default
    
    print()
    print("Starting scrape...")
    print()
    
    try:
        scrape_for_user(user_id, election_date)
        
        print()
        print("="*70)
        print("✅ SUCCESS!")
        print("="*70)
        print()
        
        
    except Exception as e:
        print()
        print("="*70)
        print("❌ ERROR")
        print("="*70)
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()