import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import 'package_purchase_history_screen.dart';
import 'resume_templates_screen.dart';

/// Saved resumes (from credits / purchases) + choose which one employers see when you apply.
class MyResumesScreen extends StatefulWidget {
  const MyResumesScreen({
    super.key,
    this.userId = 'demo-user',
    this.token = 'demo-token',
  });

  final String userId;
  final String token;

  @override
  State<MyResumesScreen> createState() => _MyResumesScreenState();
}

class _MyResumesScreenState extends State<MyResumesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _drafts = [];
  int? _primaryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view resumes.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await JobSeekerApiService.instance.getResumeDrafts();
      if (!mounted) return;
      final list = raw['drafts'];
      final drafts = <Map<String, dynamic>>[];
      if (list is List) {
        for (final e in list) {
          if (e is Map) drafts.add(Map<String, dynamic>.from(e));
        }
      }
      final pid = raw['primary_resume_draft_id'];
      int? primary;
      if (pid is int) {
        primary = pid;
      } else if (pid != null) {
        primary = int.tryParse(pid.toString());
      }
      setState(() {
        _drafts = drafts;
        _primaryId = primary;
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

  Future<void> _setPrimary(int id) async {
    try {
      await JobSeekerApiService.instance.setPrimaryResumeDraft(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Employers will see this resume when you apply.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return DateFormat('MMM d, y').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tok = AppSession.token ?? widget.token;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My resumes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Resume purchases',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PackagePurchaseHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Text(
                        'Purchased & saved',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Resumes you save after buying resume credits appear here. '
                        'Select one to show to companies when you apply.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ResumeTemplatesScreen(
                                userId: widget.userId,
                                token: tok,
                              ),
                            ),
                          );
                          if (mounted) await _load();
                        },
                        icon: const Icon(Icons.add_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        label: const Text('Create resume'),
                      ),
                      const SizedBox(height: 20),
                      if (_drafts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 56,
                                color: AppColors.textHint.withOpacity(0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No saved resumes yet.\n'
                                'Use Create resume after activating a plan.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._drafts.map((d) {
                          final idRaw = d['id'];
                          final id = idRaw is int
                              ? idRaw
                              : int.tryParse(idRaw?.toString() ?? '') ?? 0;
                          final title =
                              d['title']?.toString() ?? 'Untitled resume';
                          final template =
                              d['template_id']?.toString() ?? '—';
                          final updated =
                              d['updated_at']?.toString() ??
                                  d['created_at']?.toString();
                          final isPrimary = d['is_primary'] == true ||
                              (_primaryId != null && _primaryId == id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Template: $template · Updated ${_fmt(updated)}',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isPrimary)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Visible to employers',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (!isPrimary)
                                        TextButton(
                                          onPressed: id > 0
                                              ? () => _setPrimary(id)
                                              : null,
                                          child: const Text(
                                            'Use for applications',
                                          ),
                                        )
                                      else
                                        Text(
                                          'Shown on applications to employers',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
