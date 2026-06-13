import 'dart:convert';

import 'package:joballocate/models/json_resume.dart';

/// Stored inside API/Firestore payloads under [kResumeModelSchema].
const String kResumeModelSchema = 'resume_model_v1';

/// Bundled template identifier for the teal two-column layout ("Resume 1").
const String kResumeTemplateResume1 = 'resume_1';

class ContactInfo {
  const ContactInfo({this.mobile = '', this.email = ''});

  final String mobile;
  final String email;

  ContactInfo copyWith({String? mobile, String? email}) =>
      ContactInfo(mobile: mobile ?? this.mobile, email: email ?? this.email);

  Map<String, dynamic> toJson() => {'mobile': mobile, 'email': email};

  factory ContactInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContactInfo();
    return ContactInfo(
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class PersonalDetailRow {
  const PersonalDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  PersonalDetailRow copyWith({String? label, String? value}) =>
      PersonalDetailRow(label: label ?? this.label, value: value ?? this.value);

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  factory PersonalDetailRow.fromJson(dynamic json) {
    if (json is Map) {
      final m = Map<String, dynamic>.from(json);
      return PersonalDetailRow(
        label: m['label']?.toString() ?? '',
        value: m['value']?.toString() ?? '',
      );
    }
    return const PersonalDetailRow(label: '', value: '');
  }
}

class SchoolingColumn {
  const SchoolingColumn({
    this.boardName = '',
    this.medium = '',
    this.yearOfPassing = '',
    this.score = '',
  });

  final String boardName;
  final String medium;
  final String yearOfPassing;
  final String score;

  SchoolingColumn copyWith({
    String? boardName,
    String? medium,
    String? yearOfPassing,
    String? score,
  }) =>
      SchoolingColumn(
        boardName: boardName ?? this.boardName,
        medium: medium ?? this.medium,
        yearOfPassing: yearOfPassing ?? this.yearOfPassing,
        score: score ?? this.score,
      );

  Map<String, dynamic> toJson() => {
        'board_name': boardName,
        'medium': medium,
        'year_of_passing': yearOfPassing,
        'score': score,
      };

  factory SchoolingColumn.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SchoolingColumn();
    return SchoolingColumn(
      boardName: json['board_name']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
      yearOfPassing: json['year_of_passing']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
    );
  }
}

class SchoolingBlock {
  const SchoolingBlock({required this.class12, required this.class10});

  final SchoolingColumn class12;
  final SchoolingColumn class10;

  SchoolingBlock copyWith({SchoolingColumn? class12, SchoolingColumn? class10}) =>
      SchoolingBlock(class12: class12 ?? this.class12, class10: class10 ?? this.class10);

  Map<String, dynamic> toJson() => {
        'class_12': class12.toJson(),
        'class_10': class10.toJson(),
      };

  factory SchoolingBlock.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SchoolingBlock(
        class12: SchoolingColumn(),
        class10: SchoolingColumn(),
      );
    }
    return SchoolingBlock(
      class12: SchoolingColumn.fromJson(
        json['class_12'] is Map ? Map<String, dynamic>.from(json['class_12'] as Map) : null,
      ),
      class10: SchoolingColumn.fromJson(
        json['class_10'] is Map ? Map<String, dynamic>.from(json['class_10'] as Map) : null,
      ),
    );
  }
}

class GraduationBlock {
  const GraduationBlock({this.course = '', this.college = '', this.score = ''});

  final String course;
  final String college;
  final String score;

  GraduationBlock copyWith({String? course, String? college, String? score}) =>
      GraduationBlock(
        course: course ?? this.course,
        college: college ?? this.college,
        score: score ?? this.score,
      );

  Map<String, dynamic> toJson() => {
        'course': course,
        'college': college,
        'score': score,
      };

  factory GraduationBlock.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GraduationBlock();
    return GraduationBlock(
      course: json['course']?.toString() ?? '',
      college: json['college']?.toString() ?? '',
      score: json['score']?.toString() ?? '',
    );
  }
}

class EducationData {
  const EducationData({required this.graduation, required this.schooling});

  final GraduationBlock graduation;
  final SchoolingBlock schooling;

  EducationData copyWith({GraduationBlock? graduation, SchoolingBlock? schooling}) =>
      EducationData(graduation: graduation ?? this.graduation, schooling: schooling ?? this.schooling);

  Map<String, dynamic> toJson() => {
        'graduation': graduation.toJson(),
        'schooling': schooling.toJson(),
      };

