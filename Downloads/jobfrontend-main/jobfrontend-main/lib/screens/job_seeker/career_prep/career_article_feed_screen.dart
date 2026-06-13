import 'package:flutter/material.dart';
import '../../../services/job_seeker_api_service.dart';
import '../../../utils/app_colors.dart';

/// Loads `GET /job-seeker/career/contents` for [apiType]:
/// `career_guidance` or `interview_experience`.
class CareerArticleFeedScreen extends StatefulWidget {
  const CareerArticleFeedScreen({
    super.key,
    required this.title,
    required this.apiType,
  });

  final String title;
  final String apiType;

  @override
  State<CareerArticleFeedScreen> createState() => _CareerArticleFeedScreenState();
}

class _CareerArticleFeedScreenState extends State<CareerArticleFeedScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await JobSeekerApiService.instance.getCareerContents(widget.apiType);
      if (!mounted) return;
      final raw = data['items'];
      final list = raw is List
          ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int? _parseId(dynamic id) {
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse('$id');
  }

  Future<void> _toggleHelpful(Map<String, dynamic> item) async {
    final id = _parseId(item['id']);
    if (id == null) return;
    final currently = item['user_marked_helpful'] == true;
    try {
      final res = await JobSeekerApiService.instance.setCareerContentHelpful(
        id,
        helpful: !currently,
      );
      if (!mounted) return;
      setState(() {
        item['user_marked_helpful'] = res['user_marked_helpful'] == true;
        item['helpful_count'] = res['helpful_count'] ?? item['helpful_count'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'No articles yet. Check back soon — our team adds career tips and interview stories here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _ArticleCard(
                            item: _items[index],
                            onHelpful: () => _toggleHelpful(_items[index]),
                          );
                        },
                      ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item, required this.onHelpful});

  final Map<String, dynamic> item;
  final VoidCallback onHelpful;

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final subtitle = item['subtitle']?.toString();
    final body = item['body']?.toString() ?? '';
    final rating = item['rating_hint'];
    final helpful = item['helpful_count'] is int ? item['helpful_count'] as int : int.tryParse('${item['helpful_count']}') ?? 0;
    final marked = item['user_marked_helpful'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    TextButton.icon(
                      onPressed: onHelpful,
                      icon: Icon(
                        marked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 18,
                        color: marked ? AppColors.primary : null,
                      ),
                      label: Text('Helpful ($helpful)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
