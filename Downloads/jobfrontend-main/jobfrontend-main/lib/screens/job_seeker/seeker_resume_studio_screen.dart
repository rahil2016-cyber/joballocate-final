import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/features/resume/services/resume_seed_from_profile.dart';
import 'package:joballocate/services/app_session.dart';
import 'package:joballocate/services/job_seeker_api_service.dart';
import 'package:joballocate/utils/app_colors.dart';
import 'package:joballocate/utils/media_url.dart';
import 'package:joballocate/widgets/industry_type_dropdown.dart';
import 'package:joballocate/widgets/seeker_html_template_swatch.dart';

import 'resume_html_preview_screen.dart';

String _rowVal(List<PersonalDetailRow> rows, String label) {
  final w = label.trim().toLowerCase();
  for (final r in rows) {
    if (r.label.trim().toLowerCase() == w) return r.value;
  }
  return '';
}

const _genderDropdownItems = ['Male', 'Female', 'Prefer not to say'];

/// Values from the API may not match dropdown items; invalid values trigger framework asserts.
String? _coerceGenderForDropdown(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  for (final g in _genderDropdownItems) {
    if (g.toLowerCase() == t.toLowerCase()) return g;
  }
  final low = t.toLowerCase();
  if (low == 'm' || low == 'male') return 'Male';
  if (low == 'f' || low == 'female') return 'Female';
  if (low.contains('prefer') || low == 'other' || low == 'n/a' || low == 'na') return 'Prefer not to say';
  return null;
}

String? _sanitizeIndustryTypeKey(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (!RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(t)) return null;
  return t;
}

String _dobDisplayFromProfile(Map<String, dynamic> p) {
  final raw = p['dob']?.toString() ?? p['date_of_birth']?.toString() ?? '';
  if (raw.isEmpty) return '';
  if (raw.length >= 10 && (raw.contains('-') || raw.contains('/'))) {
    return raw.substring(0, 10);
  }
  final d = DateTime.tryParse(raw);
  if (d != null) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
  return raw;
}

List<Map<String, dynamic>> _internshipsApi(ResumeModel m) {
  return m.internships
      .map(
        (e) => {
          'organization': e.companyName,
          'role': '',
          'duration': e.dateRange,
          'description': e.bullets.join('\n'),
        },
      )
      .toList();
}

List<Map<String, dynamic>> _projectsApi(ResumeModel m) {
  return m.projects
      .map(
        (e) => {
          'title': e.companyName,
          'link': e.dateRange,
          'description': e.bullets.join('\n'),
        },
      )
      .toList();
}

List<Map<String, dynamic>> _languagesApi(ResumeModel m) {
  final out = <Map<String, dynamic>>[];
  for (final line in m.languages) {
    final parts = line.split(RegExp(r'\s*—\s*'));
    out.add({
      'language': parts.first.trim(),
      if (parts.length > 1) 'proficiency': parts.sublist(1).join('—').trim(),
    });
  }
  return out;
}

List<Map<String, dynamic>> _certsApi(ResumeModel m) {
  final out = <Map<String, dynamic>>[];
  for (final c in m.certifications) {
    final parts = c.split(RegExp(r'\s*—\s*'));
    out.add({
      'name': parts.first.trim(),
      if (parts.length > 1) 'date': parts.sublist(1).join('—').trim(),
    });
  }
  return out;
}

List<Map<String, dynamic>> _titleDetailPayload(List<TextEditingController> ctrls) {
  final out = <Map<String, dynamic>>[];
  for (final c in ctrls) {
    final line = c.text.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s*—\s*'));
    out.add({
      'title': parts.first.trim(),
      if (parts.length > 1) 'detail': parts.sublist(1).join('—').trim(),
    });
  }
  return out;
}

List<Map<String, dynamic>> _examResultPayload(List<TextEditingController> ctrls) {
  final out = <Map<String, dynamic>>[];
  for (final c in ctrls) {
    final line = c.text.trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'\s*—\s*'));
    out.add({
      'exam': parts.first.trim(),
      if (parts.length > 1) 'result': parts.sublist(1).join('—').trim(),
    });
  }
  return out;
}