  factory EducationData.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EducationData(
        graduation: GraduationBlock(),
        schooling: SchoolingBlock(
          class12: SchoolingColumn(),
          class10: SchoolingColumn(),
        ),
      );
    }
    return EducationData(
      graduation: GraduationBlock.fromJson(
        json['graduation'] is Map ? Map<String, dynamic>.from(json['graduation'] as Map) : null,
      ),
      schooling: SchoolingBlock.fromJson(
        json['schooling'] is Map ? Map<String, dynamic>.from(json['schooling'] as Map) : null,
      ),
    );
  }
}

class ExperienceItem {
  ExperienceItem({
    required this.id,
    this.companyName = '',
    this.dateRange = '',
    List<String>? bullets,
  }) : bullets = bullets ?? <String>[];

  final String id;
  final String companyName;
  final String dateRange;
  final List<String> bullets;

  String get headingLine {
    final c = companyName.trim();
    final d = dateRange.trim();
    if (c.isEmpty && d.isEmpty) return '';
    if (c.isEmpty) return d;
    if (d.isEmpty) return c;
    return '$c | $d';
  }

  ExperienceItem copyWith({
    String? id,
    String? companyName,
    String? dateRange,
    List<String>? bullets,
  }) =>
      ExperienceItem(
        id: id ?? this.id,
        companyName: companyName ?? this.companyName,
        dateRange: dateRange ?? this.dateRange,
        bullets: bullets ?? List<String>.from(this.bullets),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_name': companyName,
        'date_range': dateRange,
        'bullets': bullets,
      };

  factory ExperienceItem.fromJson(dynamic json) {
    if (json is! Map) {
      return ExperienceItem(id: DateTime.now().millisecondsSinceEpoch.toString());
    }
    final m = Map<String, dynamic>.from(json);
    final rawBullets = m['bullets'];
    List<String> b = [];
    if (rawBullets is List) {
      b = rawBullets.map((e) => e.toString()).toList();
    }
    return ExperienceItem(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      companyName: m['company_name']?.toString() ?? '',
      dateRange: m['date_range']?.toString() ?? '',
      bullets: b,
    );
  }
}

/// User-defined extra block (title + bullet lines).
class DynamicResumeSection {
  DynamicResumeSection({
    required this.id,
    this.title = '',
    List<String>? lines,
  }) : lines = lines ?? <String>[];

  final String id;
  final String title;
  final List<String> lines;

  DynamicResumeSection copyWith({String? id, String? title, List<String>? lines}) =>
      DynamicResumeSection(
        id: id ?? this.id,
        title: title ?? this.title,
        lines: lines ?? List<String>.from(this.lines),
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'lines': lines};

  factory DynamicResumeSection.fromJson(dynamic json) {
    if (json is! Map) {
      return DynamicResumeSection(id: DateTime.now().millisecondsSinceEpoch.toString());
    }
    final m = Map<String, dynamic>.from(json);
    final raw = m['lines'];
    return DynamicResumeSection(
      id: m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: m['title']?.toString() ?? '',
      lines: raw is List ? raw.map((e) => e.toString()).toList() : <String>[],
    );
  }
}

abstract final class ResumeSectionKeys {
  static const sidebar = 'sidebar';
  static const skills = 'skills';
  static const languages = 'languages';
  static const certifications = 'certifications';
  static const summary = 'summary';
  static const personal = 'personal';
  static const education = 'education';
  static const internships = 'internships';
  static const projects = 'projects';
  static const work = 'work';
  static const custom = 'custom';
}

/// Canonical resume document for the realtime builder. No sample career content —
/// defaults are empty strings / empty collections only.
class ResumeModel {
  ResumeModel({
    this.templateId = kResumeTemplateResume1,
    this.draftTitle = '',
    this.fullName = '',
    this.professionalTitle = '',
    this.profileImageBase64,
    this.profileImageUrl,
    ContactInfo? contact,
    List<String>? skills,
    List<String>? languages,
    List<String>? certifications,
    this.summary = '',
    List<PersonalDetailRow>? personalDetails,
    EducationData? education,
    List<ExperienceItem>? internships,
    List<ExperienceItem>? projects,
    List<ExperienceItem>? workExperience,
    List<DynamicResumeSection>? extraSections,
    Map<String, bool>? sectionVisible,
  })  : contact = contact ?? const ContactInfo(),
        skills = skills ?? <String>[],
        languages = languages ?? <String>[],
        certifications = certifications ?? <String>[],
        personalDetails = personalDetails ?? <PersonalDetailRow>[],
        education = education ??
            const EducationData(
              graduation: GraduationBlock(),
              schooling: SchoolingBlock(
                class12: SchoolingColumn(),
                class10: SchoolingColumn(),
              ),
            ),
        internships = internships ?? <ExperienceItem>[],
        projects = projects ?? <ExperienceItem>[],
        workExperience = workExperience ?? <ExperienceItem>[],
        extraSections = extraSections ?? <DynamicResumeSection>[],
        sectionVisible = sectionVisible ?? _defaultVisibility;

