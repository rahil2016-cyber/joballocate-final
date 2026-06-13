import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../config/api_config.dart';
import '../utils/api_json_decode.dart';

/// Share published jobs via API-built text + deep link (`joballocate://job/{id}`).
class JobShareService {
  JobShareService._();
  static final JobShareService instance = JobShareService._();

  String get _base => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchSharePayload(String jobId) async {
    final r = await http.get(
      Uri.parse('$_base/jobs/$jobId/share'),
      headers: {'Accept': 'application/json'},
    );
    final json = decodeApiJsonObject(r);
    if (r.statusCode >= 200 &&
        r.statusCode < 300 &&
        json['success'] == true &&
        json['data'] is Map) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
    throw Exception(json['message']?.toString() ?? 'Could not load share link');
  }

  Map<String, dynamic> _fallbackPayload({
    required String jobId,
    required String title,
    required String companyName,
    String? location,
  }) {
    final appLink = 'joballocate://job/$jobId';
    final loc = location?.trim();
    final lines = [
      'Check out this job on JobAllocate!',
      '',
      title,
      'at $companyName${loc != null && loc.isNotEmpty ? ' · $loc' : ''}',
      '',
      'Open in the JobAllocate app:',
      appLink,
    ];
    return {
      'app_link': appLink,
      'share_text': lines.join('\n'),
    };
  }

  Future<void> shareJob({
    required String jobId,
    required String title,
    required String companyName,
    String? location,
  }) async {
    Map<String, dynamic> payload;
    try {
      payload = await fetchSharePayload(jobId);
    } catch (_) {
      payload = _fallbackPayload(
        jobId: jobId,
        title: title,
        companyName: companyName,
        location: location,
      );
    }

    final text = payload['share_text']?.toString() ?? '';
    final appLink = payload['app_link']?.toString();
    if (text.isEmpty && appLink != null) {
      await Share.share(appLink);
      return;
    }
    await Share.share(text);
  }
}