void _mergeProfileResponseIntoSession(Map<String, dynamic> data) {
  final u = AppSession.user;
  if (u == null) return;
  final merged = Map<String, dynamic>.from(u);
  final e = data['email']?.toString().trim();
  final ph = data['phone']?.toString().trim();
  if (e != null && e.isNotEmpty) merged['email'] = e;
  if (ph != null && ph.isNotEmpty) merged['phone'] = ph;
  final url = data['profile_photo_url']?.toString().trim();
  if (url != null && url.isNotEmpty) merged['profile_photo_url'] = url;
  AppSession.updateUser(merged);
}

void _fillTitleDetailCtrls(List<TextEditingController> target, dynamic raw) {
  if (raw is! List) return;
  for (final a in raw) {
    if (a is! Map) continue;
    final t = a['title']?.toString().trim() ?? '';
    final d = a['detail']?.toString().trim() ?? '';
    final line = d.isNotEmpty ? '$t — $d' : t;
    if (line.isNotEmpty) target.add(TextEditingController(text: line));
  }
}

void _fillExamCtrls(List<TextEditingController> target, dynamic raw) {
  if (raw is! List) return;
  for (final a in raw) {
    if (a is! Map) continue;
    final ex = a['exam']?.toString().trim() ?? '';
    final r = a['result']?.toString().trim() ?? '';
    final line = r.isNotEmpty ? '$ex — $r' : ex;
    if (line.isNotEmpty) target.add(TextEditingController(text: line));
  }
}

/// Job seeker resume editor — syncs `resume_model_v1` + structured columns to Laravel profile and resume draft.
class SeekerResumeStudioScreen extends StatefulWidget {
  const SeekerResumeStudioScreen({
    super.key,
    this.resumeDraftId,
    this.initialModel,
    this.templateIdForSave = '1',
  });

  final int? resumeDraftId;
  final ResumeModel? initialModel;
  final String templateIdForSave;

  @override
  State<SeekerResumeStudioScreen> createState() => _SeekerResumeStudioScreenState();
}

class _SeekerResumeStudioScreenState extends State<SeekerResumeStudioScreen> {
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  String? _error;
  ResumeModel _model = ResumeModel.empty();
  List<Map<String, dynamic>> _education = [];
  bool _residingIndia = true;

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _hometown;
  late final TextEditingController _highestQual;
  late final TextEditingController _headline;
  late final TextEditingController _summary;
  late final TextEditingController _skills;
  late final TextEditingController _langs;
  late final TextEditingController _certs;
  late final TextEditingController _dob;
  late final TextEditingController _portfolio;
  late final TextEditingController _expYears;
  late final TextEditingController _minSal;
  late final TextEditingController _maxSal;

  String? _gender;
  String? _industryType;
  final List<TextEditingController> _achievementCtrls = [];
  final List<TextEditingController> _academicCtrls = [];
  final List<TextEditingController> _awardsCtrls = [];
  final List<TextEditingController> _examCtrls = [];

  XFile? _pickedProfilePhoto;
  String? _profilePhotoBase64;
  String? _profilePhotoUrl;

