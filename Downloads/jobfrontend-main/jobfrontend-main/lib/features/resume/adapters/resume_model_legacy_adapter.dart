import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/json_resume.dart';

/// Converts [ResumeModel] into JSON Resume for employer previews and legacy tooling.
JsonResume resumeModelToLegacyJsonResume(ResumeModel m) {
  final basics = Basics(
    name: m.fullName,
    email: m.contact.email,
    phone: m.contact.mobile,
    summary: m.summary,
    image: ResumeModel.profileBytesToDataUri(m.profileImageBase64) ?? (m.profileImageUrl ?? ''),
  );

  for (final row in m.personalDetails) {
    final k = row.label.toLowerCase();
    if (k.contains('location')) basics.location.city = row.value;
    if (k.contains('dob') || k.contains('birth')) basics.dateOfBirth = row.value;
    if (k.contains('gender')) basics.gender = row.value;
  }

  final skills = m.skills.map((s) => Skill(name: s)).toList();

  final langs = <Language>[];
  for (final line in m.languages) {
    final parts = line.split('—');
    langs.add(Language(
      language: parts.first.trim(),
      fluency: parts.length > 1 ? parts.sublist(1).join('—').trim() : '',
    ));
  }

  final work = <Work>[];
  for (final w in m.workExperience) {
    final rawName = w.companyName.trim();
    String company = rawName;
    String position = '';
    if (rawName.contains('—')) {
      final idx = rawName.indexOf('—');
      company = rawName.substring(0, idx).trim();
      position = rawName.substring(idx + 1).trim();
    }
    final dr = w.dateRange.split(RegExp(r'\s*[–-]\s*'));
    work.add(Work(
      name: company,
      position: position,
      startDate: dr.isNotEmpty ? dr.first : '',
      endDate: dr.length > 1 ? dr.sublist(1).join(' – ') : '',
      summary: '',
      highlights: List<String>.from(w.bullets),
    ));
  }

  final publications = <Publication>[];
  for (final p in m.projects) {
    publications.add(Publication(
      name: p.companyName,
      releaseDate: p.dateRange,
      summary: p.bullets.isNotEmpty ? p.bullets.join('\n') : '',
    ));
  }

  final volunteer = <Volunteer>[];
  for (final i in m.internships) {
    volunteer.add(Volunteer(
      organization: i.companyName,
      position: '',
      startDate: '',
      endDate: i.dateRange,
      summary: i.bullets.isNotEmpty ? i.bullets.join('\n') : '',
    ));
  }

  final education = <Education>[
    Education(
      institution: m.education.graduation.college,
      area: m.education.graduation.course,
      score: m.education.graduation.score,
    ),
    Education(
      institution: 'Class XII',
      area: m.education.schooling.class12.boardName,
      studyType: m.education.schooling.class12.medium,
      startDate: m.education.schooling.class12.yearOfPassing,
      score: m.education.schooling.class12.score,
    ),
    Education(
      institution: 'Class X',
      area: m.education.schooling.class10.boardName,
      studyType: m.education.schooling.class10.medium,
      startDate: m.education.schooling.class10.yearOfPassing,
      score: m.education.schooling.class10.score,
    ),
  ];

  return JsonResume(
    basics: basics,
    skills: skills,
    languages: langs,
    work: work,
    publications: publications,
    volunteer: volunteer,
    education: education,
  );
}
