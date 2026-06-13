import 'package:joballocate/constants/industry_types.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/utils/media_url.dart';

/// True when [m] has anything worth showing beyond an empty document.
bool resumeModelHasUserContent(ResumeModel m) {
  bool ne(String s) => s.trim().isNotEmpty;
  if (ne(m.fullName)) return true;
  if (ne(m.professionalTitle)) return true;
  if (ne(m.summary)) return true;
  if (ne(m.contact.mobile) || ne(m.contact.email)) return true;
  if (m.skills.any((s) => ne(s))) return true;
  if (m.languages.any((s) => ne(s))) return true;
  if (m.certifications.any((s) => ne(s))) return true;
  if (m.personalDetails.any((r) => ne(r.label) || ne(r.value))) return true;
  if (ne(m.education.graduation.course) ||
      ne(m.education.graduation.college) ||
      ne(m.education.graduation.score)) {
    return true;
  }
  final s12 = m.education.schooling.class12;
  final s10 = m.education.schooling.class10;
  if ([s12.boardName, s12.medium, s12.yearOfPassing, s12.score, s10.boardName, s10.medium, s10.yearOfPassing, s10.score]
      .any((s) => ne(s))) {
    return true;
  }
  if (m.workExperience.isNotEmpty || m.internships.isNotEmpty || m.projects.isNotEmpty) return true;
  if (m.profileImageUrl != null && m.profileImageUrl!.trim().isNotEmpty) return true;
  if (m.profileImageBase64 != null && m.profileImageBase64!.trim().isNotEmpty) return true;
  return false;
}

String _trim(dynamic v) => v?.toString().trim() ?? '';

List<String> _skillsFromProfile(Map<String, dynamic> p) {
  final sk = p['skills'];
  if (sk is List) {
    return sk.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
  }
  final s = _trim(p['skills']);
  if (s.isEmpty) return [];
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

List<String> _bulletsFromText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  return raw
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

List<ExperienceItem> _internshipsFromProfile(List<dynamic>? list) {
  if (list == null) return [];
  final out = <ExperienceItem>[];
  var i = 0;
  for (final raw in list) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final org = _trim(m['organization']);
    final role = _trim(m['role']);
    final dur = _trim(m['duration']);
    final desc = _trim(m['description']);
    final left = [role, org].where((s) => s.isNotEmpty).join(' | ');
    if (left.isEmpty && dur.isEmpty && desc.isEmpty) continue;
    out.add(
      ExperienceItem(
        id: 'profile_int_$i',
        companyName: left.isEmpty ? org : left,
        dateRange: dur,
        bullets: _bulletsFromText(desc),
      ),
    );
    i++;
  }
  return out;
}

List<ExperienceItem> _projectsFromProfile(List<dynamic>? list) {
  if (list == null) return [];
  final out = <ExperienceItem>[];
  var i = 0;
  for (final raw in list) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final title = _trim(m['title']).isNotEmpty ? _trim(m['title']) : _trim(m['name']);
    final link = _trim(m['link']);
    final desc = _trim(m['description']);
    if (title.isEmpty && link.isEmpty && desc.isEmpty) continue;
    out.add(
      ExperienceItem(
        id: 'profile_proj_$i',
        companyName: title,
        dateRange: link,
        bullets: _bulletsFromText(desc),
      ),
    );
    i++;
  }
  return out;
}

List<ExperienceItem> _workExperienceFromProfile(List<dynamic>? list) {
  if (list == null) return [];
  final out = <ExperienceItem>[];
  var i = 0;
  for (final raw in list) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final name = _trim(m['company_name']);
    final dr = _trim(m['date_range']);
    List<String> bullets = [];
    final bl = m['bullets'];
    if (bl is List) {
      bullets = bl.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else {
      bullets = _bulletsFromText(m['description']?.toString());
    }
    if (name.isEmpty && dr.isEmpty && bullets.isEmpty) continue;
    final idRaw = _trim(m['id']);
    out.add(
      ExperienceItem(
        id: idRaw.isNotEmpty ? idRaw : 'profile_work_$i',
        companyName: name,
        dateRange: dr,
        bullets: bullets,
      ),
    );
    i++;
  }
  return out;
}

/// Maps Laravel `GET /job-seeker/profile` payload (+ session user) into [ResumeModel].
ResumeModel resumeModelFromSeekerProfileMaps({
  Map<String, dynamic>? profile,
  Map<String, dynamic>? sessionUser,
}) {
  final p = profile ?? const <String, dynamic>{};
  final u = sessionUser ?? const <String, dynamic>{};

  final doc = p['resume_document'];
  if (doc is Map) {
    final docMap = Map<String, dynamic>.from(doc);
    if (docMap['schema']?.toString() == kResumeModelSchema && docMap['data'] is Map) {
      final fromDoc = ResumeModel.fromJson(Map<String, dynamic>.from(docMap['data'] as Map));
      final fromLegacy = _resumeModelFromSeekerProfileMapsCore(p, u);
      return mergeResumePreferNonEmpty(fromDoc, fromLegacy);
    }
  }

  return _resumeModelFromSeekerProfileMapsCore(p, u);
}

