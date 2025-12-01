// voter_service.dart
// Service class to interact with the Python voter info API from Flutter

import 'dart:convert';
import 'package:http/http.dart' as http;

class VoterInfo {
  final String? name;
  final String? party;
  final String? parish;
  final String? wardPrecinct;
  final String? ward;
  final String? precinct;
  final String? status;
  final String? congressionalDistrict;
  final String? senateDistrict;
  final String? houseDistrict;

  VoterInfo({
    this.name,
    this.party,
    this.parish,
    this.wardPrecinct,
    this.ward,
    this.precinct,
    this.status,
    this.congressionalDistrict,
    this.senateDistrict,
    this.houseDistrict,
  });

  factory VoterInfo.fromJson(Map<String, dynamic> json) {
    return VoterInfo(
      name: json['name'] as String?,
      party: json['party'] as String?,
      parish: json['parish'] as String?,
      wardPrecinct: json['ward_precinct'] as String?,
      ward: json['ward'] as String?,
      precinct: json['precinct'] as String?,
      status: json['status'] as String?,
      congressionalDistrict: json['congressional_district'] as String?,
      senateDistrict: json['senate_district'] as String?,
      houseDistrict: json['house_district'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'party': party,
      'parish': parish,
      'ward_precinct': wardPrecinct,
      'ward': ward,
      'precinct': precinct,
      'status': status,
      'congressional_district': congressionalDistrict,
      'senate_district': senateDistrict,
      'house_district': houseDistrict,
    };
  }
}

class VoterServiceResponse {
  final bool success;
  final VoterInfo? data;
  final String? error;

  VoterServiceResponse({
    required this.success,
    this.data,
    this.error,
  });
}

class VoterService {
  // Change this to your actual API server URL
  // For local development: http://localhost:5000
  // For production: https://your-api-domain.com
  final String baseUrl;

  VoterService({this.baseUrl = 'http://localhost:5000'});

  /// Fetch voter information from the API
  /// 
  /// Parameters:
  /// - firstName: User's first name
  /// - lastName: User's last name
  /// - zipCode: 5-digit zip code
  /// - birthMonth: Birth month (1-12)
  /// - birthYear: 4-digit birth year
  /// 
  /// Returns VoterServiceResponse with success status and data/error
  Future<VoterServiceResponse> getVoterInfo({
    required String firstName,
    required String lastName,
    required String zipCode,
    required int birthMonth,
    required int birthYear,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/voter-info');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'zip_code': zipCode,
          'birth_month': birthMonth,
          'birth_year': birthYear,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return VoterServiceResponse(
          success: true,
          data: VoterInfo.fromJson(responseData['data']),
        );
      } else {
        return VoterServiceResponse(
          success: false,
          error: responseData['error'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return VoterServiceResponse(
        success: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Fetch voter information for a user from Firebase/database
  Future<VoterServiceResponse> getVoterInfoFromUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      return await getVoterInfo(
        firstName: userData['first_name'] ?? '',
        lastName: userData['last_name'] ?? '',
        zipCode: userData['zip_code'] ?? '',
        birthMonth: userData['birth_month'] ?? 0,
        birthYear: userData['birth_year'] ?? 0,
      );
    } catch (e) {
      return VoterServiceResponse(
        success: false,
        error: 'Invalid user data: ${e.toString()}',
      );
    }
  }

  /// Check API health status
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
