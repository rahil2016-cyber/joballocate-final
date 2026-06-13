import 'package:flutter/material.dart';
import '../../../services/app_session.dart';
import '../../../services/job_seeker_api_service.dart';
import '../../../utils/app_colors.dart';

class FeedbackRateScreen extends StatefulWidget {
  const FeedbackRateScreen({super.key});

  @override
  State<FeedbackRateScreen> createState() => _FeedbackRateScreenState();
}

class _FeedbackRateScreenState extends State<FeedbackRateScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;
  bool _loadingHistory = true;
  String? _historyError;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!AppSession.isLoggedIn) {
      setState(() {
        _loadingHistory = false;
        _historyError = 'Sign in to view your feedback history.';
      });
      return;
    }
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final res = await JobSeekerApiService.instance.listSeekerFeedback();
      if (!mounted) return;
      final items = res['items'];
      final list = items is List
          ? items.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _history = list;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString();
        _loadingHistory = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!AppSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit feedback.')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating!')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await JobSeekerApiService.instance.submitSeekerFeedback(
        rating: _rating,
        message: _feedbackController.text,
      );
      if (!mounted) return;
      _feedbackController.clear();
      setState(() => _rating = 0);
      await _loadHistory();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thank you'),
          content: const Text(
            'Your feedback was sent. If you left a message, our team may reply here in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _shortDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Feedback & Rating',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadingHistory ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 100,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rate your experience',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stars and optional notes go straight to our team. You can see replies below.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: _submitting ? null : () => setState(() => _rating = starIndex),
                    iconSize: 42,
                    icon: Icon(
                      starIndex <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: starIndex <= _rating ? Colors.amber : Colors.grey.shade400,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 5,
                  enabled: !_submitting,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Share your feedback (optional)',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit feedback',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Your feedback',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (_loadingHistory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_historyError != null)
                Text(_historyError!, style: TextStyle(color: Colors.grey.shade700))
              else if (_history.isEmpty)
                Text(
                  'No submissions yet. After you send feedback, it appears here with any admin reply.',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                )
              else
                ..._history.map((row) {
                  final stars = row['rating'] is int ? row['rating'] as int : int.tryParse('${row['rating']}') ?? 0;
                  final msg = row['message']?.toString();
                  final reply = row['admin_reply']?.toString();
                  final repliedAt = row['admin_replied_at']?.toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _shortDate(row['created_at']?.toString()),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (msg != null && msg.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                        if (reply != null && reply.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Team reply${repliedAt != null ? ' · ${_shortDate(repliedAt)}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(reply, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