  static Map<String, bool> get _defaultVisibility => {
        ResumeSectionKeys.sidebar: true,
        ResumeSectionKeys.skills: true,
        ResumeSectionKeys.languages: true,
        ResumeSectionKeys.certifications: true,
        ResumeSectionKeys.summary: true,
        ResumeSectionKeys.personal: true,
        ResumeSectionKeys.education: true,
        ResumeSectionKeys.internships: true,
        ResumeSectionKeys.projects: true,
        ResumeSectionKeys.work: true,
        ResumeSectionKeys.custom: true,
      };

  final String templateId;
  final String draftTitle;
  final String fullName;
  final String professionalTitle;

  /// Raw base64 (no data-uri prefix) for local preview + PDF.
  final String? profileImageBase64;

  /// When set (e.g. after Firebase Storage upload), preview loads from network.
  final String? profileImageUrl;

  final ContactInfo contact;
  final List<String> skills;
  final List<String> languages;
  final List<String> certifications;
  final String summary;
  final List<PersonalDetailRow> personalDetails;
  final EducationData education;
  final List<ExperienceItem> internships;
  final List<ExperienceItem> projects;
  final List<ExperienceItem> workExperience;
  final List<DynamicResumeSection> extraSections;
  final Map<String, bool> sectionVisible;

  /// Empty document — placeholders in the UI use separate widget strings, not stored here.
  factory ResumeModel.empty() => ResumeModel();

  /// Skeleton content for **Minimal ATS** — same layout before and after edits; user replaces text only.
  factory ResumeModel.minimalAtsStarter() {
    final vis = Map<String, bool>.from(ResumeModel._defaultVisibility);
    return ResumeModel(
      templateId: kResumeTemplateResume1,
      draftTitle: 'My résumé',
      fullName: 'YOUR NAME',
      professionalTitle: 'YOUR PROFESSIONAL TITLE',
      contact: const ContactInfo(
        mobile: '+91 1234567890',
        email: 'your.email@gmail.com',
      ),
      summary:
          'Brief summary of your background, strengths, and goals — replace this paragraph with your own. The section order and styling stay fixed as you edit.',
      skills: const [
        'Skill 1',
        'Skill 2',
        'Skill 3',
        'Skill 4',
        'Skill 5',
        'Skill 6',
      ],
      personalDetails: const [
        PersonalDetailRow(label: 'LinkedIn', value: 'linkedin.com/in/yourprofile'),
        PersonalDetailRow(label: 'Current Location', value: 'City, State'),
      ],
      education: const EducationData(
        graduation: GraduationBlock(
          course: 'Degree Name',
          college: 'University or College | City, State',
          score: 'Month 20XX',
        ),
        schooling: SchoolingBlock(
          class12: SchoolingColumn(),
          class10: SchoolingColumn(),
        ),
      ),
      workExperience: [
        ExperienceItem(
          id: 'starter_work',
          companyName: 'Job Title | Company Name | City, State',
          dateRange: 'Month 20XX – Present',
          bullets: const [
            'Achievement or responsibility — replace with your experience.',
            'Another bullet describing impact or scope.',
            'Optional third bullet (tools, team size, metrics).',
          ],
        ),
      ],
      sectionVisible: vis,
    );
  }

