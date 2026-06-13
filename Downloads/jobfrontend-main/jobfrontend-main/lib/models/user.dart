class User {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class JobSeekerProfile {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? location;
  final String? bio;
  final List<String>? skills;
  final int? experienceYears;
  final double? currentSalary;
  final double? expectedSalary;
  final String? resumeUrl;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String? githubUrl;

  JobSeekerProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.bio,
    this.skills,
    this.experienceYears,
    this.currentSalary,
    this.expectedSalary,
    this.resumeUrl,
    this.portfolioUrl,
    this.linkedinUrl,
    this.githubUrl,
  });

  factory JobSeekerProfile.fromJson(Map<String, dynamic> json) {
    return JobSeekerProfile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      gender: json['gender'],
      location: json['location'],
      bio: json['bio'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      experienceYears: json['experience_years'],
      currentSalary: json['current_salary']?.toDouble(),
      expectedSalary: json['expected_salary']?.toDouble(),
      resumeUrl: json['resume_url'],
      portfolioUrl: json['portfolio_url'],
      linkedinUrl: json['linkedin_url'],
      githubUrl: json['github_url'],
    );
  }
}

class EmployerProfile {
  final String id;
  final String userId;
  final String companyName;
  final String? companyDescription;
  final String? companyWebsite;
  final String? companySize;
  final String? industry;
  final String? location;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final bool isKycVerified;

  EmployerProfile({
    required this.id,
    required this.userId,
    required this.companyName,
    this.companyDescription,
    this.companyWebsite,
    this.companySize,
    this.industry,
    this.location,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    required this.isKycVerified,
  });

  factory EmployerProfile.fromJson(Map<String, dynamic> json) {
    return EmployerProfile(
      id: json['id'],
      userId: json['user_id'],
      companyName: json['company_name'],
      companyDescription: json['company_description'],
      companyWebsite: json['company_website'],
      companySize: json['company_size'],
      industry: json['industry'],
      location: json['location'],
      contactPerson: json['contact_person'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      isKycVerified: json['is_kyc_verified'] ?? false,
    );
  }
}