"""
Flask API Server for Louisiana Voter Information
Provides REST API endpoint for Flutter app to query voter data
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from voter_scraper import VoterScraper
import logging
from typing import Dict

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web/mobile apps

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create a reusable scraper instance
scraper = VoterScraper()


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "voter-info-api"}), 200


@app.route('/api/voter-info', methods=['POST'])
def get_voter_info():
    """
    Get voter information endpoint
    
    Expected JSON body:
    {
        "first_name": "Ashtyn",
        "last_name": "Roberts",
        "zip_code": "70817",
        "birth_month": 7,
        "birth_year": 2003
    }
    
    Returns:
    {
        "success": true/false,
        "data": {
            "name": "Ashtyn Elizabeth Roberts",
            "party": "No Party",
            "parish": "East Baton Rouge",
            "ward_precinct": "03/016",
            "status": "Active"
        },
        "error": "error message if success is false"
    }
    """
    try:
        # Validate request has JSON body
        if not request.is_json:
            return jsonify({
                "success": False,
                "error": "Request must be JSON"
            }), 400
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['first_name', 'last_name', 'zip_code', 'birth_month', 'birth_year']
        missing_fields = [field for field in required_fields if field not in data]
        
        if missing_fields:
            return jsonify({
                "success": False,
                "error": f"Missing required fields: {', '.join(missing_fields)}"
            }), 400
        
        # Extract and validate data
        first_name = data.get('first_name', '').strip()
        last_name = data.get('last_name', '').strip()
        zip_code = data.get('zip_code', '').strip()
        
        try:
            birth_month = int(data.get('birth_month'))
            birth_year = int(data.get('birth_year'))
        except (ValueError, TypeError):
            return jsonify({
                "success": False,
                "error": "birth_month and birth_year must be valid integers"
            }), 400
        
        # Validate data
        if not first_name or not last_name:
            return jsonify({
                "success": False,
                "error": "first_name and last_name cannot be empty"
            }), 400
        
        if len(zip_code) != 5 or not zip_code.isdigit():
            return jsonify({
                "success": False,
                "error": "zip_code must be a 5-digit number"
            }), 400
        
        if not (1 <= birth_month <= 12):
            return jsonify({
                "success": False,
                "error": "birth_month must be between 1 and 12"
            }), 400
        
        if not (1900 <= birth_year <= 2024):
            return jsonify({
                "success": False,
                "error": "birth_year must be between 1900 and 2024"
            }), 400
        
        # Log the request (without sensitive data in production)
        logger.info(f"Voter info request for: {first_name[0]}. {last_name[0]}., ZIP: {zip_code}")
        
        # Perform the scraping
        result = scraper.get_voter_info(
            first_name=first_name,
            last_name=last_name,
            zip_code=zip_code,
            birth_month=birth_month,
            birth_year=birth_year
        )
        
        # Return the result
        if result.get('success'):
            return jsonify({
                "success": True,
                "data": {k: v for k, v in result.items() if k != 'success'}
            }), 200
        else:
            return jsonify({
                "success": False,
                "error": result.get('error', 'Unknown error occurred')
            }), 404
            
    except Exception as e:
        logger.error(f"Error processing voter info request: {str(e)}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@app.route('/api/batch-voter-info', methods=['POST'])
def get_batch_voter_info():
    """
    Get voter information for multiple users (batch request)
    
    Expected JSON body:
    {
        "users": [
            {
                "uid": "user123",
                "first_name": "Ashtyn",
                "last_name": "Roberts",
                "zip_code": "70817",
                "birth_month": 7,
                "birth_year": 2003
            },
            ...
        ]
    }
    
    Returns array of results with uid for matching
    """
    try:
        if not request.is_json:
            return jsonify({
                "success": False,
                "error": "Request must be JSON"
            }), 400
        
        data = request.get_json()
        users = data.get('users', [])
        
        if not isinstance(users, list):
            return jsonify({
                "success": False,
                "error": "users must be an array"
            }), 400
        
        if len(users) > 50:  # Limit batch size
            return jsonify({
                "success": False,
                "error": "Batch size limited to 50 users"
            }), 400
        
        results = []
        
        for user in users:
            uid = user.get('uid')
            
            try:
                result = scraper.get_voter_info(
                    first_name=user.get('first_name', ''),
                    last_name=user.get('last_name', ''),
                    zip_code=user.get('zip_code', ''),
                    birth_month=int(user.get('birth_month', 0)),
                    birth_year=int(user.get('birth_year', 0))
                )
                
                results.append({
                    "uid": uid,
                    "success": result.get('success', False),
                    "data": {k: v for k, v in result.items() if k != 'success'} if result.get('success') else None,
                    "error": result.get('error') if not result.get('success') else None
                })
            except Exception as e:
                results.append({
                    "uid": uid,
                    "success": False,
                    "error": str(e)
                })
        
        return jsonify({
            "success": True,
            "results": results
        }), 200
        
    except Exception as e:
        logger.error(f"Error processing batch request: {str(e)}")
        return jsonify({
            "success": False,
            "error": "Internal server error"
        }), 500


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "error": "Endpoint not found"
    }), 404


@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "success": False,
        "error": "Internal server error"
    }), 500


if __name__ == '__main__':
    # For development only 
    app.run(host='0.0.0.0', port=5000, debug=True)