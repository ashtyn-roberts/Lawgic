// user_model.dart
// Updated user model to include voter registration fields

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  
  // New fields for voter registration lookup
  final String? zipCode;
  final int? birthMonth;  // 1-12
  final int? birthYear;   // 4-digit year
  
  // Cached voter information (optional - can be stored or fetched on-demand)
  final String? voterStatus;
  final String? voterParish;
  final String? voterWardPrecinct;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.zipCode,
    this.birthMonth,
    this.birthYear,
    this.voterStatus,
    this.voterParish,
    this.voterWardPrecinct,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'zip_code': zipCode,
      'birth_month': birthMonth,
      'birth_year': birthYear,
      'voter_status': voterStatus,
      'voter_parish': voterParish,
      'voter_ward_precinct': voterWardPrecinct,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      username: json['username'] as String,
      zipCode: json['zip_code'] as String?,
      birthMonth: json['birth_month'] as int?,
      birthYear: json['birth_year'] as int?,
      voterStatus: json['voter_status'] as String?,
      voterParish: json['voter_parish'] as String?,
      voterWardPrecinct: json['voter_ward_precinct'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? zipCode,
    int? birthMonth,
    int? birthYear,
    String? voterStatus,
    String? voterParish,
    String? voterWardPrecinct,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      zipCode: zipCode ?? this.zipCode,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      voterStatus: voterStatus ?? this.voterStatus,
      voterParish: voterParish ?? this.voterParish,
      voterWardPrecinct: voterWardPrecinct ?? this.voterWardPrecinct,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if user has complete voter registration data
  bool get hasVoterRegistrationData {
    return zipCode != null && 
           birthMonth != null && 
           birthYear != null &&
           zipCode!.isNotEmpty;
  }
}