ResumeModel _resumeModelFromSeekerProfileMapsCore(
  Map<String, dynamic> p,
  Map<String, dynamic> u,
) {

  final fullName = _trim(u['name']).isNotEmpty ? _trim(u['name']) : _trim(p['name']);
  final headline = _trim(p['headline']);
  var bio = _trim(p['bio']);
  final ey = p['experience_years'];
  if (ey != null && _trim(ey).isNotEmpty) {
    final line = 'Years of experience: ${_trim(ey)}';
    bio = bio.isEmpty ? line : '$bio\n\n$line';
  }
  final ind = _trim(p['industry_type']);
  if (ind.isNotEmpty) {
    final line = 'Industry: ${industryTypeLabel(ind)}';
    bio = bio.isEmpty ? line : '$bio\n\n$line';
  }

  var phone = _trim(p['phone']).isNotEmpty ? _trim(p['phone']) : _trim(u['phone']);
  var email = _trim(p['email']).isNotEmpty ? _trim(p['email']) : _trim(u['email']);
  if (email.contains('@internal.joballocate')) email = '';

  final personal = <PersonalDetailRow>[];
  final city = _trim(p['city']);
  final country = _trim(p['country']);
  if (city.isNotEmpty || country.isNotEmpty) {
    personal.add(
      PersonalDetailRow(
        label: 'Current Location',
        value: [city, country].where((e) => e.isNotEmpty).join(', '),
      ),
    );
  }
  final dob = _trim(p['dob']);
  if (dob.isNotEmpty) personal.add(PersonalDetailRow(label: 'Date of Birth', value: dob));
  final gender = _trim(p['gender']);
  if (gender.isNotEmpty) personal.add(PersonalDetailRow(label: 'Gender', value: gender));

  final portfolio = _trim(p['portfolio_url']);
  if (portfolio.isNotEmpty) {
    if (portfolio.toLowerCase().contains('linkedin')) {
      personal.add(PersonalDetailRow(label: 'LinkedIn', value: portfolio));
    } else {
      personal.add(PersonalDetailRow(label: 'Portfolio', value: portfolio));
    }
  }

  final ht = _trim(p['hometown']);
  if (ht.isNotEmpty) {
    personal.add(PersonalDetailRow(label: 'Home Town', value: ht));
  }

  final minSal = _trim(p['expected_salary_min']);
  final maxSal = _trim(p['expected_salary_max']);
  if (minSal.isNotEmpty || maxSal.isNotEmpty) {
    final rng = [minSal, maxSal].where((e) => e.isNotEmpty).join(' – ');
    personal.add(PersonalDetailRow(label: 'Expected salary (INR)', value: rng));
  }

  GraduationBlock grad = const GraduationBlock();
  SchoolingColumn class12 = const SchoolingColumn();
  SchoolingColumn class10 = const SchoolingColumn();
  final edu = p['education'];
  if (edu is List && edu.isNotEmpty) {
    void applyRow(int index, void Function(Map<String, dynamic> m) fn) {
      if (index >= edu.length) return;
      final e = edu[index];
      if (e is! Map) return;
      fn(Map<String, dynamic>.from(e));
    }

    applyRow(0, (m) {
      grad = GraduationBlock(
        course: _trim(m['title']),
        college: _trim(m['institution']),
        score: _trim(m['year_completed']).isNotEmpty
            ? _trim(m['year_completed'])
            : _trim(m['marks_or_grade']),
      );
    });
    applyRow(1, (m) {
      class12 = SchoolingColumn(
        boardName: _trim(m['title']).isNotEmpty ? _trim(m['title']) : _trim(m['institution']),
        medium: _trim(m['board_or_stream']),
        yearOfPassing: _trim(m['year_completed']),
        score: _trim(m['marks_or_grade']),
      );
    });
    applyRow(2, (m) {
      class10 = SchoolingColumn(
        boardName: _trim(m['title']).isNotEmpty ? _trim(m['title']) : _trim(m['institution']),
        medium: _trim(m['board_or_stream']),
        yearOfPassing: _trim(m['year_completed']),
        score: _trim(m['marks_or_grade']),
      );
    });
  }

  final certs = <String>[];
  final ach = p['achievements'];
  if (ach is List) {
    for (final a in ach) {
      final t = _trim(a);
      if (t.isNotEmpty) certs.add(t);
    }
  }
  final certStructured = p['certifications_structured'];
  if (certStructured is List) {
    for (final row in certStructured) {
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row);
      final n = _trim(m['name']);
      final d = _trim(m['date']);
      if (n.isNotEmpty) certs.add(d.isNotEmpty ? '$n — $d' : n);
    }
  }

  final languages = <String>[];
  final lk = p['languages_known'];
  if (lk is List) {
    for (final row in lk) {
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row);
      final lang = _trim(m['language']);
      final prof = _trim(m['proficiency']);
      if (lang.isNotEmpty) languages.add(prof.isNotEmpty ? '$lang — $prof' : lang);
    }
  }

  final workExp = _workExperienceFromProfile(p['work_experience'] is List ? p['work_experience'] as List : null);

  var photoUrl = _trim(p['profile_photo_url']);
  if (photoUrl.isEmpty) photoUrl = _trim(p['profile_photo']);
  if (photoUrl.isEmpty) photoUrl = _trim(u['profile_photo_url']);
  final resolvedPhoto = photoUrl.isNotEmpty ? (MediaUrl.resolve(photoUrl) ?? photoUrl) : null;

  final draftTitle = fullName.isNotEmpty ? '$fullName — Résumé' : 'My résumé';

  return ResumeModel(
    draftTitle: draftTitle,
    fullName: fullName,
    professionalTitle: headline,
    summary: bio,
    contact: ContactInfo(mobile: phone, email: email),
    skills: _skillsFromProfile(p),
    languages: languages,
    certifications: certs,
    personalDetails: personal,
    education: EducationData(
      graduation: grad,
      schooling: SchoolingBlock(class12: class12, class10: class10),
    ),
    internships: _internshipsFromProfile(p['internships'] is List ? p['internships'] as List : null),
    projects: _projectsFromProfile(p['projects'] is List ? p['projects'] as List : null),
    workExperience: workExp,
    profileImageUrl: resolvedPhoto,
  );
}