  ResumeModel copyWith({
    String? templateId,
    String? draftTitle,
    String? fullName,
    String? professionalTitle,
    String? profileImageBase64,
    String? profileImageUrl,
    bool clearProfileImageBase64 = false,
    bool clearProfileImageUrl = false,
    ContactInfo? contact,
    List<String>? skills,
    List<String>? languages,
    List<String>? certifications,
    String? summary,
    List<PersonalDetailRow>? personalDetails,
    EducationData? education,
    List<ExperienceItem>? internships,
    List<ExperienceItem>? projects,
    List<ExperienceItem>? workExperience,
    List<DynamicResumeSection>? extraSections,
    Map<String, bool>? sectionVisible,
  }) =>
      ResumeModel(
        templateId: templateId ?? this.templateId,
        draftTitle: draftTitle ?? this.draftTitle,
        fullName: fullName ?? this.fullName,
        professionalTitle: professionalTitle ?? this.professionalTitle,
        profileImageBase64:
            clearProfileImageBase64 ? null : (profileImageBase64 ?? this.profileImageBase64),
        profileImageUrl: clearProfileImageUrl ? null : (profileImageUrl ?? this.profileImageUrl),
        contact: contact ?? this.contact,
        skills: skills ?? List<String>.from(this.skills),
        languages: languages ?? List<String>.from(this.languages),
        certifications: certifications ?? List<String>.from(this.certifications),
        summary: summary ?? this.summary,
        personalDetails: personalDetails ?? List<PersonalDetailRow>.from(this.personalDetails),
        education: education ?? this.education,
        internships: internships ?? List<ExperienceItem>.from(this.internships),
        projects: projects ?? List<ExperienceItem>.from(this.projects),
        workExperience: workExperience ?? List<ExperienceItem>.from(this.workExperience),
        extraSections: extraSections ?? List<DynamicResumeSection>.from(this.extraSections),
        sectionVisible: sectionVisible ?? Map<String, bool>.from(this.sectionVisible),
      );

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        'draft_title': draftTitle,
        'full_name': fullName,
        'professional_title': professionalTitle,
        'profile_image_base64': profileImageBase64,
        'profile_image_url': profileImageUrl,
        'contact': contact.toJson(),
        'skills': skills,
        'languages': languages,
        'certifications': certifications,
        'summary': summary,
        'personal_details': personalDetails.map((e) => e.toJson()).toList(),
        'education': education.toJson(),
        'internships': internships.map((e) => e.toJson()).toList(),
        'projects': projects.map((e) => e.toJson()).toList(),
        'work_experience': workExperience.map((e) => e.toJson()).toList(),
        'extra_sections': extraSections.map((e) => e.toJson()).toList(),
        'section_visible': sectionVisible,
      };

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    final pd = json['personal_details'];
    final personalList = <PersonalDetailRow>[];
    if (pd is List) {
      for (final e in pd) {
        personalList.add(PersonalDetailRow.fromJson(e));
      }
    }

    final vis = json['section_visible'];
    Map<String, bool> visibility = Map<String, bool>.from(ResumeModel._defaultVisibility);
    if (vis is Map) {
      for (final e in vis.entries) {
        visibility[e.key.toString()] = e.value == true;
      }
    }

    return ResumeModel(
      templateId: json['template_id']?.toString() ?? kResumeTemplateResume1,
      draftTitle: json['draft_title']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      professionalTitle: json['professional_title']?.toString() ?? '',
      profileImageBase64: json['profile_image_base64']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      contact: ContactInfo.fromJson(
        json['contact'] is Map ? Map<String, dynamic>.from(json['contact'] as Map) : null,
      ),
      skills: _stringList(json['skills']),
      languages: _stringList(json['languages']),
      certifications: _stringList(json['certifications']),
      summary: json['summary']?.toString() ?? '',
      personalDetails: personalList,
      education: EducationData.fromJson(
        json['education'] is Map ? Map<String, dynamic>.from(json['education'] as Map) : null,
      ),
      internships: _experienceList(json['internships']),
      projects: _experienceList(json['projects']),
      workExperience: _experienceList(json['work_experience']),
      extraSections: _dynamicSections(json['extra_sections']),
      sectionVisible: visibility,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((s) => true).toList();
  }

  static List<ExperienceItem> _experienceList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map(ExperienceItem.fromJson).toList();
  }

  static List<DynamicResumeSection> _dynamicSections(dynamic raw) {
    if (raw is! List) return [];
    return raw.map(DynamicResumeSection.fromJson).toList();
  }

  /// Best-effort conversion from legacy JSON Resume drafts / imports.
  factory ResumeModel.fromLegacyJsonResume(JsonResume r) {
    var imgB64 = '';
    final img = r.basics.image.trim();
    if (img.startsWith('data:image')) {
      final i = img.indexOf(',');
      imgB64 = i >= 0 && i < img.length - 1 ? img.substring(i + 1) : '';
    } else {
      imgB64 = '';
    }

    final skills = r.skills.map((s) => s.name).where((n) => n.trim().isNotEmpty).toList();
    final langs =
        r.languages.map((l) => '${l.language}${l.fluency.isNotEmpty ? ' — ${l.fluency}' : ''}').toList();

    final work = <ExperienceItem>[];
    for (final w in r.work) {
      final bullets = <String>[];
      if (w.summary.trim().isNotEmpty) bullets.add(w.summary.trim());
      for (final h in w.highlights) {
        if (h.trim().isNotEmpty) bullets.add(h.trim());
      }
      work.add(
        ExperienceItem(
          id: '${w.startDate}_${w.endDate}_${w.name}'.hashCode.toString(),
          companyName: '${w.name}${w.position.isNotEmpty ? ' — ${w.position}' : ''}'.trim(),
          dateRange: [w.startDate, w.endDate].where((s) => s.trim().isNotEmpty).join(' – '),
          bullets: bullets,
        ),
      );
    }

    final projects = <ExperienceItem>[];
    for (final p in r.publications) {
      final bullets = <String>[];
      if (p.summary.trim().isNotEmpty) bullets.add(p.summary.trim());
      projects.add(
        ExperienceItem(
          id: p.name.hashCode.toString(),
          companyName: p.name,
          dateRange: p.releaseDate,
          bullets: bullets,
        ),
      );
    }

    final internships = <ExperienceItem>[];
    for (final v in r.volunteer) {
      internships.add(
        ExperienceItem(
          id: v.organization.hashCode.toString(),
          companyName: v.organization,
          dateRange: [v.startDate, v.endDate].where((s) => s.trim().isNotEmpty).join(' – '),
          bullets: v.summary.trim().isNotEmpty ? [v.summary.trim()] : [],
        ),
      );
    }

    final eduRows = <PersonalDetailRow>[];
    final school = SchoolingBlock(
      class12: const SchoolingColumn(),
      class10: const SchoolingColumn(),
    );
    if (r.education.isNotEmpty) {
      final e0 = r.education.first;
      final g = GraduationBlock(
        course: e0.studyType.isNotEmpty ? e0.studyType : e0.area,
        college: e0.institution,
        score: e0.score,
      );
      for (final e in r.education) {
        final line =
            '${e.studyType} ${e.area}'.trim().isNotEmpty ? '${e.studyType} ${e.area}'.trim() : e.institution;
        if (line.isNotEmpty) {
          eduRows.add(PersonalDetailRow(label: 'Education', value: line));
        }
      }
      return ResumeModel(
        fullName: r.basics.name,
        professionalTitle: r.basics.label,
        profileImageBase64: imgB64.isNotEmpty ? imgB64 : null,
        profileImageUrl: img.isNotEmpty && !img.startsWith('data:') ? img : null,
        contact: ContactInfo(mobile: r.basics.phone, email: r.basics.email),
        skills: skills,
        languages: langs,
        certifications: const [],
        summary: r.basics.summary,
        personalDetails: [
          if (r.basics.location.city.isNotEmpty)
            PersonalDetailRow(label: 'Current Location', value: r.basics.location.city),
          ...eduRows,
        ],
        education: EducationData(graduation: g, schooling: school),
        internships: internships,
        projects: projects,
        workExperience: work,
      );
    }

    return ResumeModel(
      fullName: r.basics.name,
      professionalTitle: r.basics.label,
      profileImageBase64: imgB64.isNotEmpty ? imgB64 : null,
      profileImageUrl: img.isNotEmpty && !img.startsWith('data:') ? img : null,
      contact: ContactInfo(mobile: r.basics.phone, email: r.basics.email),
      skills: skills,
      languages: langs,
      summary: r.basics.summary,
      personalDetails: [
        if (r.basics.location.city.isNotEmpty)
          PersonalDetailRow(label: 'Current Location', value: r.basics.location.city),
      ],
      education: EducationData(
        graduation: const GraduationBlock(),
        schooling: school,
      ),
      internships: internships,
      projects: projects,
      workExperience: work,
    );
  }

  static String? profileBytesToDataUri(String? base64Raw) {
    if (base64Raw == null || base64Raw.isEmpty) return null;
    return 'data:image/jpeg;base64,$base64Raw';
  }

  static String? tryDecodeBase64ToString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      utf8.decode(base64Decode(raw));
      return raw;
    } catch (_) {
      return null;
    }
  }
}

/// Wraps model for Laravel `content` JSON and Firebase documents.
Map<String, dynamic> resumeModelToApiEnvelope(ResumeModel model) => {
      'schema': kResumeModelSchema,
      'version': 1,
      'data': model.toJson(),
    };

ResumeModel resumeModelFromApiEnvelope(Map<String, dynamic>? json) {
  if (json == null) return ResumeModel.empty();
  if (json['schema']?.toString() == kResumeModelSchema && json['data'] is Map) {
    return ResumeModel.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }
  if (json.containsKey('basics')) {
    return ResumeModel.fromLegacyJsonResume(JsonResume.fromJson(json));
  }
  return ResumeModel.empty();
}
