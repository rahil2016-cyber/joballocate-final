import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/useresume_api_service.dart';
import '../../utils/app_colors.dart';
import '../../features/resume/adapters/draft_resume_parse.dart';
import '../../features/resume/models/resume_model.dart';
import '../../widgets/seeker_html_template_swatch.dart';
import 'package_purchase_history_screen.dart';
import 'resume_templates_screen.dart';
import 'resume_html_preview_screen.dart';
import 'seeker_resume_studio_screen.dart';
import '../../config/useresume_config.dart';
import '../auth/job_seeker_otp_login.dart';

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

  Future<void> _importFromPdf() async {
    if (UseresumeConfig.apiKey.isEmpty) {
      _showError('Useresume AI API key is not configured. Please add your key in lib/config/useresume_config.dart');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _loading = true);
      
      final file = File(result.files.single.path!);
      final parsedResume = await UseresumeApiService.instance.parseResume(file);

      if (!mounted) return;
      setState(() => _loading = false);

      if (parsedResume != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SeekerResumeStudioScreen(
              initialModel: ResumeModel.fromLegacyJsonResume(parsedResume),
              templateIdForSave: '1',
            ),
          ),
        ).then((_) => _load());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to parse resume: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  bool _looksLikeAuthError(String? text) {
    if (text == null || text.isEmpty) return false;
    final s = text.toLowerCase();
    return s.contains('unauthenticated') ||
        s.contains('session') ||
        s.contains('not valid for this server') ||
        s.contains('expired token');
  }

  Future<void> _signInAgain() async {
    await AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const JobSeekerOtpLoginScreen()),
      (_) => false,
    );
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
                      if (_looksLikeAuthError(_error)) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _signInAgain,
                          child: const Text('Sign in again'),
                        ),
                      ],
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
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
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
                              label: const Text('Create'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importFromPdf,
                              icon: const Icon(Icons.upload_file_rounded),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                              label: const Text('Import PDF'),
                            ),
                          ),
                        ],
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

                          final htmlKey = seekerHtmlTemplateKeyForStudioTemplateId(template);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              onTap: () {
                                try {
                                  final rawContent = d['content'];
                                  final parsed = resumeDraftParseForBuilder(rawContent);

                                  // Laravel stores display title on the draft row; content JSON may omit draft_title.
                                  final apiTitle = title.trim();
                                  final ResumeModel baseModel = parsed.model ??
                                      (parsed.legacy != null
                                          ? ResumeModel.fromLegacyJsonResume(parsed.legacy!)
                                          : ResumeModel.empty());
                                  final ResumeModel initial =
                                      apiTitle.isNotEmpty ? baseModel.copyWith(draftTitle: apiTitle) : baseModel;

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SeekerResumeStudioScreen(
                                        resumeDraftId: id,
                                        initialModel: initial,
                                        templateIdForSave: template.toString(),
                                      ),
                                    ),
                                  ).then((_) => _load());
                                } catch (e) {
                                  debugPrint('Error opening resume: $e');
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Template Preview Block
                                    Container(
                                      width: 80,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SeekerHtmlTemplateSwatch(templateKey: htmlKey),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isPrimary)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Updated ${_fmt(updated)}',
                                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              seekerHtmlTemplateLabel(htmlKey),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary.withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              SizedBox(
                                                height: 32,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.of(context).push<void>(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) => ResumeHtmlPreviewScreen(
                                                          templateKey: htmlKey,
                                                          resumeDraftId: id > 0 ? id : null,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                  child: const Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (!isPrimary)
                                                SizedBox(
                                                  height: 32,
                                                  child: TextButton(
                                                    onPressed: id > 0 ? () => _setPrimary(id) : null,
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      backgroundColor: AppColors.primary.withOpacity(0.08),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    ),
                                                    child: const Text(
                                                      'Use for Applications',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                )
                                              else
                                                const Text(
                                                  'Active Primary Resume',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
