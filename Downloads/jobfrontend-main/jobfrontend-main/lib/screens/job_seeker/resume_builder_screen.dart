import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/features/resume/providers/resume_draft_provider.dart';
import 'package:joballocate/features/resume/services/resume_pdf_export_service.dart';
import 'package:joballocate/features/resume/services/resume_seed_from_profile.dart';
import 'package:joballocate/resume/models/resume_font_family.dart';
import 'package:joballocate/resume/models/resume_builder_ids.dart';
import 'package:joballocate/resume/models/resume_sheet_constants.dart';
import 'package:joballocate/resume/providers/resume_studio_theme_provider.dart';
import 'package:joballocate/resume/templates/resume_template_registry.dart';
import 'package:joballocate/models/json_resume.dart';
import 'package:joballocate/models/resume.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:joballocate/services/api_service.dart';
import 'package:joballocate/services/app_session.dart';
import 'package:joballocate/services/job_seeker_api_service.dart';
import 'package:joballocate/utils/app_colors.dart';
import 'package:printing/printing.dart';

import 'resume_templates_screen.dart';

String _detailLabel(List<PersonalDetailRow> rows, String label) {
  final want = label.trim().toLowerCase();
  for (final r in rows) {
    if (r.label.trim().toLowerCase() == want) return r.value;
  }
  return '';
}

String _personalExtraLines(ResumeModel m) {
  const structured = {
    'current location',
    'date of birth',
    'gender',
    'linkedin',
    'portfolio',
    'expected salary (inr)',
  };
  final buf = StringBuffer();
  for (final r in m.personalDetails) {
    final k = r.label.trim().toLowerCase();
    if (structured.contains(k)) continue;
    if (r.label.trim().isEmpty) {
      if (r.value.trim().isNotEmpty) buf.writeln(r.value.trim());
    } else {
      buf.writeln('${r.label}: ${r.value}');
    }
  }
  return buf.toString().trimRight();
}

