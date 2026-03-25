import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/company_api_service.dart';
import '../../utils/app_colors.dart';

class _ApplicantRow {
  _ApplicantRow({
    required this.jobId,
    required this.jobTitle,
    required this.applicationId,
    required this.applicantName,
    required this.status,
    this.email,
    this.phone,
    this.coverLetter,
    this.employerNote,
    this.resumeUrl,
    this.primaryResumeTitle,
    this.headline,
    this.bio,
    this.city,
    this.country,
    this.experienceYears,
    this.dateOfBirth,
    this.skills = const [],
  });

  final int jobId;
  final String jobTitle;
  final int applicationId;
  final String applicantName;
  final String status;
  final String? email;
  final String? phone;
  final String? coverLetter;
  final String? employerNote;
  final String? resumeUrl;
  /// From profile `primary_resume_draft` — visible resume for applications.
  final String? primaryResumeTitle;
  final String? headline;
  final String? bio;
  final String? city;
  final String? country;
  final int? experienceYears;
  final String? dateOfBirth;
  final List<String> skills;
}

/// Lists applications across all company jobs; updates status via API.
class ManageApplicationsScreen extends StatefulWidget {
  const ManageApplicationsScreen({super.key});

  @override
  State<ManageApplicationsScreen> createState() =>
      _ManageApplicationsScreenState();
}

class _ManageApplicationsScreenState extends State<ManageApplicationsScreen> {
  final _api = CompanyApiService.instance;

