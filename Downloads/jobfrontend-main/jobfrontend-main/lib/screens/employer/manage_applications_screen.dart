import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/company_api_service.dart';
import '../../services/resume_pdf_export.dart';
import '../../utils/app_colors.dart';
import '../../utils/media_url.dart';
import '../../features/resume/adapters/draft_resume_parse.dart';
import '../../models/json_resume.dart';
import '../../models/resume_template.dart';
import '../../widgets/template_preview.dart';

List<String> _educationLinesFromProfile(dynamic raw) {
  if (raw is! List) return [];
  final out = <String>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final title = m['title']?.toString().trim() ?? '';
    final inst = m['institution']?.toString().trim() ?? '';
    final board = m['board_or_stream']?.toString().trim() ?? '';
    final grade = m['marks_or_grade']?.toString().trim() ?? '';
    final year = m['year_completed']?.toString().trim() ?? '';
    final parts = <String>[
      if (title.isNotEmpty) title,
      if (inst.isNotEmpty) inst,
      if (board.isNotEmpty) board,
      if (grade.isNotEmpty) 'Grade: $grade',
      if (year.isNotEmpty) year,
    ];
    if (parts.isNotEmpty) out.add(parts.join(' · '));
  }
  return out;
}

/// Fills gaps in saved JSON from profile chips (bio, skills, etc.) for employer preview/PDF.
JsonResume _resumeMergedForEmployerView(_ApplicantRow a) {
  final src = a.primaryResumeContent!;
  final j = JsonResume.fromJson(src.toJson());
  if (j.basics.name.trim().isEmpty) {
    j.basics.name = a.applicantName;
  }
  if (j.basics.phone.trim().isEmpty && (a.phone?.trim().isNotEmpty == true)) {
    j.basics.phone = a.phone!.trim();
  }
  if (j.basics.email.trim().isEmpty && (a.email?.trim().isNotEmpty == true)) {
    j.basics.email = a.email!.trim();
  }
  if (j.basics.label.trim().isEmpty && (a.headline?.trim().isNotEmpty == true)) {
    j.basics.label = a.headline!.trim();
  }
  if (j.basics.summary.trim().isEmpty && (a.bio?.trim().isNotEmpty == true)) {
    j.basics.summary = a.bio!.trim();
  }
  if (j.skills.isEmpty && a.skills.isNotEmpty) {
    for (final s in a.skills) {
      j.skills.add(Skill(name: s));
    }
  }
  if (j.education.isEmpty && a.educationLines.isNotEmpty) {
    for (final line in a.educationLines) {
      if (line.trim().isEmpty) continue;
      j.education.add(Education(institution: line));
    }
  }
  if (j.basics.location.city.trim().isEmpty && (a.city?.trim().isNotEmpty == true)) {
    j.basics.location.city = a.city!.trim();
  }
  if (a.country != null && a.country!.trim().isNotEmpty) {
    final co = a.country!.trim();
    if (j.basics.location.region.trim().isEmpty) {
      j.basics.location.region = co;
    }
  }
  if (j.totalWorkExperience.trim().isEmpty && a.experienceYears != null) {
    j.totalWorkExperience = '${a.experienceYears} yrs experience';
  }
  return j;
}

