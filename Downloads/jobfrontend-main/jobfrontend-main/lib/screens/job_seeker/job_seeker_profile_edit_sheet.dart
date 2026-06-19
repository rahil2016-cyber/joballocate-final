import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';
import '../../utils/media_url.dart';
import '../../widgets/industry_type_dropdown.dart';
import '../../constants/industry_types.dart';

class _EduRow {
  _EduRow({
    String title = '',
    String institution = '',
    String board = '',
    String marks = '',
    String year = '',
  }) : title = TextEditingController(text: title),
       institution = TextEditingController(text: institution),
       boardOrStream = TextEditingController(text: board),
       marksOrGrade = TextEditingController(text: marks),
       yearCompleted = TextEditingController(text: year);

  final TextEditingController title;
  final TextEditingController institution;
  final TextEditingController boardOrStream;
  final TextEditingController marksOrGrade;
  final TextEditingController yearCompleted;

  void dispose() {
    title.dispose();
    institution.dispose();
    boardOrStream.dispose();
    marksOrGrade.dispose();
    yearCompleted.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.text.trim(),
      'institution': institution.text.trim(),
      'board_or_stream': boardOrStream.text.trim(),
      'marks_or_grade': marksOrGrade.text.trim(),
      'year_completed': yearCompleted.text.trim(),
    };
  }
}

class _InternshipRow {
  _InternshipRow({
    String org = '',
    String role = '',
    String dur = '',
    String desc = '',
  }) : organization = TextEditingController(text: org),
       role = TextEditingController(text: role),
       duration = TextEditingController(text: dur),
       description = TextEditingController(text: desc);

  final TextEditingController organization;
  final TextEditingController role;
  final TextEditingController duration;
  final TextEditingController description;

  void dispose() {
    organization.dispose();
    role.dispose();
    duration.dispose();
    description.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'organization': organization.text.trim(),
      'role': role.text.trim(),
      'duration': duration.text.trim(),
      'description': description.text.trim(),
    };
  }
}

class _ProjectRow {
  _ProjectRow({
    String name = '',
    String link = '',
    String desc = '',
  }) : title = TextEditingController(text: name),
       link = TextEditingController(text: link),
       description = TextEditingController(text: desc);

  final TextEditingController title;
  final TextEditingController link;
  final TextEditingController description;

  void dispose() {
    title.dispose();
    link.dispose();
    description.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.text.trim(),
      'link': link.text.trim(),
      'description': description.text.trim(),
    };
  }
}

class _AchievementRow {
  _AchievementRow({String val = ''}) : controller = TextEditingController(text: val);
  final TextEditingController controller;
  void dispose() => controller.dispose();
  String toJson() => controller.text.trim();
}

class _WorkExpRow {
  _WorkExpRow({
    String company = '',
    String dateRange = '',
    List<String> bullets = const [],
  })  : companyName = TextEditingController(text: company),
        dateRange = TextEditingController(text: dateRange),
        bulletsCtrl = TextEditingController(text: bullets.join('\n'));

  final TextEditingController companyName;
  final TextEditingController dateRange;
  final TextEditingController bulletsCtrl;

  void dispose() {
    companyName.dispose();
    dateRange.dispose();
    bulletsCtrl.dispose();
  }

  Map<String, dynamic> toJson() {
    final lines = bulletsCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return {
      'company_name': companyName.text.trim(),
      'date_range': dateRange.text.trim(),
      'bullets': lines,
    };
  }
}

class _LanguageRow {
  _LanguageRow({String lang = '', String prof = ''})
      : language = TextEditingController(text: lang),
        proficiency = TextEditingController(text: prof);

  final TextEditingController language;
  final TextEditingController proficiency;

  void dispose() {
    language.dispose();
    proficiency.dispose();
  }

  Map<String, dynamic> toJson() => {
        'language': language.text.trim(),
        'proficiency': proficiency.text.trim(),
      };
}

class _CertificationRow {
  _CertificationRow({String name = '', String date = ''})
      : name = TextEditingController(text: name),
        date = TextEditingController(text: date);

  final TextEditingController name;
  final TextEditingController date;

  void dispose() {
    name.dispose();
    date.dispose();
  }

  Map<String, dynamic> toJson() => {
        'name': name.text.trim(),
        'date': date.text.trim(),
      };
}

