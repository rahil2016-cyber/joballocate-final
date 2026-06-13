import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/useresume_config.dart';
import '../models/json_resume.dart';

class UseresumeApiService {
  UseresumeApiService._();
  static final UseresumeApiService instance = UseresumeApiService._();

  static const String _baseUrl = UseresumeConfig.baseUrl;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${UseresumeConfig.apiKey}',
    'Accept': 'application/json',
  };

  /// Parses a resume file (PDF, DOCX, etc.) into structured JSON data.
  /// Uses POST /api/v3/resume/parse
  Future<JsonResume?> parseResume(File file) async {
    if (UseresumeConfig.apiKey.isEmpty) {
      throw Exception('Useresume AI API key is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/resume/parse');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return JsonResume.fromJson(Map<String, dynamic>.from(json['data']));
      }
    }
    
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to parse resume (${response.statusCode})');
  }

  /// Tailors a resume based on a job description.
  /// Uses POST /api/v3/resume/create-tailored
  Future<JsonResume?> tailorResume({
    required JsonResume resume,
    required String jobDescription,
  }) async {
    if (UseresumeConfig.apiKey.isEmpty) {
      throw Exception('Useresume AI API key is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/resume/create-tailored');
    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'resume': resume.toJson(),
        'job_description': jobDescription,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return JsonResume.fromJson(Map<String, dynamic>.from(json['data']));
      }
    }

    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Failed to tailor resume (${response.statusCode})');
  }

  /// Generates a high-quality PDF using Useresume.ai engine.
  /// Uses POST /api/v3/resume/create
  Future<List<int>> generatePdf(JsonResume resume, {String templateId = 'ats-modern'}) async {
    if (UseresumeConfig.apiKey.isEmpty) {
      throw Exception('Useresume AI API key is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/resume/create');
    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'resume': resume.toJson(),
        'template': templateId,
      }),
    );

    if (response.statusCode == 200) {
      // The API might return the PDF bytes directly or a URL/Base64
      // Based on docs, it usually returns bytes if Accept is application/pdf
      // or a JSON with a URL. Let's assume it returns a URL for now as per most modern APIs.
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null && json['data']['pdf_url'] != null) {
        final pdfRes = await http.get(Uri.parse(json['data']['pdf_url']));
        return pdfRes.bodyBytes;
      }
    }

    throw Exception('Failed to generate PDF');
  }
}