bool _applicantRowHasExternalResumeOnly(_ApplicantRow a) {
  if (a.primaryResumeContent != null) return false;
  final u = a.resumeUrl?.trim();
  if (u == null || u.isEmpty) return false;
  return (MediaUrl.resolve(u) ?? u).trim().isNotEmpty;
}

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
    this.state,
    this.district,
    this.industryType,
    this.skills = const [],
    this.educationLines = const [],
    this.primaryResumeContent,
    this.primaryResumeTemplateId,
    this.profilePhotoUrl,
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
  final String? profilePhotoUrl;
  /// From profile `primary_resume_draft` — visible resume for applications.
  final String? primaryResumeTitle;
  final JsonResume? primaryResumeContent;
  final String? primaryResumeTemplateId;
  final String? headline;
  final String? bio;
  final String? city;
  final String? country;
  final String? state;
  final String? district;
  final String? industryType;
  final int? experienceYears;
  final String? dateOfBirth;
  final List<String> skills;
  /// One line per education entry (title · institution · year).
  final List<String> educationLines;
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
            String? photo =
                u?['profile_photo_url']?.toString() ?? u?['profile_photo']?.toString();

            String? resumeUrl;
            String? primaryResumeTitle;
            String? headline;
            String? bio;
            String? city;
            String? country;
            String? state;
            String? district;
            String? industryType;
            int? experienceYears;
            String? dateOfBirth;
            var skills = <String>[];
            var educationLines = <String>[];
            JsonResume? primaryResumeContent;
            String? primaryResumeTemplateId;
            if (u != null) {
              final prof = u['job_seeker_profile'];
              if (prof is Map) {
                final m = Map<String, dynamic>.from(prof);
                final profPhoto = m['profile_photo_url']?.toString().trim();
                if (profPhoto != null && profPhoto.isNotEmpty) {
                  photo = profPhoto;
                }
                final r = m['resume_url']?.toString();
                if (r != null && r.trim().isNotEmpty) resumeUrl = r.trim();
                final pr = m['primary_resume_draft'];
                if (pr is Map) {
                  final t = pr['title']?.toString().trim();
                  if (t != null && t.isNotEmpty) primaryResumeTitle = t;
                  primaryResumeTemplateId = pr['template_id']?.toString();
                  final content = pr['content'];
                  primaryResumeContent = jsonResumePreviewFromDraftContent(content);
                }
                headline = m['headline']?.toString().trim();
                if (headline != null && headline.isEmpty) headline = null;
                bio = m['bio']?.toString().trim();
                if (bio != null && bio.isEmpty) bio = null;
                city = m['city']?.toString().trim();
                if (city != null && city.isEmpty) city = null;
                country = m['country']?.toString().trim();
                if (country != null && country.isEmpty) country = null;
                state = m['state']?.toString().trim();
                if (state != null && state.isEmpty) state = null;
                district = m['district']?.toString().trim();
                if (district != null && district.isEmpty) district = null;
                industryType = m['industry_type']?.toString().trim();
                if (industryType != null && industryType.isEmpty) {
                  industryType = null;
                }
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
                  skills = sk
                      .map((e) => e.toString())
                      .where((s) => s.isNotEmpty)
                      .toList();
                }
                educationLines = _educationLinesFromProfile(m['education']);
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
              state: state,
              district: district,
              industryType: industryType,
              experienceYears: experienceYears,
              dateOfBirth: dateOfBirth,
              skills: skills,
              educationLines: educationLines,
              primaryResumeContent: primaryResumeContent,
              primaryResumeTemplateId: primaryResumeTemplateId,
              profilePhotoUrl: photo,
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
                Row(
                  children: [
                    if (MediaUrl.resolve(a.profilePhotoUrl) != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: NetworkImage(
                            MediaUrl.resolve(a.profilePhotoUrl)!,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.applicantName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (a.headline != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              a.headline!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (a.email != null)
                      _miniChip(Icons.mail_outline_rounded, a.email!),
                    if (a.phone != null)
                      _miniChip(Icons.phone_rounded, a.phone!),
                    if (a.city != null)
                      _miniChip(Icons.location_city_outlined, 'City: ${a.city!}'),
                    if (a.district != null)
                      _miniChip(Icons.map_outlined, 'District: ${a.district!}'),
                    if (a.state != null)
                      _miniChip(Icons.public_outlined, 'State: ${a.state!}'),
                    if (a.country != null)
                      _miniChip(Icons.flag_outlined, 'Country: ${a.country!}'),
                    if (a.dateOfBirth != null)
                      _miniChip(Icons.cake_outlined, 'DOB ${a.dateOfBirth!}'),
                    if (a.experienceYears != null)
                      _miniChip(
                        Icons.work_outline_rounded,
                        '${a.experienceYears} yrs experience',
                      ),
                    if (a.industryType != null)
                      _miniChip(
                        Icons.category_outlined,
                        'Industry: ${a.industryType!}',
                      ),
                  ],
                ),
                if (a.educationLines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Education',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...a.educationLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                    'Primary resume (applications): ${a.primaryResumeTitle}',
                  ),
                ],
                if (_applicantRowHasExternalResumeOnly(a)) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openResume(a.resumeUrl!);
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Open resume / portfolio (PDF or link)'),
                  ),
                ],
                if (a.primaryResumeContent != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Application resume (in-app)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Built in JobAllocate — includes profile details where the candidate has not duplicated them in the resume JSON.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary.withOpacity(0.95),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TemplatePreview(
                      resume: _resumeMergedForEmployerView(a),
                      variant: (() {
                        if (a.primaryResumeTemplateId == null) return 0;
                        final tid = int.tryParse(a.primaryResumeTemplateId!);
                        return resumeTemplateOrDefaultForDraft(tid).designVariant;
                      })(),
                      height: 400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final display = _resumeMergedForEmployerView(a);
                      final tid =
                          int.tryParse(a.primaryResumeTemplateId ?? '14') ?? 14;
                      try {
                        final bytes =
                            await exportResumePdfForTemplate(display, tid);
                        final safe = a.applicantName
                            .replaceAll(RegExp(r'[^\w\- ]'), '_')
                            .trim();
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename:
                              '${safe.isEmpty ? 'candidate' : safe}_resume.pdf',
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not build PDF: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download resume PDF'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Design template: ${a.primaryResumeTemplateId ?? '14'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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



  Future<void> _openResume(String url) async {
    final resolved = (MediaUrl.resolve(url) ?? url).trim();
    if (resolved.isEmpty) return;
    final u = Uri.tryParse(resolved);
    if (u == null) return;
    try {
      if (await canLaunchUrl(u)) {
        final ok = await launchUrl(
          u,
          mode: LaunchMode.externalApplication,
        );
        if (ok || !mounted) return;
      }
    } catch (_) {}
    try {
      if (await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open link. Try copying: $resolved'),
        backgroundColor: AppColors.error,
      ),
    );
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
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
        color: AppColors.primary,
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
          color: sel ? AppColors.primary : AppColors.surface,
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
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: MediaUrl.resolve(a.profilePhotoUrl) != null
                            ? Image.network(
                                MediaUrl.resolve(a.profilePhotoUrl)!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _nameIcon(a.applicantName),
                              )
                            : _nameIcon(a.applicantName),
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
                                    color: AppColors.primary,
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
                            if (a.dateOfBirth != null)
                              Text(
                                'DOB: ${a.dateOfBirth}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (a.district != null ||
                                a.city != null ||
                                a.state != null ||
                                a.country != null)
                              Text(
                                [
                                  if (a.city != null && a.city!.isNotEmpty) a.city!,
                                  if (a.district != null && a.district!.isNotEmpty)
                                    a.district!,
                                  if (a.state != null && a.state!.isNotEmpty) a.state!,
                                  if (a.country != null && a.country!.isNotEmpty)
                                    a.country!,
                                ].join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (a.experienceYears != null)
                              Text(
                                '${a.experienceYears} yrs experience',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (a.educationLines.isNotEmpty)
                              Text(
                                a.educationLines.first,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (a.educationLines.length > 1)
                              Text(
                                '+ ${a.educationLines.length - 1} more education',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                  fontStyle: FontStyle.italic,
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
          if (_applicantRowHasExternalResumeOnly(a)) ...[
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
          if (a.primaryResumeContent != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showApplicantProfile(a),
              child: Row(
                children: [
                  Icon(Icons.article_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In-app resume — tap profile above to preview or download PDF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
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

  Widget _nameIcon(String name) {
    return Center(
      child: Text(
        name
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