  int _strengthPercent(ResumeModel m) {
    int n = 0;
    const t = 14;
    void c(bool x) {
      if (x) n++;
    }

    c(m.fullName.trim().isNotEmpty);
    c(m.contact.mobile.trim().isNotEmpty || m.contact.email.trim().isNotEmpty);
    c(m.summary.trim().isNotEmpty);
    c(m.skills.any((s) => s.trim().isNotEmpty));
    c(m.workExperience.isNotEmpty || m.internships.isNotEmpty);
    c(m.projects.isNotEmpty);
    c(m.education.graduation.course.trim().isNotEmpty || _education.isNotEmpty);
    c(m.languages.isNotEmpty);
    c(m.certifications.isNotEmpty);
    c(_hometown.text.trim().isNotEmpty);
    c(_profilePhotoUrl != null && _profilePhotoUrl!.trim().isNotEmpty || _profilePhotoBase64 != null);
    c(_highestQual.text.trim().isNotEmpty);
    c(_country.text.trim().isNotEmpty);
    c(_dob.text.trim().isNotEmpty || (_gender != null && _gender!.isNotEmpty));
    c(_industryType != null && _industryType!.trim().isNotEmpty);
    return ((n / t) * 100).round().clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _mobile = TextEditingController();
    _city = TextEditingController();
    _country = TextEditingController();
    _hometown = TextEditingController();
    _highestQual = TextEditingController();
    _headline = TextEditingController();
    _summary = TextEditingController();
    _skills = TextEditingController();
    _langs = TextEditingController();
    _certs = TextEditingController();
    _dob = TextEditingController();
    _portfolio = TextEditingController();
    _expYears = TextEditingController();
    _minSal = TextEditingController();
    _maxSal = TextEditingController();
    _bootstrap();
  }

  void _disposeAchievementCtrls() {
    for (final c in _achievementCtrls) {
      c.dispose();
    }
    _achievementCtrls.clear();
  }

