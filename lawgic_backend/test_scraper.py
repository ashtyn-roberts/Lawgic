#!/usr/bin/env python3
"""
Test script for the Louisiana Voter Scraper
Tests the scraper functionality and API endpoints
"""

import requests
import json
from scraper_user_info import get_complete_voter_info

def test_scraper_directly():
    """Test the scraper module directly"""
    print("=" * 60)
    print("TEST 1: Direct Scraper Test")
    print("=" * 60)
    
    print("\nTesting with example data:")
    print("  Name: Ashtyn Roberts")
    print("  ZIP: 70817")
    print("  Birth: July 2003\n")
    
    result = get_complete_voter_info(
        first_name="Ashtyn",
        last_name="Roberts",
        zip_code="70817",
        birth_month=7,
        birth_year=2003
    )
    
    print("Result:")
    print(json.dumps(result, indent=2))
    
    if result.get('success'):
        print("\n✅ Scraper test PASSED")
        return True
    else:
        print("\n❌ Scraper test FAILED")
        return False


def test_api_health(base_url="http://localhost:5000"):
    """Test API health endpoint"""
    print("\n" + "=" * 60)
    print("TEST 2: API Health Check")
    print("=" * 60)
    
    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 200:
            print("✅ Health check PASSED")
            return True
        else:
            print("❌ Health check FAILED")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to API server")
        print("   Make sure the API is running with: python api_server.py")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_api_voter_info(base_url="http://localhost:5000"):
    """Test the voter info API endpoint"""
    print("\n" + "=" * 60)
    print("TEST 3: API Voter Info Endpoint")
    print("=" * 60)
    
    test_data = {
        "first_name": "Ashtyn",
        "last_name": "Roberts",
        "zip_code": "70817",
        "birth_month": 7,
        "birth_year": 2003
    }
    
    print("\nSending request with:")
    print(json.dumps(test_data, indent=2))
    
    try:
        response = requests.post(
            f"{base_url}/api/voter-info",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=15
        )
        
        print(f"\nStatus Code: {response.status_code}")
        print("Response:")
        print(json.dumps(response.json(), indent=2))
        
        if response.status_code == 200 and response.json().get('success'):
            print("\n✅ API voter info test PASSED")
            return True
        else:
            print("\n❌ API voter info test FAILED")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to API server")
        print("   Make sure the API is running with: python api_server.py")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_api_validation(base_url="http://localhost:5000"):
    """Test API input validation"""
    print("\n" + "=" * 60)
    print("TEST 4: API Input Validation")
    print("=" * 60)
    
    # Test with missing fields
    print("\nTest 4a: Missing required fields")
    test_data = {
        "first_name": "John"
        # Missing other required fields
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/voter-info",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        
        if response.status_code == 400:
            print("✅ Correctly rejected incomplete data")
            validation_passed = True
        else:
            print("❌ Should have rejected incomplete data")
            validation_passed = False
    except Exception as e:
        print(f"❌ Error: {e}")
        validation_passed = False
    
    # Test with invalid ZIP code
    print("\nTest 4b: Invalid ZIP code")
    test_data = {
        "first_name": "John",
        "last_name": "Doe",
        "zip_code": "123",  # Too short
        "birth_month": 6,
        "birth_year": 1990
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/voter-info",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        
        if response.status_code == 400:
            print("✅ Correctly rejected invalid ZIP code")
            validation_passed = validation_passed and True
        else:
            print("❌ Should have rejected invalid ZIP code")
            validation_passed = False
    except Exception as e:
        print(f"❌ Error: {e}")
        validation_passed = False
    
    return validation_passed


def run_all_tests():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("Louisiana Voter Scraper Test Suite")
    print("=" * 60)
    
    results = []
    
    # Test 1: Direct scraper
    results.append(("Direct Scraper", test_scraper_directly()))
    
    # Test 2-4: API tests (only if API is running)
    print("\n⚠️  Starting API tests...")
    print("   Make sure the API is running: python api_server.py\n")
    
    api_base = "http://localhost:5000"
    results.append(("API Health", test_api_health(api_base)))
    
    if results[-1][1]:  # Only continue if health check passed
        results.append(("API Voter Info", test_api_voter_info(api_base)))
        results.append(("API Validation", test_api_validation(api_base)))
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    for name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{name:20} {status}")
    
    total = len(results)
    passed = sum(1 for _, p in results if p)
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
        return True
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return False


if __name__ == "__main__":
    success = run_all_tests()
    exit(0 if success else 1)