/// Realtime Resume 1 builder — isolated [ProviderScope] for Riverpod + autosave.
class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({
    super.key,
    required this.template,
    required this.userId,
    required this.token,
    this.initialResume,
    this.legacyInitialResume,
    this.existingResumeId,
    /// When set (or fetched in-screen), résumé fields pre-fill from job-seeker profile; user can still edit everything.
    this.seekerProfile,
  });

  final ResumeTemplate template;
  final String userId;
  final String token;
  final ResumeModel? initialResume;
  final JsonResume? legacyInitialResume;
  final String? existingResumeId;
  final Map<String, dynamic>? seekerProfile;

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  bool _bootstrappedNotifier = false;

  late final TabController _narrowTabController;
  late final FocusNode _summaryFocus;

  int _railIndex = 0;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _langsCtrl;
  late final TextEditingController _certsCtrl;
  late final TextEditingController _personalCtrl;

  late final TextEditingController _gCourse;
  late final TextEditingController _gCollege;
  late final TextEditingController _gScore;

  late final TextEditingController _s12Board;
  late final TextEditingController _s12Medium;
  late final TextEditingController _s12Year;
  late final TextEditingController _s12Score;
  late final TextEditingController _s10Board;
  late final TextEditingController _s10Medium;
  late final TextEditingController _s10Year;
  late final TextEditingController _s10Score;

  bool _saving = false;
  String? _serverDraftId;

  ResumeModel _seed() {
    if (widget.initialResume != null) return widget.initialResume!;
    if (widget.legacyInitialResume != null) {
      return ResumeModel.fromLegacyJsonResume(widget.legacyInitialResume!);
    }
    final fromProf = resumeModelFromSeekerProfileMaps(
      profile: widget.seekerProfile,
      sessionUser: AppSession.user,
    );
    if (widget.template.builderKey == ResumeBuilderIds.minimalAts) {
      return mergeResumePreferNonEmpty(fromProf, ResumeModel.minimalAtsStarter());
    }
    if (resumeModelHasUserContent(fromProf)) {
      return fromProf;
    }
    return ResumeModel.empty();
  }

  void _applyControllersFromModel(ResumeModel m) {
    _titleCtrl.text = m.draftTitle;
    _nameCtrl.text = m.fullName;
    _headlineCtrl.text = m.professionalTitle;
    _mobileCtrl.text = m.contact.mobile;
    _emailCtrl.text = m.contact.email;
    _locationCtrl.text = _detailLabel(m.personalDetails, 'Current Location');
    _linkedinCtrl.text = _detailLabel(m.personalDetails, 'LinkedIn');
    _dobCtrl.text = _detailLabel(m.personalDetails, 'Date of Birth');
    _genderCtrl.text = _detailLabel(m.personalDetails, 'Gender');
    _summaryCtrl.text = m.summary;
    _skillsCtrl.text = m.skills.join('\n');
    _langsCtrl.text = m.languages.join('\n');
    _certsCtrl.text = m.certifications.join('\n');
    _personalCtrl.text = _personalExtraLines(m);
    _gCourse.text = m.education.graduation.course;
    _gCollege.text = m.education.graduation.college;
    _gScore.text = m.education.graduation.score;
    _s12Board.text = m.education.schooling.class12.boardName;
    _s12Medium.text = m.education.schooling.class12.medium;
    _s12Year.text = m.education.schooling.class12.yearOfPassing;
    _s12Score.text = m.education.schooling.class12.score;
    _s10Board.text = m.education.schooling.class10.boardName;
    _s10Medium.text = m.education.schooling.class10.medium;
    _s10Year.text = m.education.schooling.class10.yearOfPassing;
    _s10Score.text = m.education.schooling.class10.score;
  }

  Future<void> _hydrateSeekerProfileWhenMissing() async {
    if (widget.seekerProfile != null) return;
    if (!AppSession.isLoggedIn) return;
    if (widget.initialResume != null || widget.legacyInitialResume != null) return;
    try {
      final p = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      final fromApi = resumeModelFromSeekerProfileMaps(profile: p, sessionUser: AppSession.user);
      if (!resumeModelHasUserContent(fromApi)) return;
      final merged = widget.template.builderKey == ResumeBuilderIds.minimalAts
          ? mergeResumePreferNonEmpty(fromApi, ResumeModel.minimalAtsStarter())
          : fromApi;
      final withId = merged.copyWith(templateId: kResumeTemplateResume1);
      setState(() => _applyControllersFromModel(withId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          ProviderScope.containerOf(context).read(resumeDraftProvider.notifier).replaceAll(withId);
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _narrowTabController = TabController(length: 2, vsync: this);
    _summaryFocus = FocusNode();
    _serverDraftId = widget.existingResumeId;
    final m = _seed().copyWith(templateId: kResumeTemplateResume1);

    _titleCtrl = TextEditingController(text: m.draftTitle);
    _nameCtrl = TextEditingController(text: m.fullName);
    _headlineCtrl = TextEditingController(text: m.professionalTitle);
    _mobileCtrl = TextEditingController(text: m.contact.mobile);
    _emailCtrl = TextEditingController(text: m.contact.email);
    _locationCtrl = TextEditingController(text: _detailLabel(m.personalDetails, 'Current Location'));
    _linkedinCtrl = TextEditingController(text: _detailLabel(m.personalDetails, 'LinkedIn'));
    _dobCtrl = TextEditingController(text: _detailLabel(m.personalDetails, 'Date of Birth'));
    _genderCtrl = TextEditingController(text: _detailLabel(m.personalDetails, 'Gender'));
    _summaryCtrl = TextEditingController(text: m.summary);
    _skillsCtrl = TextEditingController(text: m.skills.join('\n'));
    _langsCtrl = TextEditingController(text: m.languages.join('\n'));
    _certsCtrl = TextEditingController(text: m.certifications.join('\n'));
    _personalCtrl = TextEditingController(text: _personalExtraLines(m));

    _gCourse = TextEditingController(text: m.education.graduation.course);
    _gCollege = TextEditingController(text: m.education.graduation.college);
    _gScore = TextEditingController(text: m.education.graduation.score);

    _s12Board = TextEditingController(text: m.education.schooling.class12.boardName);
    _s12Medium = TextEditingController(text: m.education.schooling.class12.medium);
    _s12Year = TextEditingController(text: m.education.schooling.class12.yearOfPassing);
    _s12Score = TextEditingController(text: m.education.schooling.class12.score);
    _s10Board = TextEditingController(text: m.education.schooling.class10.boardName);
    _s10Medium = TextEditingController(text: m.education.schooling.class10.medium);
    _s10Year = TextEditingController(text: m.education.schooling.class10.yearOfPassing);
    _s10Score = TextEditingController(text: m.education.schooling.class10.score);

    Future<void>.microtask(() => _hydrateSeekerProfileWhenMissing());
  }

  @override
  void dispose() {
    _narrowTabController.dispose();
    _summaryFocus.dispose();
    _titleCtrl.dispose();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _summaryCtrl.dispose();
    _skillsCtrl.dispose();
    _langsCtrl.dispose();
    _certsCtrl.dispose();
    _personalCtrl.dispose();
    _gCourse.dispose();
    _gCollege.dispose();
    _gScore.dispose();
    _s12Board.dispose();
    _s12Medium.dispose();
    _s12Year.dispose();
    _s12Score.dispose();
    _s10Board.dispose();
    _s10Medium.dispose();
    _s10Year.dispose();
    _s10Score.dispose();
    super.dispose();
  }

  List<PersonalDetailRow> _parsePersonal(String raw) {
    final out = <PersonalDetailRow>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final idx = t.indexOf(':');
      if (idx <= 0) {
        out.add(PersonalDetailRow(label: '', value: t));
      } else {
        out.add(PersonalDetailRow(
          label: t.substring(0, idx).trim(),
          value: t.substring(idx + 1).trim(),
        ));
      }
    }
    return out;
  }

  List<PersonalDetailRow> _mergePersonalDetailsRows() {
    final merged = <PersonalDetailRow>[];
    void add(String label, String value) {
      if (value.trim().isEmpty) return;
      merged.add(PersonalDetailRow(label: label, value: value.trim()));
    }

    add('Current Location', _locationCtrl.text);
    add('LinkedIn', _linkedinCtrl.text);
    add('Date of Birth', _dobCtrl.text);
    add('Gender', _genderCtrl.text);
    const skip = {'current location', 'date of birth', 'gender', 'linkedin'};
    for (final r in _parsePersonal(_personalCtrl.text)) {
      final k = r.label.trim().toLowerCase();
      if (skip.contains(k)) continue;
      merged.add(r);
    }
    return merged;
  }

  void _insertSummarySnippet(String snippet, WidgetRef ref) {
    final c = _summaryCtrl;
    final sel = c.selection;
    if (!sel.isValid) {
      c.text = c.text + snippet;
    } else {
      final t = c.text;
      final newText = t.replaceRange(sel.start, sel.end, snippet);
      final off = sel.start + snippet.length;
      c.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: off),
      );
    }
    _syncStaticFieldsToNotifier(ref);
  }

  ResumeModel _composeModel(ResumeModel dynamicLists) {
    return dynamicLists.copyWith(
      draftTitle: _titleCtrl.text,
      fullName: _nameCtrl.text,
      professionalTitle: _headlineCtrl.text,
      contact: ContactInfo(mobile: _mobileCtrl.text, email: _emailCtrl.text),
      summary: _summaryCtrl.text,
      skills: _skillsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      languages: _langsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      certifications: _certsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      personalDetails: _mergePersonalDetailsRows(),
      education: EducationData(
        graduation: GraduationBlock(
          course: _gCourse.text,
          college: _gCollege.text,
          score: _gScore.text,
        ),
        schooling: SchoolingBlock(
          class12: SchoolingColumn(
            boardName: _s12Board.text,
            medium: _s12Medium.text,
            yearOfPassing: _s12Year.text,
            score: _s12Score.text,
          ),
          class10: SchoolingColumn(
            boardName: _s10Board.text,
            medium: _s10Medium.text,
            yearOfPassing: _s10Year.text,
            score: _s10Score.text,
          ),
        ),
      ),
    );
  }

  Future<void> _persistServer(WidgetRef ref) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a resume title to save to your account.')),
      );
      return;
    }
    final merged = _composeModel(ref.read(resumeDraftProvider));
    ref.read(resumeDraftProvider.notifier).replaceAll(merged);

    setState(() => _saving = true);
    try {
      final draftIdInt = int.tryParse(_serverDraftId ?? '');
      final result = await _apiService.createResume(
        widget.userId,
        widget.token,
        widget.template.id.toString(),
        title,
        resumeModelToApiEnvelope(merged),
        draftIdInt,
      );
      final rawResume = result['resume'] ?? result['data'];
      if (result['success'] != true || rawResume is! Map<String, dynamic>) {
        throw Exception('Failed to save resume');
      }
      final created = Resume.fromJson(rawResume);
      _serverDraftId = created.id;
      ref.read(resumeDraftProvider.notifier).notifyPersistedSnapshot();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume saved'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportPdf(WidgetRef ref) async {
    final merged = _composeModel(ref.read(resumeDraftProvider));
    ref.read(resumeDraftProvider.notifier).replaceAll(merged);
    final studio = ref.read(resumeStudioAppearanceProvider);
    final bytes = await exportResumePdf(
      model: merged,
      templateMeta: widget.template,
      studioAppearance: studio,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _pickPhoto(WidgetRef ref) async {
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 720);
    if (pick == null) return;
    final raw = await pick.readAsBytes();
    ref.read(resumeDraftProvider.notifier).setProfileBase64(base64Encode(raw), clearUrl: true);
  }

  void _syncStaticFieldsToNotifier(WidgetRef ref) {
    ref.read(resumeDraftProvider.notifier).replaceAll(_composeModel(ref.read(resumeDraftProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final seed = _seed().copyWith(templateId: kResumeTemplateResume1);

    return ProviderScope(
      overrides: [
        resumeInitialProvider.overrideWith((ref) => seed),
        resumeAutosaveContextProvider.overrideWith(
          (ref) => ResumeAutosaveContext(
            userKey: widget.userId,
            token: widget.token,
            existingDraftId: _serverDraftId ?? widget.existingResumeId,
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final dynamicModel = ref.watch(resumeDraftProvider);

          if (!_bootstrappedNotifier) {
            _bootstrappedNotifier = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncStaticFieldsToNotifier(ref);
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: LayoutBuilder(
              builder: (context, cons) {
                final wide = cons.maxWidth >= 960;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStudioTopBar(ref, wide: wide),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _editorWithRail(ref, dynamicModel, context),
                                ),
                                const VerticalDivider(width: 1),
                                Expanded(
                                  flex: 5,
                                  child: _buildPreviewColumn(ref, context),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Material(
                                  color: Colors.white,
                                  child: TabBar(
                                    controller: _narrowTabController,
                                    labelColor: ref
                                        .watch(resumeStudioAppearanceProvider)
                                        .resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
                                    indicatorColor: ref
                                        .watch(resumeStudioAppearanceProvider)
                                        .resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
                                    tabs: const [
                                      Tab(text: 'Edit'),
                                      Tab(text: 'Preview'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _narrowTabController,
                                    children: [
                                      _editorWithRail(ref, dynamicModel, context),
                                      _buildPreviewColumn(ref, context),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudioTopBar(WidgetRef ref, {required bool wide}) {
    final accent =
        ref.watch(resumeStudioAppearanceProvider).resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template)));
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 17,
      color: accent,
    );

    final actionRow = <Widget>[
      IconButton(
        tooltip: 'Undo',
        onPressed: null,
        icon: Icon(Icons.undo, color: Colors.grey.shade400),
      ),
      IconButton(
        tooltip: 'Redo',
        onPressed: null,
        icon: Icon(Icons.redo, color: Colors.grey.shade400),
      ),
      Icon(Icons.check_circle, size: 18, color: AppColors.success),
      const SizedBox(width: 4),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Text(
          'All changes saved',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ),
      TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: wide
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live preview is on the right')),
                );
              }
            : () => _narrowTabController.animateTo(1),
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('Preview'),
      ),
      TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ResumeTemplatesScreen(
                userId: widget.userId,
                token: widget.token,
              ),
            ),
          );
        },
        icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
        label: const Text('Templates'),
      ),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _exportPdf(ref),
        icon: const Icon(Icons.download_outlined, size: 18),
        label: const Text('PDF'),
      ),
      TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _saving ? null : () => _persistServer(ref),
        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
        label: const Text('Save'),
      ),
    ];

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.article_outlined, color: accent, size: 26),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Resume Builder',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Resume title',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                  ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: actionRow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewColumn(WidgetRef ref, BuildContext context) {
    final draft = ref.watch(resumeDraftProvider);
    final merged = _composeModel(draft);
    final studio = ref.watch(resumeStudioAppearanceProvider);
    final builder = ResumeTemplateRegistry.instance.resolve(widget.template.builderKey);

    return ColoredBox(
      color: const Color(0xFFECEFF3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinch to zoom · drag to pan · opens fitted to screen · A4 (${kResumeA4Width.toInt()}×${kResumeA4Height.toInt()})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _A4InteractiveResumePreview(
              sheet: KeyedSubtree(
                key: ValueKey(
                  '${merged.fullName}|${merged.summary}|${merged.profileImageBase64?.length ?? 0}|'
                  '${studio.sheetBrightness}|${studio.headingFont}|${studio.bodyFont}|'
                  '${studio.accentOverride}|${widget.template.builderKey}',
                ),
                child: builder.buildFlutterSheet(context, merged, studio, widget.template),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorPane(int index, WidgetRef ref, ResumeModel dynamicModel, BuildContext context) {
    switch (index) {
      case 0:
        return _personalPane(ref, dynamicModel, context);
      case 1:
        return _summaryPane(ref, context);
      case 2:
        return _educationPane(ref, context);
      case 3:
        return _experiencePane(ref, dynamicModel);
      case 4:
        return _projectsPane(ref, dynamicModel);
      case 5:
        return _skillsPane(ref, context);
      case 6:
        return _certsPane(ref, context);
      case 7:
        return _languagesPane(ref, context);
      default:
        return _settingsPane(ref, dynamicModel, context);
    }
  }

  ImageProvider<Object>? _profileImage(ResumeModel m) {
    final b64 = m.profileImageBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(b64));
      } catch (_) {}
    }
    final u = m.profileImageUrl;
    if (u != null && u.trim().isNotEmpty) {
      return NetworkImage(u.trim());
    }
    return null;
  }

  Widget _personalPane(WidgetRef ref, ResumeModel dynamicModel, BuildContext context) {
    final img = _profileImage(dynamicModel);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Personal information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: img,
                    child: img == null ? Icon(Icons.person, size: 48, color: Colors.grey.shade500) : null,
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          ref.watch(resumeStudioAppearanceProvider).resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
                      side: BorderSide(
                        color: ref
                            .watch(resumeStudioAppearanceProvider)
                            .resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
                      ),
                    ),
                    onPressed: () => _pickPhoto(ref),
                    child: const Text('Change Photo'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () {
                      ref.read(resumeDraftProvider.notifier).setProfileBase64(null, clearUrl: true);
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _headlineCtrl,
                decoration: const InputDecoration(labelText: 'Title / Profession'),
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mobileCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Current Location'),
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkedinCtrl,
                decoration: const InputDecoration(labelText: 'LinkedIn (profile URL or handle)'),
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dobCtrl,
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _genderCtrl,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Other details (label: value per line)', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _personalCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. LinkedIn: https://...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      ref.watch(resumeStudioAppearanceProvider).resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _saving ? null : () => _persistServer(ref),
                child: const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryPane(WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Resume summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Bold',
                        icon: const Icon(Icons.format_bold),
                        onPressed: () => _insertSummarySnippet('**', ref),
                      ),
                      IconButton(
                        tooltip: 'Italic',
                        icon: const Icon(Icons.format_italic),
                        onPressed: () => _insertSummarySnippet('_', ref),
                      ),
                      IconButton(
                        tooltip: 'Bullet line',
                        icon: const Icon(Icons.format_list_bulleted),
                        onPressed: () => _insertSummarySnippet('• ', ref),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _summaryCtrl,
                focusNode: _summaryFocus,
                decoration: const InputDecoration(
                  hintText: 'Write a short professional summary…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 8,
                maxLines: 14,
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _educationPane(WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Education', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _ExpansionCard(
                title: 'Graduation',
                child: Column(
                  children: [
                    TextField(
                      controller: _gCourse,
                      decoration: const InputDecoration(labelText: 'Course'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _gCollege,
                      decoration: const InputDecoration(labelText: 'College'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _gScore,
                      decoration: InputDecoration(
                        labelText: widget.template.builderKey == ResumeBuilderIds.minimalAts
                            ? 'Graduation date (right column on résumé)'
                            : 'Score',
                      ),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ],
                ),
              ),
              _ExpansionCard(
                title: 'Schooling — Class XII',
                child: Column(
                  children: [
                    TextField(
                      controller: _s12Board,
                      decoration: const InputDecoration(labelText: 'Board'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s12Medium,
                      decoration: const InputDecoration(labelText: 'Medium'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s12Year,
                      decoration: const InputDecoration(labelText: 'Year of passing'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s12Score,
                      decoration: const InputDecoration(labelText: 'Score'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ],
                ),
              ),
              _ExpansionCard(
                title: 'Schooling — Class X',
                child: Column(
                  children: [
                    TextField(
                      controller: _s10Board,
                      decoration: const InputDecoration(labelText: 'Board'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s10Medium,
                      decoration: const InputDecoration(labelText: 'Medium'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s10Year,
                      decoration: const InputDecoration(labelText: 'Year of passing'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                    TextField(
                      controller: _s10Score,
                      decoration: const InputDecoration(labelText: 'Score'),
                      onChanged: (_) => _syncStaticFieldsToNotifier(ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _experiencePane(WidgetRef ref, ResumeModel dynamicModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExperienceListCard(
                title: 'Internships',
                items: dynamicModel.internships,
                onChanged: (list) => ref.read(resumeDraftProvider.notifier).setInternships(list),
              ),
              _ExperienceListCard(
                title: 'Work experience',
                items: dynamicModel.workExperience,
                onChanged: (list) => ref.read(resumeDraftProvider.notifier).setWork(list),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectsPane(WidgetRef ref, ResumeModel dynamicModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _ExperienceListCard(
            title: 'Projects',
            items: dynamicModel.projects,
            onChanged: (list) => ref.read(resumeDraftProvider.notifier).setProjects(list),
          ),
        ),
      ),
    );
  }

  Widget _skillsPane(WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Skills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _skillsCtrl,
                decoration: const InputDecoration(
                  hintText: 'One skill per line',
                  border: OutlineInputBorder(),
                ),
                maxLines: 12,
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _certsPane(WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Certifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _certsCtrl,
                decoration: const InputDecoration(
                  hintText: 'One certification per line',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languagesPane(WidgetRef ref, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Languages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _langsCtrl,
                decoration: const InputDecoration(
                  hintText: 'One language per line',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                onChanged: (_) => _syncStaticFieldsToNotifier(ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsPane(WidgetRef ref, ResumeModel m, BuildContext context) {
    bool vis(String k) => m.sectionVisible[k] ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Typography & sheet theme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ResumeFontFamily>(
                initialValue: ref.watch(resumeStudioAppearanceProvider).headingFont,
                decoration: const InputDecoration(
                  labelText: 'Heading font',
                  border: OutlineInputBorder(),
                ),
                items: ResumeFontFamily.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) ref.read(resumeStudioAppearanceProvider.notifier).setHeadingFont(v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ResumeFontFamily>(
                initialValue: ref.watch(resumeStudioAppearanceProvider).bodyFont,
                decoration: const InputDecoration(
                  labelText: 'Body font',
                  border: OutlineInputBorder(),
                ),
                items: ResumeFontFamily.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) ref.read(resumeStudioAppearanceProvider.notifier).setBodyFont(v);
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<Brightness>(
                segments: const [
                  ButtonSegment(
                    value: Brightness.light,
                    label: Text('Light sheet'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: Brightness.dark,
                    label: Text('Dark sheet'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {ref.watch(resumeStudioAppearanceProvider).sheetBrightness},
                onSelectionChanged: (next) {
                  if (next.isNotEmpty) {
                    ref.read(resumeStudioAppearanceProvider.notifier).setSheetBrightness(next.first);
                  }
                },
              ),
              const SizedBox(height: 12),
              Text('Accent override', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Template default'),
                    onPressed: () => ref.read(resumeStudioAppearanceProvider.notifier).setAccent(null),
                  ),
                  for (final c in const [
                    Colors.blue,
                    Colors.teal,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.red,
                    Colors.orange,
                  ])
                    InkWell(
                      onTap: () => ref.read(resumeStudioAppearanceProvider.notifier).setAccent(c),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(backgroundColor: c, radius: 18),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Preview sections', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Sidebar (contact, photo column)'),
                value: vis(ResumeSectionKeys.sidebar),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.sidebar, v),
              ),
              SwitchListTile(
                title: const Text('Summary'),
                value: vis(ResumeSectionKeys.summary),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.summary, v),
              ),
              SwitchListTile(
                title: const Text('Personal details'),
                value: vis(ResumeSectionKeys.personal),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.personal, v),
              ),
              SwitchListTile(
                title: const Text('Education'),
                value: vis(ResumeSectionKeys.education),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.education, v),
              ),
              SwitchListTile(
                title: const Text('Skills'),
                value: vis(ResumeSectionKeys.skills),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.skills, v),
              ),
              SwitchListTile(
                title: const Text('Languages'),
                value: vis(ResumeSectionKeys.languages),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.languages, v),
              ),
              SwitchListTile(
                title: const Text('Certifications'),
                value: vis(ResumeSectionKeys.certifications),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.certifications, v),
              ),
              SwitchListTile(
                title: const Text('Internships'),
                value: vis(ResumeSectionKeys.internships),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.internships, v),
              ),
              SwitchListTile(
                title: const Text('Projects'),
                value: vis(ResumeSectionKeys.projects),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.projects, v),
              ),
              SwitchListTile(
                title: const Text('Work experience'),
                value: vis(ResumeSectionKeys.work),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.work, v),
              ),
              SwitchListTile(
                title: const Text('Custom sections'),
                value: vis(ResumeSectionKeys.custom),
                onChanged: (v) => ref.read(resumeDraftProvider.notifier).setSectionVisible(ResumeSectionKeys.custom, v),
              ),
              const SizedBox(height: 16),
              Text('Custom sections', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _ExtraSectionsEditor(
                sections: m.extraSections,
                onChanged: (list) => ref.read(resumeDraftProvider.notifier).setExtraSections(list),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NavigationRailDestination> _railDestinations() => [
        const NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Personal')),
        const NavigationRailDestination(icon: Icon(Icons.article_outlined), label: Text('Summary')),
        const NavigationRailDestination(icon: Icon(Icons.school_outlined), label: Text('Education')),
        const NavigationRailDestination(icon: Icon(Icons.work_outline), label: Text('Experience')),
        const NavigationRailDestination(icon: Icon(Icons.folder_special_outlined), label: Text('Projects')),
        const NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('Skills')),
        const NavigationRailDestination(icon: Icon(Icons.verified_outlined), label: Text('Certs')),
        const NavigationRailDestination(icon: Icon(Icons.language), label: Text('Languages')),
        const NavigationRailDestination(icon: Icon(Icons.settings_outlined), label: Text('Settings')),
      ];

  Widget _editorWithRail(WidgetRef ref, ResumeModel dynamicModel, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationRail(
          selectedIndex: _railIndex,
          onDestinationSelected: (i) => setState(() => _railIndex = i),
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(
            color: ref.watch(resumeStudioAppearanceProvider).resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
          ),
          selectedLabelTextStyle: TextStyle(
            color: ref.watch(resumeStudioAppearanceProvider).resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template))),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          indicatorColor: ref
              .watch(resumeStudioAppearanceProvider)
              .resolvedAccent(Color(safeResumeTemplateAccentArgb(widget.template)))
              .withValues(alpha: 0.15),
          minWidth: 88,
          destinations: _railDestinations(),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF5F7FA),
            child: _editorPane(_railIndex, ref, dynamicModel, context),
          ),
        ),
      ],
    );
  }
}

class _ExpansionCard extends StatelessWidget {
  const _ExpansionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ExperienceListCard extends StatefulWidget {
  const _ExperienceListCard({
    required this.title,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final List<ExperienceItem> items;
  final ValueChanged<List<ExperienceItem>> onChanged;

  @override
  State<_ExperienceListCard> createState() => _ExperienceListCardState();
}

class _ExperienceListCardState extends State<_ExperienceListCard> {
  late List<_ExpControllers> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.items.map(_ExpControllers.fromItem).toList();
    if (_rows.isEmpty) {
      _rows = [_ExpControllers.blank()];
    }
  }

  @override
  void didUpdateWidget(covariant _ExperienceListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items && widget.items.length != _rows.length) {
      _disposeRows();
      _rows = widget.items.map(_ExpControllers.fromItem).toList();
      if (_rows.isEmpty) _rows = [_ExpControllers.blank()];
    }
  }

  void _disposeRows() {
    for (final r in _rows) {
      r.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_rows.map((r) => r.toItem()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return _ExpansionCard(
      title: widget.title,
      child: Column(
        children: [
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _rows[i].company,
                    decoration: const InputDecoration(labelText: 'Company / heading'),
                    onChanged: (_) => _emit(),
                  ),
                  TextField(
                    controller: _rows[i].dates,
                    decoration: const InputDecoration(labelText: 'Date range'),
                    onChanged: (_) => _emit(),
                  ),
                  TextField(
                    controller: _rows[i].bullets,
                    decoration: const InputDecoration(labelText: 'Bullets (one per line)'),
                    maxLines: 5,
                    onChanged: (_) => _emit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _rows[i].dispose();
                          _rows.removeAt(i);
                          if (_rows.isEmpty) _rows = [_ExpControllers.blank()];
                          _emit();
                        });
                      },
                      child: const Text('Remove'),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _rows.add(_ExpControllers.blank());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
          ),
        ],
      ),
    );
  }
}

class _ExpControllers {
  _ExpControllers({
    required this.company,
    required this.dates,
    required this.bullets,
    required this.id,
  });

  factory _ExpControllers.blank() => _ExpControllers(
        company: TextEditingController(),
        dates: TextEditingController(),
        bullets: TextEditingController(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  factory _ExpControllers.fromItem(ExperienceItem it) => _ExpControllers(
        company: TextEditingController(text: it.companyName),
        dates: TextEditingController(text: it.dateRange),
        bullets: TextEditingController(text: it.bullets.join('\n')),
        id: it.id,
      );

  final TextEditingController company;
  final TextEditingController dates;
  final TextEditingController bullets;
  final String id;

  void dispose() {
    company.dispose();
    dates.dispose();
    bullets.dispose();
  }

  ExperienceItem toItem() => ExperienceItem(
        id: id,
        companyName: company.text,
        dateRange: dates.text,
        bullets: bullets.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

class _ExtraSectionsEditor extends StatefulWidget {
  const _ExtraSectionsEditor({required this.sections, required this.onChanged});

  final List<DynamicResumeSection> sections;
  final ValueChanged<List<DynamicResumeSection>> onChanged;

  @override
  State<_ExtraSectionsEditor> createState() => _ExtraSectionsEditorState();
}

class _ExtraSectionsEditorState extends State<_ExtraSectionsEditor> {
  late List<_ExtraCtr> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.sections.map(_ExtraCtr.fromSec).toList();
  }

  @override
  void didUpdateWidget(covariant _ExtraSectionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      for (final r in _rows) {
        r.dispose();
      }
      _rows = widget.sections.map(_ExtraCtr.fromSec).toList();
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_rows.map((r) => r.toSection()).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _rows[i].title,
                  decoration: const InputDecoration(labelText: 'Section title'),
                  onChanged: (_) => _emit(),
                ),
                TextField(
                  controller: _rows[i].lines,
                  decoration: const InputDecoration(labelText: 'Lines (one per line)'),
                  maxLines: 5,
                  onChanged: (_) => _emit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _rows[i].dispose();
                        _rows.removeAt(i);
                        _emit();
                      });
                    },
                    child: const Text('Remove section'),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _rows.add(_ExtraCtr.blank());
              _emit();
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add section'),
        ),
      ],
    );
  }
}

/// Pinch-zoom preview with an initial **fit-to-viewport** transform so the full A4 sheet is visible and centered.
class _A4InteractiveResumePreview extends StatefulWidget {
  const _A4InteractiveResumePreview({required this.sheet});

  final Widget sheet;

  @override
  State<_A4InteractiveResumePreview> createState() => _A4InteractiveResumePreviewState();
}

class _A4InteractiveResumePreviewState extends State<_A4InteractiveResumePreview> {
  final TransformationController _tc = TransformationController();
  Size? _lastFittedSize;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _fitToViewport(Size viewport) {
    const double pw = kResumeA4Width;
    const double ph = kResumeA4Height;
    const double pad = 10.0;
    final double availW = math.max(0.0, viewport.width - pad * 2);
    final double availH = math.max(0.0, viewport.height - pad * 2);
    if (availW <= 8 || availH <= 8) return;

    final double scale = math.min(availW / pw, availH / ph).clamp(0.12, 1.12);
    final double sx = pw * scale;
    final double sy = ph * scale;
    final double tx = (viewport.width - sx) / 2.0;
    final double ty = (viewport.height - sy) / 2.0;

    final m = Matrix4.identity();
    m.setEntry(0, 0, scale);
    m.setEntry(1, 1, scale);
    m.setEntry(0, 3, tx);
    m.setEntry(1, 3, ty);
    _tc.value = m;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sz = constraints.biggest;
        if (sz.width > 8 &&
            sz.height > 8 &&
            (_lastFittedSize == null ||
                (sz.width - _lastFittedSize!.width).abs() > 0.5 ||
                (sz.height - _lastFittedSize!.height).abs() > 0.5)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _fitToViewport(sz);
            _lastFittedSize = sz;
          });
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InteractiveViewer(
            transformationController: _tc,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.08,
            maxScale: 3.8,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: kResumeA4Width,
              height: kResumeA4Height,
              child: widget.sheet,
            ),
          ),
        );
      },
    );
  }
}

class _ExtraCtr {
  _ExtraCtr({required this.title, required this.lines, required this.id});

  factory _ExtraCtr.blank() => _ExtraCtr(
        title: TextEditingController(),
        lines: TextEditingController(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  factory _ExtraCtr.fromSec(DynamicResumeSection s) => _ExtraCtr(
        title: TextEditingController(text: s.title),
        lines: TextEditingController(text: s.lines.join('\n')),
        id: s.id,
      );

  final TextEditingController title;
  final TextEditingController lines;
  final String id;

  void dispose() {
    title.dispose();
    lines.dispose();
  }

  DynamicResumeSection toSection() => DynamicResumeSection(
        id: id,
        title: title.text,
        lines: lines.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      );
}