class _AcademicAchievementRow {
  _AcademicAchievementRow({String title = '', String detail = ''})
      : title = TextEditingController(text: title),
        detail = TextEditingController(text: detail);

  final TextEditingController title;
  final TextEditingController detail;

  void dispose() {
    title.dispose();
    detail.dispose();
  }

  Map<String, dynamic> toJson() => {
        'title': title.text.trim(),
        'detail': detail.text.trim(),
      };
}

class _AwardsRow {
  _AwardsRow({String title = '', String detail = ''})
      : title = TextEditingController(text: title),
        detail = TextEditingController(text: detail);

  final TextEditingController title;
  final TextEditingController detail;

  void dispose() {
    title.dispose();
    detail.dispose();
  }

  Map<String, dynamic> toJson() => {
        'title': title.text.trim(),
        'detail': detail.text.trim(),
      };
}

class _ExamResultRow {
  _ExamResultRow({String exam = '', String result = ''})
      : exam = TextEditingController(text: exam),
        result = TextEditingController(text: result);

  final TextEditingController exam;
  final TextEditingController result;

  void dispose() {
    exam.dispose();
    result.dispose();
  }

  Map<String, dynamic> toJson() => {
        'exam': exam.text.trim(),
        'result': result.text.trim(),
      };
}

/// Scrollable edit form for job seeker profile (education + industry type).
class JobSeekerProfileEditSheet extends StatefulWidget {
  const JobSeekerProfileEditSheet({
    super.key,
    required this.initial,
    required this.onSaved,
  });

  final Map<String, dynamic> initial;
  final VoidCallback onSaved;

  @override
  State<JobSeekerProfileEditSheet> createState() =>
      _JobSeekerProfileEditSheetState();
}

class _JobSeekerProfileEditSheetState extends State<JobSeekerProfileEditSheet> {
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _minSalCtrl;
  late final TextEditingController _maxSalCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _portfolioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _customIndustryCtrl;
  String? _gender;

  String? _industryType;
  final List<_EduRow> _education = [];
  final List<_InternshipRow> _internships = [];
  final List<_ProjectRow> _projects = [];
  final List<_AchievementRow> _achievements = [];
  final List<_WorkExpRow> _workExperience = [];
  final List<_LanguageRow> _languages = [];
  final List<_CertificationRow> _certifications = [];
  final List<_AcademicAchievementRow> _academicAchievements = [];
  final List<_AwardsRow> _awards = [];
  final List<_ExamResultRow> _examResults = [];
  bool _saving = false;
  bool _uploadingResume = false;
  String? _resumeUrl;

  static const int _maxPhotoBytes = 2 * 1024 * 1024; // ~2MB
  final ImagePicker _imagePicker = ImagePicker();
  String? _profilePhotoUrl;
  XFile? _pickedProfilePhoto;
  String? _profilePhotoBase64;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _headlineCtrl = TextEditingController(
      text: p['headline']?.toString() ?? '',
    );
    _bioCtrl = TextEditingController(text: p['bio']?.toString() ?? '');
    _cityCtrl = TextEditingController(text: p['city']?.toString() ?? '');
    _countryCtrl = TextEditingController(text: p['country']?.toString() ?? '');
    _expCtrl = TextEditingController(
      text: p['experience_years']?.toString() ?? '',
    );
    _minSalCtrl = TextEditingController(
      text: p['expected_salary_min']?.toString() ?? '',
    );
    _maxSalCtrl = TextEditingController(
      text: p['expected_salary_max']?.toString() ?? '',
    );
    _skillsCtrl = TextEditingController(
      text: p['skills'] is List
          ? (p['skills'] as List).map((e) => e.toString()).join(', ')
          : '',
    );
    _portfolioCtrl = TextEditingController(text: p['portfolio_url']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p['phone']?.toString() ?? '');
    _emailCtrl = TextEditingController(text: p['email']?.toString() ?? '');
    _dobCtrl = TextEditingController(text: p['dob']?.toString() ?? '');
    _gender = p['gender']?.toString();
    if (_gender != null && _gender!.isEmpty) _gender = null;

    final ind = p['industry_type']?.toString() ?? '';
    final exists = kIndustryTypes.any((e) => e.key == ind);
    if (exists) {
      _industryType = ind;
      _customIndustryCtrl = TextEditingController();
    } else if (ind.isNotEmpty) {
      _industryType = 'none_of_above';
      _customIndustryCtrl = TextEditingController(text: ind);
    } else {
      _industryType = null;
      _customIndustryCtrl = TextEditingController();
    }

