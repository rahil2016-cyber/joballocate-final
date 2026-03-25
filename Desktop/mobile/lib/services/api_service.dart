import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/api_json_decode.dart';
import 'app_session.dart';
import '../models/user.dart';

class ApiService {
  // When demoMode is true, network calls for OTP are bypassed and the
  // hardcoded code below is always accepted. Set to false to use [ApiConfig.baseUrl]
  // (Laravel on host: Android emulator uses 10.0.2.2:8000 — see [ApiConfig]).
  static bool demoMode = false;
  static const String demoOtp = '123456';

  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, dynamic> _decodeBody(http.Response response) =>
      decodeApiJsonObject(response);

  /// [role] must match Laravel: `job_seeker` or `company`.
  /// [intent]: `login` or `register` (register needs [name] / [companyName] on verify).
  Future<Map<String, dynamic>> sendOtp(
    String identifier, {
    required String intent,
    required String role,
  }) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'success': true, 'message': 'Demo OTP sent', 'data': {'mock_otp': demoOtp}};
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/send-otp'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'intent': intent,
        'role': role,
      }),
    );

    final json = _decodeBody(response);
    if (response.statusCode == 200 && json['success'] == true) {
      return json;
    }
    final msg = json['message']?.toString() ?? 'Failed to send OTP';
    throw Exception(msg);
  }

  Future<Map<String, dynamic>> verifyOtp(
    String identifier,
    String otp, {
    required String intent,
    required String role,
    String? name,
    String? companyName,
    String? gstNumber,
  }) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (otp == demoOtp) {
        AppSession.setSession(
          bearerToken: 'demo-token',
          userPayload: {'id': 'demo-user', 'name': 'Demo User', 'role': role},
        );
        return {'success': true, 'data': {'token': 'demo-token', 'user': AppSession.user!}};
      }
      throw Exception('Invalid OTP');
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'code': otp,
        'intent': intent,
        'role': role,
        if (name != null && name.isNotEmpty) 'name': name,
        if (companyName != null && companyName.isNotEmpty) 'company_name': companyName,
        if (gstNumber != null && gstNumber.trim().isNotEmpty)
          'gst_number': gstNumber.trim(),
      }),
    );

    final json = _decodeBody(response);
    if (response.statusCode == 200 && json['success'] == true) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final token = data['token'] as String?;
        final user = data['user'];
        if (token != null && user is Map<String, dynamic>) {
          AppSession.setSession(bearerToken: token, userPayload: user);
        }
      }
      return json;
    }
    final msg = json['message']?.toString() ?? 'Invalid OTP';
    throw Exception(msg);
  }

  // Get user profile
  Future<User> getUserProfile(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return User(
        id: userId,
        email: 'rahul@example.com',
        phone: '+91 98765 43210',
        role: 'job_seeker',
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData, String token) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  // Job Seeker specific APIs
  Future<JobSeekerProfile> getJobSeekerProfile(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return JobSeekerProfile(
        id: 'demo-id',
        userId: userId,
        firstName: 'Rahul',
        lastName: 'Kumar',
        location: 'Bangalore, Karnataka',
        bio: 'Passionate about building beautiful mobile applications with Flutter',
        skills: ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'State Management', 'UI Design'],
        experienceYears: 5,
        resumeUrl: 'rahul_resume.pdf',
        linkedinUrl: 'https://linkedin.com/in/rahul',
      );
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/job-seeker/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return JobSeekerProfile.fromJson(data['profile']);
    } else {
      throw Exception('Failed to load job seeker profile');
    }
  }

  Future<void> updateJobSeekerProfile(String userId, Map<String, dynamic> profileData, String token) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/job-seeker/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update job seeker profile');
    }
  }

  // Employer specific APIs
  Future<EmployerProfile> getEmployerProfile(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return EmployerProfile(
        id: 'demo-id',
        userId: userId,
        companyName: 'TechCorp Solutions',
        contactEmail: 'hr@techcorp.com',
        contactPhone: '+91 80 1234 5678',
        contactPerson: 'John Doe',
        location: 'Bangalore, Karnataka',
        industry: 'Technology',
        companySize: '500-1000',
        companyDescription: 'Leading technology solutions provider delivering innovative products and services.',
        companyWebsite: 'www.techcorp.com',
        isKycVerified: true,
      );
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/employer/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return EmployerProfile.fromJson(data['profile']);
    } else {
      throw Exception('Failed to load employer profile');
    }
  }

  Future<void> updateEmployerProfile(String userId, Map<String, dynamic> profileData, String token) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/employer/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update employer profile');
    }
  }

  // ===== Resume APIs =====

  // Get all resume templates (legacy path; empty → app uses local [resumeTemplates]).
  Future<List<Map<String, dynamic>>> getResumeTemplates() async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {'id': 1, 'name': 'Classic Blue', 'category': 'professional', 'thumbnail': 'assets/templates/classic_blue.png'},
        {'id': 2, 'name': 'Modern Minimal', 'category': 'modern', 'thumbnail': 'assets/templates/modern_minimal.png'},
        {'id': 3, 'name': 'Executive Pro', 'category': 'professional', 'thumbnail': 'assets/templates/executive_pro.png'},
        {'id': 4, 'name': 'Creative Designer', 'category': 'creative', 'thumbnail': 'assets/templates/creative_designer.png'},
        {'id': 5, 'name': 'Tech Stack', 'category': 'technical', 'thumbnail': 'assets/templates/tech_stack.png'},
      ];
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/resumes/templates'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['templates'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  // Get user's resumes
  Future<List<Map<String, dynamic>>> getUserResumes(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [];
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/resumes/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['resumes'] ?? []);
    } else {
      throw Exception('Failed to load resumes');
    }
  }

  /// Persists resume draft — Laravel `POST /job-seeker/resume/save`.
  Future<Map<String, dynamic>> createResume(
    String userId,
    String token,
    String templateId,
    String title,
    Map<String, dynamic> content,
  ) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Resume created successfully',
        'data': {
          'id': 'demo-resume-${DateTime.now().millisecondsSinceEpoch}',
          'user_id': userId,
          'template_id': templateId,
          'title': title,
          'content': content,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      };
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/job-seeker/resume/save'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'template_id': templateId,
        'title': title,
        'content': content,
      }),
    );

    final json = _decodeBody(response);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        json['success'] == true) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return {'success': true, 'resume': data};
      }
    }
    final msg = json['message']?.toString() ?? 'Failed to save resume';
    throw Exception(msg);
  }

  // Update resume
  Future<void> updateResume(
    String resumeId,
    String token,
    Map<String, dynamic> content,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/resumes/$resumeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update resume');
    }
  }

  // Delete resume
  Future<void> deleteResume(String resumeId, String token) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/resumes/$resumeId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete resume');
    }
  }

  // ===== Payment/Transaction APIs =====

  // Get user's wallet balance
  Future<double> getWalletBalance(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return 500.0; // Demo balance
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/wallet/balance/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['balance'] as num).toDouble();
    } else {
      throw Exception('Failed to get wallet balance');
    }
  }

  // Initiate payment for resume creation
  Future<Map<String, dynamic>> initiateResumePayment(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'order_id': 'demo-order-${DateTime.now().millisecondsSinceEpoch}',
        'amount': 20,
        'currency': 'INR',
      };
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/payments/resume-create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'amount': 20}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate payment');
    }
  }

  // Initiate payment for job application
  Future<Map<String, dynamic>> initiateApplicationPayment(
    String userId,
    String jobId,
    String token,
  ) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'order_id': 'demo-order-${DateTime.now().millisecondsSinceEpoch}',
        'amount': 100,
        'currency': 'INR',
      };
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/payments/job-application'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'job_id': jobId,
        'amount': 100,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate payment');
    }
  }

  // Verify payment and apply for job
  Future<Map<String, dynamic>> applyForJob(
    String userId,
    String jobId,
    String resumeId,
    String orderId,
    String token,
  ) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Application submitted successfully',
        'application_id': 'demo-app-${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/jobs/apply'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'job_id': jobId,
        'resume_id': resumeId,
        'order_id': orderId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to apply for job');
    }
  }

  // Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId, String token) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [];
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/transactions/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
    } else {
      throw Exception('Failed to load transaction history');
    }
  }

  // ===== Subscription APIs =====

  /// Get all subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return []; // caller falls back to kHardcodedPlans
    }
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/subscriptions/plans'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['plans'] ?? []);
    } else {
      throw Exception('Failed to load subscription plans');
    }
  }

  /// Get user subscriptions
  Future<Map<String, dynamic>> getUserSubscriptions(
    String userId,
    String token,
  ) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return {'subscriptions': [], 'activeResumeSub': null, 'activeJobSub': null};
    }
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/subscriptions/user/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user subscriptions');
    }
  }

  /// Purchase a subscription plan
  Future<Map<String, dynamic>> purchaseSubscription(
    String userId,
    String planId,
    String token, {
    String? orderId,
  }) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'message': 'Subscription activated (demo)',
        'subscription': {
          'id': 'sub-demo-${DateTime.now().millisecondsSinceEpoch}',
          'userId': userId,
          'planId': planId,
          'planName': planId,
          'type': 'combo',
          'resumeCreditsTotal': 5,
          'resumeCreditsUsed': 0,
          'jobCreditsTotal': 5,
          'jobCreditsUsed': 0,
          'purchasedAt': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'status': 'active',
        },
      };
    }
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/subscriptions/purchase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'plan_id': planId,
        if (orderId != null) 'order_id': orderId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to purchase subscription');
    }
  }
}