import 'job_seeker_api_service.dart';

/// Cached server-rendered demo HTML per [demoVariant] (all 12 templates in one request).
class ResumeHtmlThumbnailCache {
  ResumeHtmlThumbnailCache._();
  static final ResumeHtmlThumbnailCache instance = ResumeHtmlThumbnailCache._();

  final Map<int, Map<String, String>> _byVariant = {};
  final Map<int, Future<Map<String, String>>> _loading = {};

  String? htmlFor({required String templateKey, required int demoVariant}) {
    return _byVariant[demoVariant]?[templateKey];
  }

  Future<String?> ensureHtml({
    required String templateKey,
    required int demoVariant,
  }) async {
    final cached = htmlFor(templateKey: templateKey, demoVariant: demoVariant);
    if (cached != null && cached.isNotEmpty) return cached;

    final batch = await _loadVariant(demoVariant);
    return batch[templateKey];
  }

  /// Warms cache for all 12 templates for [demoVariant] (one HTTP request).
  Future<void> preloadVariant(int demoVariant) => _loadVariant(demoVariant);

  Future<Map<String, String>> _loadVariant(int demoVariant) async {
    final existing = _byVariant[demoVariant];
    if (existing != null && existing.isNotEmpty) return existing;

    final inFlight = _loading[demoVariant];
    if (inFlight != null) return inFlight;

    final future = JobSeekerApiService.instance.fetchDemoPreviewHtmlBatch(demoVariant).then((map) {
      _byVariant[demoVariant] = map;
      _loading.remove(demoVariant);
      return map;
    });
    _loading[demoVariant] = future;
    return future;
  }
}