    final edu = p['education'];
    if (edu is List) {
      for (final e in edu) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          _education.add(
            _EduRow(
              title: m['title']?.toString() ?? '',
              institution: m['institution']?.toString() ?? '',
              board: m['board_or_stream']?.toString() ?? '',
              marks: m['marks_or_grade']?.toString() ?? '',
              year: m['year_completed']?.toString() ?? '',
            ),
          );
        }
      }
    }
    if (_education.isEmpty) {
      _education.add(_EduRow());
    }

    final ints = p['internships'];
    if (ints is List) {
      for (final i in ints) {
        if (i is Map) {
          final m = Map<String, dynamic>.from(i);
          _internships.add(
            _InternshipRow(
              org: m['organization']?.toString() ?? '',
              role: m['role']?.toString() ?? '',
              dur: m['duration']?.toString() ?? '',
              desc: m['description']?.toString() ?? '',
            ),
          );
        }
      }
    }

    final projs = p['projects'];
    if (projs is List) {
      for (final pr in projs) {
        if (pr is Map) {
          final m = Map<String, dynamic>.from(pr);
          _projects.add(
            _ProjectRow(
              name: m['title']?.toString() ?? m['name']?.toString() ?? '',
              link: m['link']?.toString() ?? '',
              desc: m['description']?.toString() ?? '',
            ),
          );
        }
      }
    }

    // Work experience
    final wexp = p['work_experience'];
    if (wexp is List) {
      for (final w in wexp) {
        if (w is Map) {
          final m = Map<String, dynamic>.from(w);
          final rawBullets = m['bullets'];
          final bullets = <String>[];
          if (rawBullets is List) {
            for (final b in rawBullets) {
              final s = b?.toString().trim() ?? '';
              if (s.isNotEmpty) bullets.add(s);
            }
          }
          _workExperience.add(_WorkExpRow(
            company: m['company_name']?.toString() ?? '',
            dateRange: m['date_range']?.toString() ?? '',
            bullets: bullets,
          ));
        }
      }
    }

    // Languages known
    final langs = p['languages_known'];
    if (langs is List) {
      for (final l in langs) {
        if (l is Map) {
          final m = Map<String, dynamic>.from(l);
          _languages.add(_LanguageRow(
            lang: m['language']?.toString() ?? '',
            prof: m['proficiency']?.toString() ?? '',
          ));
        }
      }
    }

    // Certifications
    final certs = p['certifications_structured'];
    if (certs is List) {
      for (final c in certs) {
        if (c is Map) {
          final m = Map<String, dynamic>.from(c);
          _certifications.add(_CertificationRow(
            name: m['name']?.toString() ?? '',
            date: m['date']?.toString() ?? '',
          ));
        }
      }
    }

    // Academic achievements
    final acads = p['academic_achievements'];
    if (acads is List) {
      for (final a in acads) {
        if (a is Map) {
          final m = Map<String, dynamic>.from(a);
          _academicAchievements.add(_AcademicAchievementRow(
            title: m['title']?.toString() ?? '',
            detail: m['detail']?.toString() ?? '',
          ));
        }
      }
    }

    // Awards & honors
    final awds = p['awards_honors'];
    if (awds is List) {
      for (final a in awds) {
        if (a is Map) {
          final m = Map<String, dynamic>.from(a);
          _awards.add(_AwardsRow(
            title: m['title']?.toString() ?? '',
            detail: m['detail']?.toString() ?? '',
          ));
        }
      }
    }

    // Competitive exam results
    final exams = p['competitive_exam_results'];
    if (exams is List) {
      for (final e in exams) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          _examResults.add(_ExamResultRow(
            exam: m['exam']?.toString() ?? '',
            result: m['result']?.toString() ?? '',
          ));
        }
      }
    }

    final r = p['resume_url']?.toString();
    _resumeUrl = (r != null && r.trim().isNotEmpty) ? r.trim() : null;

    final rawPhoto = p['profile_photo_url']?.toString() ??
        p['profile_photo']?.toString();
    final trimmed = rawPhoto?.trim() ?? '';
    _profilePhotoUrl = trimmed.isNotEmpty ? trimmed : null;
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _customIndustryCtrl.dispose();
    _countryCtrl.dispose();
    _expCtrl.dispose();
    _minSalCtrl.dispose();
    _maxSalCtrl.dispose();
    _skillsCtrl.dispose();
    _portfolioCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    for (final r in _education) {
      r.dispose();
    }
    for (final r in _internships) {
      r.dispose();
    }
    for (final r in _projects) {
      r.dispose();
    }
    for (final r in _achievements) {
      r.dispose();
    }
    for (final r in _workExperience) {
      r.dispose();
    }
    for (final r in _languages) {
      r.dispose();
    }
    for (final r in _certifications) {
      r.dispose();
    }
    for (final r in _academicAchievements) {
      r.dispose();
    }
    for (final r in _awards) {
      r.dispose();
    }
    for (final r in _examResults) {
      r.dispose();
    }
    super.dispose();
  }

  void _addAchievement() => setState(() => _achievements.add(_AchievementRow()));
  void _removeAchievement(int i) {
    setState(() {
      final r = _achievements.removeAt(i);
      r.dispose();
    });
  }

  void _addInternship() => setState(() => _internships.add(_InternshipRow()));
  void _removeInternship(int i) {
    setState(() {
      final r = _internships.removeAt(i);
      r.dispose();
    });
  }

  void _addProject() => setState(() => _projects.add(_ProjectRow()));
  void _removeProject(int i) {
    setState(() {
      final r = _projects.removeAt(i);
      r.dispose();
    });
  }

  void _addEducation() {
    setState(() => _education.add(_EduRow()));
  }

  void _removeEducation(int i) {
    if (_education.length <= 1) return;
    setState(() {
      final r = _education.removeAt(i);
      r.dispose();
    });
  }

  void _addWorkExp() => setState(() => _workExperience.add(_WorkExpRow()));
  void _removeWorkExp(int i) {
    setState(() {
      final r = _workExperience.removeAt(i);
      r.dispose();
    });
  }

  void _addLanguage() => setState(() => _languages.add(_LanguageRow()));
  void _removeLanguage(int i) {
    setState(() {
      final r = _languages.removeAt(i);
      r.dispose();
    });
  }

  void _addCertification() => setState(() => _certifications.add(_CertificationRow()));
  void _removeCertification(int i) {
    setState(() {
      final r = _certifications.removeAt(i);
      r.dispose();
    });
  }

  void _addAcademicAchievement() => setState(() => _academicAchievements.add(_AcademicAchievementRow()));
  void _removeAcademicAchievement(int i) {
    setState(() {
      final r = _academicAchievements.removeAt(i);
      r.dispose();
    });
  }

  void _addAward() => setState(() => _awards.add(_AwardsRow()));
  void _removeAward(int i) {
    setState(() {
      final r = _awards.removeAt(i);
      r.dispose();
    });
  }

  void _addExamResult() => setState(() => _examResults.add(_ExamResultRow()));
  void _removeExamResult(int i) {
    setState(() {
      final r = _examResults.removeAt(i);
      r.dispose();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_industryType == 'none_of_above' && _customIndustryCtrl.text.trim().isEmpty) {
        throw Exception('Please enter a custom industry name');
      }

      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final eduPayload = _education
          .map((r) => r.toJson())
          .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
          .toList();

      String? portfolioUrl = _portfolioCtrl.text.trim();
      if (portfolioUrl.isNotEmpty) {
        if (!portfolioUrl.startsWith('http://') && !portfolioUrl.startsWith('https://')) {
          portfolioUrl = 'https://$portfolioUrl';
        }
      } else {
        portfolioUrl = null;
      }

      final body = <String, dynamic>{
        'headline': _headlineCtrl.text.trim().isEmpty
            ? null
            : _headlineCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim().isEmpty
            ? null
            : _countryCtrl.text.trim(),
        'experience_years': _expCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_expCtrl.text.trim()),
        'expected_salary_min': _minSalCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_minSalCtrl.text.trim()),
        'expected_salary_max': _maxSalCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_maxSalCtrl.text.trim()),
        'currency': 'INR',
        'skills': skills.isEmpty ? null : skills,
        'industry_type': _industryType == 'none_of_above' ? _customIndustryCtrl.text.trim() : _industryType,
        'education': eduPayload.isEmpty ? null : eduPayload,
        'internships': _internships
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'projects': _projects
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'achievements': _achievements
            .map((r) => r.toJson())
            .where((v) => v.isNotEmpty)
            .toList(),
        'work_experience': _workExperience
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) {
              if (v is String) return v.trim().isNotEmpty;
              if (v is List) return v.isNotEmpty;
              return false;
            }))
            .toList(),
        'languages_known': _languages
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'certifications_structured': _certifications
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'academic_achievements': _academicAchievements
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'awards_honors': _awards
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'competitive_exam_results': _examResults
            .map((r) => r.toJson())
            .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
            .toList(),
        'portfolio_url': portfolioUrl,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'dob': _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        'gender': _gender,
      };
      if (_profilePhotoBase64 != null) {
        body['profile_photo'] = _profilePhotoBase64;
      }

      await JobSeekerApiService.instance.updateSeekerProfile(body);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadResume() async {
    setState(() => _uploadingResume = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        throw Exception('Could not read selected file');
      }

      final data = await JobSeekerApiService.instance.uploadResumePdf(
        File(path),
      );
      final url = data['resume_url']?.toString();
      if (url != null && url.trim().isNotEmpty) {
        setState(() => _resumeUrl = url.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resume uploaded'),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh parent profile so uploaded resume shows immediately.
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo too large (max ~2MB). Please select a smaller one.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _pickedProfilePhoto = picked;
        _profilePhotoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildProfilePhotoCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarSize =
            (constraints.maxWidth * 0.22).clamp(72.0, 120.0).toDouble();

        ImageProvider? provider;
        if (_pickedProfilePhoto != null) {
          provider = FileImage(File(_pickedProfilePhoto!.path));
        } else {
          final resolved = MediaUrl.resolve(_profilePhotoUrl);
          if (resolved != null) {
            provider = NetworkImage(resolved);
          }
        }

        final hasExisting = provider != null;
        final label =
            _pickedProfilePhoto != null ? 'Replace' : (hasExisting ? 'Replace' : 'Upload');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: Colors.white,
                    backgroundImage: provider,
                    child: provider == null
                        ? Icon(Icons.person_rounded,
                            size: avatarSize * 0.48, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profile photo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This photo will appear on your profile for employers.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(label),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: maxH,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    'Edit profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfilePhotoCard(),
                  const SizedBox(height: 20),

                  // BASIC INFO
                  const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dobCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'Select Date of Birth',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: () async {
                      DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
                      if (_dobCtrl.text.isNotEmpty) {
                        final parsed = DateTime.tryParse(_dobCtrl.text.trim());
                        if (parsed != null) {
                          initialDate = parsed;
                        }
                      }
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                        setState(() {
                          _dobCtrl.text = formattedDate;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['Male', 'Female', 'Prefer not to say']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Resume (PDF)',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: (_saving || _uploadingResume)
                                  ? null
                                  : _pickAndUploadResume,
                              child: Text(
                                _resumeUrl == null ? 'Upload' : 'Replace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _resumeUrl == null
                              ? 'Upload your PDF resume so employers can open it.'
                              : 'Resume uploaded and visible to employers.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (_uploadingResume) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(minHeight: 6),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  IndustryTypeDropdown(
                    value: _industryType,
                    labelText: 'Industry / role type',
                    onChanged: (v) => setState(() => _industryType = v),
                  ),
                  if (_industryType == 'none_of_above') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customIndustryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Write Custom Industry Name *',
                        hintText: 'e.g. Space Exploration, Robotics',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _headlineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Headline',
                      hintText: 'e.g. Senior Flutter Developer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portfolioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Portfolio / Website Link',
                      hintText: 'e.g. https://myportfolio.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Education',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add Class 10, 12, diploma, degree — title, school/college, board, marks, year.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_education.length, (i) {
                    final r = _education[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Entry ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                if (_education.length > 1)
                                  IconButton(
                                    onPressed: () => _removeEducation(i),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.title,
                              decoration: const InputDecoration(
                                labelText: 'Title (e.g. Class 12, B.Tech)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.institution,
                              decoration: const InputDecoration(
                                labelText: 'School / college name',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.boardOrStream,
                              decoration: const InputDecoration(
                                labelText: 'Board / stream (optional)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: r.marksOrGrade,
                                    decoration: const InputDecoration(
                                      labelText: 'Marks / CGPA',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: r.yearCompleted,
                                    decoration: const InputDecoration(
                                      labelText: 'Year',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // WORK EXPERIENCE
                  Row(
                    children: [
                      Text(
                        'Work Experience',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addWorkExp,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add your work experience — company, dates and what you did.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_workExperience.length, (i) {
                    final r = _workExperience[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Experience ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeWorkExp(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.companyName,
                              decoration: const InputDecoration(
                                labelText: 'Company Name',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.dateRange,
                              decoration: const InputDecoration(
                                labelText: 'Date Range (e.g. Jan 2023 – Dec 2024)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.bulletsCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Key responsibilities (one per line)',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // INTERNSHIPS
                  Row(
                    children: [
                      Text(
                        'Internships',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addInternship,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add your internship experience — role, organization, duration and description.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_internships.length, (i) {
                    final r = _internships[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Internship ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeInternship(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.role,
                              decoration: const InputDecoration(
                                labelText: 'Role (e.g. Flutter Intern)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.organization,
                              decoration: const InputDecoration(
                                labelText: 'Organization / Company',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.duration,
                              decoration: const InputDecoration(
                                labelText: 'Duration (e.g. 3 months)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.description,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // PROJECTS
                  Row(
                    children: [
                      Text(
                        'Projects',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addProject,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add your personal or professional projects — name, link and what you built.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_projects.length, (i) {
                    final r = _projects[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Project ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeProject(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.title,
                              decoration: const InputDecoration(
                                labelText: 'Project Name',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.link,
                              decoration: const InputDecoration(
                                labelText: 'Project Link (optional)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.description,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // ACHIEVEMENTS
                  Row(
                    children: [
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addAchievement,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add your awards, certifications and professional recognition.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_achievements.length, (i) {
                    final r = _achievements[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: r.controller,
                                decoration: const InputDecoration(
                                  labelText: 'Achievement',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeAchievement(i),
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // CERTIFICATIONS
                  Row(
                    children: [
                      Text(
                        'Certifications',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addCertification,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add professional certifications — name and date obtained.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_certifications.length, (i) {
                    final r = _certifications[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Certification ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeCertification(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.name,
                              decoration: const InputDecoration(
                                labelText: 'Certification Name',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.date,
                              decoration: const InputDecoration(
                                labelText: 'Date (e.g. March 2024)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // LANGUAGES KNOWN
                  Row(
                    children: [
                      Text(
                        'Languages Known',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addLanguage,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'List languages you speak and your proficiency level.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_languages.length, (i) {
                    final r = _languages[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: r.language,
                                decoration: const InputDecoration(
                                  labelText: 'Language',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: r.proficiency,
                                decoration: const InputDecoration(
                                  labelText: 'Proficiency',
                                  hintText: 'e.g. Native, Fluent',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeLanguage(i),
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // ACADEMIC ACHIEVEMENTS
                  Row(
                    children: [
                      Text(
                        'Academic Achievements',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addAcademicAchievement,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Academic honors, scholarships, dean\'s list, etc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_academicAchievements.length, (i) {
                    final r = _academicAchievements[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Achievement ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeAcademicAchievement(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.title,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.detail,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Details',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // AWARDS & HONORS
                  Row(
                    children: [
                      Text(
                        'Awards \u0026 Honors',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addAward,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Professional awards, recognition, and honors received.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_awards.length, (i) {
                    final r = _awards[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text('Award ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeAward(i),
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.title,
                              decoration: const InputDecoration(
                                labelText: 'Award Title',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: r.detail,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Details',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // COMPETITIVE EXAM RESULTS
                  Row(
                    children: [
                      Text(
                        'Competitive Exam Results',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addExamResult,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'GATE, GRE, CAT, JEE, NEET or other competitive exam scores.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_examResults.length, (i) {
                    final r = _examResults[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: r.exam,
                                decoration: const InputDecoration(
                                  labelText: 'Exam Name',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: r.result,
                                decoration: const InputDecoration(
                                  labelText: 'Score / Rank',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeExamResult(i),
                              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location_rounded,
                                  color: AppColors.primary),
                              onPressed: () async {
                                final loc = await LocationService.instance
                                    .getCurrentLocation();
                                if (loc != null) {
                                  setState(() => _cityCtrl.text = loc);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _countryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years of experience',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected salary min (₹/yr)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxSalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected salary max (₹/yr)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _skillsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