  bool _loading = true;
  String? _error;
  List<_ApplicantRow> _rows = [];
  /// all | applied | shortlisted | interview | rejected | hired
  String _filter = 'all';

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
      final jr = await _api.listJobPosts(perPage: 50);
      final jobs = (jr['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final futures = <Future<List<_ApplicantRow>>>[];

      for (final j in jobs) {
        final rawId = j['id'];
        final jobId = rawId is int ? rawId : int.tryParse(rawId.toString());
        if (jobId == null) continue;
        final title = j['title']?.toString() ?? 'Job';

        futures.add(() async {
          final ar = await _api.listApplications(jobId, perPage: 100);
          final apps =
              (ar['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final part = <_ApplicantRow>[];

          for (final a in apps) {
            final aid = a['id'];
            final appId =
                aid is int ? aid : int.tryParse(aid.toString()) ?? 0;
            final st = a['status']?.toString() ?? 'applied';
            Map<String, dynamic>? u;
            final user = a['user'];
            if (user is Map<String, dynamic>) u = user;
            final name = u?['name']?.toString() ?? 'Candidate';

            String? resumeUrl;
            String? primaryResumeTitle;
            String? headline;
            String? bio;
            String? city;
            String? country;
            int? experienceYears;
            String? dateOfBirth;
            var skills = <String>[];
            if (u != null) {
              final prof = u['job_seeker_profile'];
              if (prof is Map) {
                final m = Map<String, dynamic>.from(prof);
                final r = m['resume_url']?.toString();
                if (r != null && r.trim().isNotEmpty) resumeUrl = r.trim();
                final pr = m['primary_resume_draft'];
                if (pr is Map) {
                  final t = pr['title']?.toString().trim();
                  if (t != null && t.isNotEmpty) primaryResumeTitle = t;
                }
                headline = m['headline']?.toString().trim();
                if (headline != null && headline.isEmpty) headline = null;
                bio = m['bio']?.toString().trim();
                if (bio != null && bio.isEmpty) bio = null;
                city = m['city']?.toString();
                country = m['country']?.toString();
                final ey = m['experience_years'];
                if (ey is int) {
                  experienceYears = ey;
                } else {
                  experienceYears = int.tryParse(ey?.toString() ?? '');
                }
                final dob = m['date_of_birth']?.toString();
                if (dob != null && dob.trim().isNotEmpty) {
                  dateOfBirth =
                      dob.length >= 10 ? dob.substring(0, 10) : dob.trim();
                }
                final sk = m['skills'];
                if (sk is List) {
                  skills = sk.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
                }
              }
            }

            final cover = a['cover_letter']?.toString();
            final note = a['employer_note']?.toString();

            part.add(_ApplicantRow(
              jobId: jobId,
              jobTitle: title,
              applicationId: appId,
              applicantName: name,
              status: st,
              email: u?['email']?.toString(),
              phone: u?['phone']?.toString(),
              coverLetter: (cover != null && cover.trim().isNotEmpty)
                  ? cover
                  : null,
              employerNote:
                  (note != null && note.trim().isNotEmpty) ? note : null,
              resumeUrl: resumeUrl,
              primaryResumeTitle: primaryResumeTitle,
              headline: headline,
              bio: bio,
              city: city,
              country: country,
              experienceYears: experienceYears,
              dateOfBirth: dateOfBirth,
              skills: skills,
            ));
          }
          return part;
        }());
      }

      final chunks = await Future.wait(futures);
      final rows = chunks.expand((e) => e).toList();

      rows.sort((a, b) => b.applicationId.compareTo(a.applicationId));

      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<_ApplicantRow> get _filtered {
    if (_filter == 'all') return _rows;
    return _rows.where((r) => r.status == _filter).toList();
  }

  Future<void> _showApplicantProfile(_ApplicantRow a) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scroll) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  a.applicantName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (a.headline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    a.headline!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (a.email != null)
                      _miniChip(Icons.mail_outline_rounded, a.email!),
                    if (a.phone != null)
                      _miniChip(Icons.phone_rounded, a.phone!),
                    if (a.city != null || a.country != null)
                      _miniChip(
                        Icons.place_outlined,
                        [
                          if (a.city != null && a.city!.trim().isNotEmpty)
                            a.city!.trim(),
                          if (a.country != null && a.country!.trim().isNotEmpty)
                            a.country!.trim(),
                        ].join(', '),
                      ),
                    if (a.dateOfBirth != null)
                      _miniChip(Icons.cake_outlined, 'DOB ${a.dateOfBirth!}'),
                    if (a.experienceYears != null)
                      _miniChip(
                        Icons.work_outline_rounded,
                        '${a.experienceYears} yrs experience',
                      ),
                  ],
                ),
                if (a.skills.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: a.skills
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            visualDensity: VisualDensity.compact,
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (a.bio != null && a.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.bio!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (a.primaryResumeTitle != null) ...[
                  const SizedBox(height: 16),
                  _miniChip(
                    Icons.description_outlined,
                    'Application resume: ${a.primaryResumeTitle}',
                  ),
                ],
                if (a.resumeUrl != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openResume(a.resumeUrl!);
                    },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Open resume / portfolio link'),
                  ),
                ],
                if (a.coverLetter != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Cover letter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.coverLetter!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openResume(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    if (!await canLaunchUrl(u)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open resume link')),
      );
      return;
    }
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _setStatus(
    _ApplicantRow row,
    String newStatus,
    String actionTitle,
  ) async {
    final noteCtrl = TextEditingController(
      text: row.employerNote ?? '',
    );

    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row.applicantName} · ${row.jobTitle}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note to candidate (optional)',
                  hintText:
                      'This message is visible to the applicant on their application.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (submit != true) {
      noteCtrl.dispose();
      return;
    }

    final note = noteCtrl.text.trim();
    noteCtrl.dispose();

    try {
      await _api.updateApplicationStatus(
        row.jobId,
        row.applicationId,
        status: newStatus,
        employerNote: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated to $newStatus'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  int _count(String status) => _rows.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final list = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applications',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review cover letters, resume links, and update status.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('All (${_rows.length})', 'all'),
                      const SizedBox(width: 8),
                      _chip('Applied (${_count('applied')})', 'applied'),
                      const SizedBox(width: 8),
                      _chip('Shortlisted (${_count('shortlisted')})',
                          'shortlisted'),
                      const SizedBox(width: 8),
                      _chip('Interview (${_count('interview')})', 'interview'),
                      const SizedBox(width: 8),
                      _chip('Rejected (${_count('rejected')})', 'rejected'),
                      const SizedBox(width: 8),
                      _chip('Hired (${_count('hired')})', 'hired'),
                    ],
                  ),
                ),
              ),
            ),
            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _rows.isEmpty
                        ? 'No applications yet.'
                        : 'No applicants in this filter.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _card(list[i]),
                  childCount: list.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: sel ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : AppColors.textSecondary,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _card(_ApplicantRow a) {
    final statusColor = _statusColor(a.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showApplicantProfile(a),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            a.applicantName
                                .split(' ')
                                .where((e) => e.isNotEmpty)
                                .map((e) => e[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.applicantName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.jobTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (a.headline != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  a.headline!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (a.email != null || a.phone != null)
                              Text(
                                [a.email, a.phone].whereType<String>().join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap for full profile, bio & resume',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (a.primaryResumeTitle != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_copy_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Resume for applications: ${a.primaryResumeTitle}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (a.resumeUrl != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openResume(a.resumeUrl!),
              child: Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open candidate resume / portfolio link',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (a.coverLetter != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Cover letter',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              a.coverLetter!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (a.employerNote != null) ...[
            const SizedBox(height: 10),
            Text(
              'Your note to candidate: ${a.employerNote!}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (a.status == 'applied')
                OutlinedButton(
                  onPressed: () => _setStatus(
                    a,
                    'shortlisted',
                    'Shortlist candidate',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  child: const Text('Shortlist'),
                ),
              if (a.status == 'applied' || a.status == 'shortlisted')
                OutlinedButton(
                  onPressed: () => _setStatus(
                    a,
                    'interview',
                    'Move to interview',
                  ),
                  child: const Text('Interview'),
                ),
              if (a.status != 'rejected' && a.status != 'hired')
                OutlinedButton(
                  onPressed: () => _setStatus(
                    a,
                    'rejected',
                    'Reject candidate',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Reject'),
                ),
              if (a.status != 'hired' && a.status != 'rejected')
                FilledButton(
                  onPressed: () => _setStatus(
                    a,
                    'hired',
                    'Mark as hired',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Hire'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'applied':
        return AppColors.primary;
      case 'shortlisted':
        return Colors.orange;
      case 'interview':
        return AppColors.accent;
      case 'rejected':
        return AppColors.error;
      case 'hired':
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }
}