String _preferStr(String a, String b) => a.trim().isNotEmpty ? a : b;

/// For each scalar / list field, use [primary] when non-empty, otherwise [fallback] (e.g. ATS starter skeleton).
ResumeModel mergeResumePreferNonEmpty(ResumeModel primary, ResumeModel fallback) {
  final pg = primary.education.graduation;
  final fg = fallback.education.graduation;
  final grad = GraduationBlock(
    course: _preferStr(pg.course, fg.course),
    college: _preferStr(pg.college, fg.college),
    score: _preferStr(pg.score, fg.score),
  );

  final p12 = primary.education.schooling.class12;
  final f12 = fallback.education.schooling.class12;
  final p10 = primary.education.schooling.class10;
  final f10 = fallback.education.schooling.class10;

  SchoolingColumn mergeCol(SchoolingColumn a, SchoolingColumn b) => SchoolingColumn(
        boardName: _preferStr(a.boardName, b.boardName),
        medium: _preferStr(a.medium, b.medium),
        yearOfPassing: _preferStr(a.yearOfPassing, b.yearOfPassing),
        score: _preferStr(a.score, b.score),
      );

  final personal = <PersonalDetailRow>[...primary.personalDetails];
  final seen = personal.map((r) => r.label.trim().toLowerCase()).toSet();
  for (final r in fallback.personalDetails) {
    final k = r.label.trim().toLowerCase();
    if (k.isEmpty && r.value.trim().isEmpty) continue;
    if (!seen.contains(k)) {
      personal.add(r);
      seen.add(k);
    }
  }

  return ResumeModel(
    draftTitle: _preferStr(primary.draftTitle, fallback.draftTitle),
    fullName: _preferStr(primary.fullName, fallback.fullName),
    professionalTitle: _preferStr(primary.professionalTitle, fallback.professionalTitle),
    summary: _preferStr(primary.summary, fallback.summary),
    contact: ContactInfo(
      mobile: _preferStr(primary.contact.mobile, fallback.contact.mobile),
      email: _preferStr(primary.contact.email, fallback.contact.email),
    ),
    skills: primary.skills.isNotEmpty ? List<String>.from(primary.skills) : List<String>.from(fallback.skills),
    languages: primary.languages.isNotEmpty ? List<String>.from(primary.languages) : List<String>.from(fallback.languages),
    certifications:
        primary.certifications.isNotEmpty ? List<String>.from(primary.certifications) : List<String>.from(fallback.certifications),
    personalDetails: personal,
    education: EducationData(
      graduation: grad,
      schooling: SchoolingBlock(
        class12: mergeCol(p12, f12),
        class10: mergeCol(p10, f10),
      ),
    ),
    internships: primary.internships.isNotEmpty ? List<ExperienceItem>.from(primary.internships) : List<ExperienceItem>.from(fallback.internships),
    projects: primary.projects.isNotEmpty ? List<ExperienceItem>.from(primary.projects) : List<ExperienceItem>.from(fallback.projects),
    workExperience:
        primary.workExperience.isNotEmpty ? List<ExperienceItem>.from(primary.workExperience) : List<ExperienceItem>.from(fallback.workExperience),
    extraSections:
        primary.extraSections.isNotEmpty ? List<DynamicResumeSection>.from(primary.extraSections) : List<DynamicResumeSection>.from(fallback.extraSections),
    profileImageBase64: primary.profileImageBase64 ?? fallback.profileImageBase64,
    profileImageUrl: primary.profileImageUrl?.trim().isNotEmpty == true ? primary.profileImageUrl : fallback.profileImageUrl,
    sectionVisible: Map<String, bool>.from(fallback.sectionVisible),
    templateId: primary.templateId,
  );
}