  void _disposeStructuredExtraCtrls() {
    for (final c in _academicCtrls) {
      c.dispose();
    }
    _academicCtrls.clear();
    for (final c in _awardsCtrls) {
      c.dispose();
    }
    _awardsCtrls.clear();
    for (final c in _examCtrls) {
      c.dispose();
    }
    _examCtrls.clear();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      ResumeModel merged = widget.initialModel ?? ResumeModel.empty();
      if (AppSession.isLoggedIn) {
        final p = await JobSeekerApiService.instance.getSeekerProfile();
        final fromP = resumeModelFromSeekerProfileMaps(profile: p, sessionUser: AppSession.user);
        merged = widget.initialModel != null
            ? mergeResumePreferNonEmpty(widget.initialModel!, fromP)
            : fromP;
        final edu = p['education'];
        if (edu is List) {
          _education = edu.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          _education = [];
        }
        _residingIndia = p['residing_in_india'] != false;
        _highestQual.text = p['highest_qualification']?.toString() ?? '';
        _hometown.text = p['hometown']?.toString() ?? _rowVal(merged.personalDetails, 'Home Town');
        _country.text = p['country']?.toString() ?? '';
        _dob.text = _dobDisplayFromProfile(p);
        _gender = _coerceGenderForDropdown(p['gender']?.toString());
        _portfolio.text = p['portfolio_url']?.toString() ?? '';
        _expYears.text = p['experience_years']?.toString() ?? '';
        _minSal.text = p['expected_salary_min']?.toString() ?? '';
        _maxSal.text = p['expected_salary_max']?.toString() ?? '';
        _industryType = _sanitizeIndustryTypeKey(p['industry_type']?.toString());

        _disposeAchievementCtrls();
        final ach = p['achievements'];
        if (ach is List) {
          for (final a in ach) {
            final t = a?.toString().trim() ?? '';
            if (t.isNotEmpty) _achievementCtrls.add(TextEditingController(text: t));
          }
        }

        _disposeStructuredExtraCtrls();
        _fillTitleDetailCtrls(_academicCtrls, p['academic_achievements']);
        _fillTitleDetailCtrls(_awardsCtrls, p['awards_honors']);
        _fillExamCtrls(_examCtrls, p['competitive_exam_results']);

        final rawPhoto = p['profile_photo_url']?.toString() ?? '';
        _profilePhotoUrl = rawPhoto.trim().isNotEmpty ? (MediaUrl.resolve(rawPhoto.trim()) ?? rawPhoto.trim()) : null;
        _pickedProfilePhoto = null;
        _profilePhotoBase64 = null;
      }
      _model = merged;
      _applyControllers(merged);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  void _applyControllers(ResumeModel m) {
    _name.text = m.fullName;
    _headline.text = m.professionalTitle;
    _mobile.text = m.contact.mobile;
    _email.text = m.contact.email;
    _city.text = _rowVal(m.personalDetails, 'Current Location').split(',').first.trim();
    if (_country.text.isEmpty) {
      final loc = _rowVal(m.personalDetails, 'Current Location');
      final parts = loc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (parts.length > 1) _country.text = parts.sublist(1).join(', ');
    }
    if (_hometown.text.isEmpty) {
      _hometown.text = _rowVal(m.personalDetails, 'Home Town');
    }
    if (_portfolio.text.isEmpty) {
      _portfolio.text = _rowVal(m.personalDetails, 'Portfolio');
      if (_portfolio.text.isEmpty) {
        _portfolio.text = _rowVal(m.personalDetails, 'LinkedIn');
      }
    }
    if (_dob.text.isEmpty) {
      _dob.text = _rowVal(m.personalDetails, 'Date of Birth');
    }
    var mergedGender = _gender;
    if (mergedGender == null || mergedGender.trim().isEmpty) {
      mergedGender = _rowVal(m.personalDetails, 'Gender');
    }
    _gender = _coerceGenderForDropdown(mergedGender);
    _industryType = _sanitizeIndustryTypeKey(_industryType);
    _summary.text = m.summary;
    _skills.text = m.skills.join(', ');
    _langs.text = m.languages.join('\n');
    _certs.text = m.certifications.join('\n');
  }

  ResumeModel _compose() {
    final skills = _skills.text
        .split(RegExp(r'[,|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final langs = _langs.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final certs = _certs.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final city = _city.text.trim();
    final country = _country.text.trim();
    final personal = <PersonalDetailRow>[
      if (city.isNotEmpty || country.isNotEmpty)
        PersonalDetailRow(
          label: 'Current Location',
          value: [city, country].where((e) => e.isNotEmpty).join(', '),
        ),
      if (_hometown.text.trim().isNotEmpty) PersonalDetailRow(label: 'Home Town', value: _hometown.text.trim()),
      if (_dob.text.trim().isNotEmpty) PersonalDetailRow(label: 'Date of Birth', value: _dob.text.trim()),
      if (_gender != null && _gender!.trim().isNotEmpty) PersonalDetailRow(label: 'Gender', value: _gender!.trim()),
      if (_portfolio.text.trim().isNotEmpty)
        PersonalDetailRow(
          label: _portfolio.text.toLowerCase().contains('linkedin') ? 'LinkedIn' : 'Portfolio',
          value: _portfolio.text.trim(),
        ),
    ];
    final minS = _minSal.text.trim();
    final maxS = _maxSal.text.trim();
    if (minS.isNotEmpty || maxS.isNotEmpty) {
      personal.add(
        PersonalDetailRow(
          label: 'Expected salary (INR)',
          value: [minS, maxS].where((e) => e.isNotEmpty).join(' – '),
        ),
      );
    }

    return _model.copyWith(
      fullName: _name.text.trim(),
      professionalTitle: _headline.text.trim(),
      contact: ContactInfo(mobile: _mobile.text.trim(), email: _email.text.trim()),
      summary: _summary.text.trim(),
      skills: skills,
      languages: langs,
      certifications: certs,
      personalDetails: personal,
      profileImageBase64: _profilePhotoBase64,
      profileImageUrl: _profilePhotoBase64 != null ? _model.profileImageUrl : (_profilePhotoUrl ?? _model.profileImageUrl),
    );
  }

  List<String> _achievementsPayload() {
    return _achievementCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _save() async {
    final m = _compose();
    setState(() => _model = m);
    try {
      final env = resumeModelToApiEnvelope(m);
      final academicPayload = _titleDetailPayload(_academicCtrls);
      final awardsPayload = _titleDetailPayload(_awardsCtrls);
      final examsPayload = _examResultPayload(_examCtrls);
      final body = <String, dynamic>{
        'headline': m.professionalTitle,
        'bio': m.summary,
        'skills': m.skills,
        'city': _city.text.trim(),
        'country': _country.text.trim().isEmpty ? null : _country.text.trim(),
        'hometown': _hometown.text.trim(),
        'residing_in_india': _residingIndia,
        'highest_qualification': _highestQual.text.trim().isEmpty ? null : _highestQual.text.trim(),
        'education': _education,
        'internships': _internshipsApi(m),
        'projects': _projectsApi(m),
        'work_experience': m.workExperience.map((e) => e.toJson()).toList(),
        'languages_known': _languagesApi(m),
        'certifications_structured': _certsApi(m),
        'resume_document': env,
        'portfolio_url': _portfolio.text.trim().isEmpty ? null : _portfolio.text.trim(),
        'dob': _dob.text.trim().isEmpty ? null : _dob.text.trim(),
        'gender': _gender,
        'industry_type': _industryType,
        'experience_years': int.tryParse(_expYears.text.trim()),
        'expected_salary_min': int.tryParse(_minSal.text.trim()),
        'expected_salary_max': int.tryParse(_maxSal.text.trim()),
        'currency': 'INR',
        'achievements': _achievementsPayload().isEmpty ? null : _achievementsPayload(),
        'academic_achievements': academicPayload.isEmpty ? null : academicPayload,
        'awards_honors': awardsPayload.isEmpty ? null : awardsPayload,
        'competitive_exam_results': examsPayload.isEmpty ? null : examsPayload,
        'phone': _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      };
      if (_profilePhotoBase64 != null) {
        body['profile_photo'] = _profilePhotoBase64;
      }
      body.removeWhere((k, v) => v == null);

      final data = await JobSeekerApiService.instance.updateSeekerProfile(body);
      _mergeProfileResponseIntoSession(data);
      final newUrl = data['profile_photo_url']?.toString().trim();
      if (newUrl != null && newUrl.isNotEmpty) {
        _profilePhotoUrl = MediaUrl.resolve(newUrl) ?? newUrl;
        _pickedProfilePhoto = null;
        _profilePhotoBase64 = null;
        _model = m.copyWith(
          profileImageUrl: _profilePhotoUrl,
          clearProfileImageBase64: true,
        );
      }

      final title = m.draftTitle.trim().isNotEmpty
          ? m.draftTitle.trim()
          : '${m.fullName.trim().isNotEmpty ? m.fullName : 'My'} résumé';
      await JobSeekerApiService.instance.saveResumeDraft(
        title: title,
        templateId: widget.templateIdForSave,
        contentEnvelope: resumeModelToApiEnvelope(_compose()),
        resumeDraftId: widget.resumeDraftId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile & resume saved'), backgroundColor: AppColors.success),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openPreview() {
    final m = _compose();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResumeHtmlPreviewScreen(
          templateKey: seekerHtmlTemplateKeyForStudioTemplateId(widget.templateIdForSave),
          contentEnvelope: resumeModelToApiEnvelope(m),
          resumeDraftId: widget.resumeDraftId,
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo too large (max ~2MB).'), backgroundColor: AppColors.error),
        );
        return;
      }
      setState(() {
        _pickedProfilePhoto = picked;
        _profilePhotoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (src != null) await _pickProfilePhoto(src);
  }

  void _addAchievement() {
    setState(() => _achievementCtrls.add(TextEditingController()));
  }

  void _removeAchievement(int i) {
    setState(() {
      _achievementCtrls.removeAt(i).dispose();
    });
  }

  void _addAcademic() => setState(() => _academicCtrls.add(TextEditingController()));

  void _removeAcademic(int i) {
    setState(() {
      _academicCtrls.removeAt(i).dispose();
    });
  }

  void _addAward() => setState(() => _awardsCtrls.add(TextEditingController()));

  void _removeAward(int i) {
    setState(() {
      _awardsCtrls.removeAt(i).dispose();
    });
  }

  void _addExam() => setState(() => _examCtrls.add(TextEditingController()));

  void _removeExam(int i) {
    setState(() {
      _examCtrls.removeAt(i).dispose();
    });
  }

  Future<void> _editEducationRow(int? index) async {
    final isNew = index == null;
    final editIndex = index;
    final row = isNew
        ? <String, dynamic>{
            'title': '',
            'institution': '',
            'year_completed': '',
            'marks_or_grade': '',
            'study_mode': '',
            'board_or_stream': '',
          }
        : Map<String, dynamic>.from(_education[editIndex as int]);
    final tCtrl = TextEditingController(text: row['title']?.toString() ?? '');
    final iCtrl = TextEditingController(text: row['institution']?.toString() ?? '');
    final yCtrl = TextEditingController(text: row['year_completed']?.toString() ?? '');
    final mCtrl = TextEditingController(text: row['marks_or_grade']?.toString() ?? '');
    final modeCtrl = TextEditingController(text: row['study_mode']?.toString() ?? '');
    final boardCtrl = TextEditingController(text: row['board_or_stream']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Add education' : 'Edit education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'Course / title')),
              TextField(controller: iCtrl, decoration: const InputDecoration(labelText: 'Institution')),
              TextField(controller: yCtrl, decoration: const InputDecoration(labelText: 'Year')),
              TextField(controller: mCtrl, decoration: const InputDecoration(labelText: 'Score / %')),
              TextField(controller: boardCtrl, decoration: const InputDecoration(labelText: 'Board / stream (optional)')),
              TextField(controller: modeCtrl, decoration: const InputDecoration(labelText: 'Study mode (e.g. Full time)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    final next = {
      'title': tCtrl.text.trim(),
      'institution': iCtrl.text.trim(),
      'year_completed': yCtrl.text.trim(),
      'marks_or_grade': mCtrl.text.trim(),
      'study_mode': modeCtrl.text.trim(),
      'board_or_stream': boardCtrl.text.trim(),
    };
    tCtrl.dispose();
    iCtrl.dispose();
    yCtrl.dispose();
    mCtrl.dispose();
    modeCtrl.dispose();
    boardCtrl.dispose();
    if (ok != true || !mounted) return;
    setState(() {
      if (isNew) {
        _education.add(next);
      } else {
        _education[editIndex as int] = next;
      }
    });
  }

  Future<ExperienceItem?> _editExperienceDialog(ExperienceItem initial, String title) async {
    final co = TextEditingController(text: initial.companyName);
    final dr = TextEditingController(text: initial.dateRange);
    final bu = TextEditingController(text: initial.bullets.join('\n'));
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: co, decoration: const InputDecoration(labelText: 'Title / company / organization')),
              TextField(controller: dr, decoration: const InputDecoration(labelText: 'Dates or link')),
              TextField(controller: bu, maxLines: 6, decoration: const InputDecoration(labelText: 'Description / bullets (one per line)', alignLabelWithHint: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    final out = ExperienceItem(
      id: initial.id,
      companyName: co.text.trim(),
      dateRange: dr.text.trim(),
      bullets: bu.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );
    co.dispose();
    dr.dispose();
    bu.dispose();
    if (r != true) return null;
    return out;
  }

  Future<void> _editWork(int? index) async {
    final isNew = index == null;
    final ExperienceItem cur;
    if (isNew) {
      cur = ExperienceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: '',
        dateRange: '',
        bullets: [],
      );
    } else {
      cur = _model.workExperience[index];
    }
    final next = await _editExperienceDialog(cur, isNew ? 'Add work experience' : 'Edit work experience');
    if (next == null) return;
    setState(() {
      final list = List<ExperienceItem>.from(_model.workExperience);
      if (isNew) {
        list.add(next);
      } else {
        list[index] = next;
      }
      _model = _model.copyWith(workExperience: list);
    });
  }

  Future<void> _editIntern(int? index) async {
    final isNew = index == null;
    final ExperienceItem cur;
    if (isNew) {
      cur = ExperienceItem(
        id: 'int_${DateTime.now().millisecondsSinceEpoch}',
        companyName: '',
        dateRange: '',
        bullets: [],
      );
    } else {
      cur = _model.internships[index];
    }
    final next = await _editExperienceDialog(cur, isNew ? 'Add internship' : 'Edit internship');
    if (next == null) return;
    setState(() {
      final list = List<ExperienceItem>.from(_model.internships);
      if (isNew) {
        list.add(next);
      } else {
        list[index] = next;
      }
      _model = _model.copyWith(internships: list);
    });
  }

  Future<void> _editProject(int? index) async {
    final isNew = index == null;
    final ExperienceItem cur;
    if (isNew) {
      cur = ExperienceItem(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        companyName: '',
        dateRange: '',
        bullets: [],
      );
    } else {
      cur = _model.projects[index];
    }
    final next = await _editExperienceDialog(cur, isNew ? 'Add project' : 'Edit project');
    if (next == null) return;
    setState(() {
      final list = List<ExperienceItem>.from(_model.projects);
      if (isNew) {
        list.add(next);
      } else {
        list[index] = next;
      }
      _model = _model.copyWith(projects: list);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _city.dispose();
    _country.dispose();
    _hometown.dispose();
    _highestQual.dispose();
    _headline.dispose();
    _summary.dispose();
    _skills.dispose();
    _langs.dispose();
    _certs.dispose();
    _dob.dispose();
    _portfolio.dispose();
    _expYears.dispose();
    _minSal.dispose();
    _maxSal.dispose();
    _disposeAchievementCtrls();
    _disposeStructuredExtraCtrls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = _strengthPercent(_compose());
    final strengthLabel = strength >= 70 ? 'High' : (strength >= 40 ? 'Medium' : 'Low');

    ImageProvider? photoProvider;
    if (_pickedProfilePhoto != null) {
      photoProvider = FileImage(File(_pickedProfilePhoto!.path));
    } else if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      photoProvider = NetworkImage(_profilePhotoUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit resume'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _openPreview,
            child: const Text('View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        const Text('Resume strength', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text(
                          strengthLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: strength >= 70 ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: _openPreview,
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Preview'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Profile photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'Optional. Shown on your profile and résumé templates that support a photo. Saved with your profile.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: photoProvider,
                          child: photoProvider == null ? Icon(Icons.person, size: 44, color: Colors.grey.shade600) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _showPhotoSourceSheet,
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: Text(_pickedProfilePhoto != null ? 'Change photo' : 'Add / change photo'),
                              ),
                              if (_pickedProfilePhoto != null || _profilePhotoBase64 != null)
                                TextButton(
                                  onPressed: () => setState(() {
                                    _pickedProfilePhoto = null;
                                    _profilePhotoBase64 = null;
                                  }),
                                  child: const Text('Discard new photo'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Personal & contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
                    const SizedBox(height: 8),
                    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(controller: _mobile, decoration: const InputDecoration(labelText: 'Mobile')),
                    const SizedBox(height: 8),
                    TextField(controller: _city, decoration: const InputDecoration(labelText: 'City / current location')),
                    const SizedBox(height: 8),
                    TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dob,
                      decoration: const InputDecoration(labelText: 'Date of birth', hintText: 'YYYY-MM-DD'),
                    ),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _gender,
                          hint: const Text('Select'),
                          items: _genderDropdownItems
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: _hometown, decoration: const InputDecoration(labelText: 'Home town')),
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Currently residing in India'),
                      value: _residingIndia,
                      onChanged: (v) => setState(() => _residingIndia = v ?? true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _highestQual,
                      decoration: const InputDecoration(labelText: 'Highest qualification (e.g. Graduate)'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Job preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    IndustryTypeDropdown(
                      value: _industryType,
                      labelText: 'Industry / role type',
                      onChanged: (v) => setState(() => _industryType = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _expYears,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Years of experience'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minSal,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Expected salary min (INR)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxSal,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Expected salary max (INR)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portfolio,
                      decoration: const InputDecoration(labelText: 'Portfolio or LinkedIn URL'),
                    ),
                    const SizedBox(height: 20),
                    const Text('Professional headline', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _headline, decoration: const InputDecoration(hintText: 'e.g. Fullstack Developer')),
                    const SizedBox(height: 20),
                    const Text('Resume summary', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _summary, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    const Text('Skills (comma separated)', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _skills, maxLines: 2),
                    const SizedBox(height: 16),
                    const Text('Languages (one per line: English — Fluent)', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _langs, maxLines: 4),
                    const SizedBox(height: 16),
                    const Text('Certifications (one per line: Name — Feb 2025)', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(controller: _certs, maxLines: 4),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextButton.icon(
                          onPressed: _addAchievement,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    Text(
                      'One achievement per line (saved to your profile).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    ..._achievementCtrls.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: TextField(controller: c, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
                            IconButton(onPressed: () => _removeAchievement(i), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Academic highlights', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextButton.icon(onPressed: _addAcademic, icon: const Icon(Icons.add), label: const Text('Add')),
                      ],
                    ),
                    Text(
                      'Optional. Use “Title — detail” on one line if you need both.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    ..._academicCtrls.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            IconButton(onPressed: () => _removeAcademic(i), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Awards & honors', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextButton.icon(onPressed: _addAward, icon: const Icon(Icons.add), label: const Text('Add')),
                      ],
                    ),
                    Text(
                      'Optional. Same “Title — detail” format as above.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    ..._awardsCtrls.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            IconButton(onPressed: () => _removeAward(i), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Competitive exams', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextButton.icon(onPressed: _addExam, icon: const Icon(Icons.add), label: const Text('Add')),
                      ],
                    ),
                    Text(
                      'Optional. Use “Exam name — score or rank” on one line.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    ..._examCtrls.asMap().entries.map((e) {
                      final i = e.key;
                      final c = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: c,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              ),
                            ),
                            IconButton(onPressed: () => _removeExam(i), icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Education', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextButton.icon(
                          onPressed: () => _editEducationRow(null),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    ..._education.asMap().entries.map((e) {
                      final i = e.key;
                      final row = e.value;
                      final title = row['title']?.toString() ?? '';
                      final inst = row['institution']?.toString() ?? '';
                      final sub = [row['year_completed'], row['marks_or_grade']].where((x) => '${x ?? ''}'.trim().isNotEmpty).join(', ');
                      return Card(
                        child: ListTile(
                          title: Text(title.isEmpty ? '(No title)' : title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('$inst${sub.isEmpty ? '' : ' · $sub'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editEducationRow(i)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(() => _education.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    _expSection(
                      title: 'Work experience',
                      items: _model.workExperience,
                      onAdd: () => _editWork(null),
                      onEdit: (i) => _editWork(i),
                      onDelete: (i) => setState(() {
                        final l = List<ExperienceItem>.from(_model.workExperience)..removeAt(i);
                        _model = _model.copyWith(workExperience: l);
                      }),
                    ),
                    _expSection(
                      title: 'Internships',
                      items: _model.internships,
                      onAdd: () => _editIntern(null),
                      onEdit: (i) => _editIntern(i),
                      onDelete: (i) => setState(() {
                        final l = List<ExperienceItem>.from(_model.internships)..removeAt(i);
                        _model = _model.copyWith(internships: l);
                      }),
                    ),
                    _expSection(
                      title: 'Projects',
                      items: _model.projects,
                      onAdd: () => _editProject(null),
                      onEdit: (i) => _editProject(i),
                      onDelete: (i) => setState(() {
                        final l = List<ExperienceItem>.from(_model.projects)..removeAt(i);
                        _model = _model.copyWith(projects: l);
                      }),
                    ),
                  ],
                ),
    );
  }

  Widget _expSection({
    required String title,
    required List<ExperienceItem> items,
    required VoidCallback onAdd,
    required void Function(int index) onEdit,
    required void Function(int index) onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add')),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('None yet — tap Add.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final it = e.value;
          final line = it.companyName.isEmpty ? '(No title)' : it.companyName;
          final sub = [it.dateRange, if (it.bullets.isNotEmpty) it.bullets.first].where((s) => s.trim().isNotEmpty).join(' · ');
          return Card(
            child: ListTile(
              title: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => onEdit(i)),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onDelete(i)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
