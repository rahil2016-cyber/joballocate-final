/// Mirrors Laravel `ResumeHtmlDemoData::viewProfile()` for gallery thumbnails.
class ResumeDemoViewProfile {
  const ResumeDemoViewProfile({
    required this.variant,
    required this.fullName,
    required this.professionalTitle,
    required this.summary,
    required this.mobile,
    required this.email,
    this.photoUrl,
    required this.location,
    required this.skills,
    required this.languages,
    required this.workExperience,
    required this.internships,
    required this.projects,
    required this.educationEntries,
    required this.certifications,
  });

  final int variant;
  final String fullName;
  final String professionalTitle;
  final String summary;
  final String mobile;
  final String email;
  final String? photoUrl;
  final String location;
  final List<String> skills;
  final List<String> languages;
  final List<ResumeDemoExperienceBlock> workExperience;
  final List<ResumeDemoExperienceBlock> internships;
  final List<ResumeDemoExperienceBlock> projects;
  final List<ResumeDemoEducationEntry> educationEntries;
  final List<String> certifications;

  factory ResumeDemoViewProfile.fromJson(Map<String, dynamic> json) {
    return ResumeDemoViewProfile(
      variant: (json['variant'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      professionalTitle: json['professional_title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      location: json['location']?.toString() ?? '',
      skills: _stringList(json['skills']),
      languages: _stringList(json['languages']),
      workExperience: _blocks(json['work_experience']),
      internships: _blocks(json['internships']),
      projects: _blocks(json['projects']),
      educationEntries: _education(json['education_list']),
      certifications: _stringList(json['certifications']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  }

  static List<ResumeDemoExperienceBlock> _blocks(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ResumeDemoExperienceBlock.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String get summarySnippet {
    final s = summary.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return '';
    if (s.length <= 140) return s;
    return '${s.substring(0, 137)}…';
  }

  String? get primaryWorkLine {
    final w = workExperience.isNotEmpty ? workExperience.first : null;
    if (w == null) return null;
    final h = w.heading.trim();
    if (h.isEmpty) return null;
    final d = w.dates.trim();
    return d.isNotEmpty ? '$h · $d' : h;
  }

  String? get primaryWorkBody {
    final w = workExperience.isNotEmpty ? workExperience.first : null;
    if (w == null) return null;
    final body = w.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (body.isEmpty) return null;
    if (body.length <= 100) return body;
    return '${body.substring(0, 97)}…';
  }

  String? get primaryProjectLine {
    final p = projects.isNotEmpty ? projects.first : null;
    if (p == null) return null;
    return p.heading.trim().isNotEmpty ? p.heading.trim() : null;
  }

  String? get primaryInternshipLine {
    final i = internships.isNotEmpty ? internships.first : null;
    if (i == null) return null;
    final h = i.heading.trim();
    return h.isEmpty ? null : h;
  }

  String? get primaryEducationLine {
    final e = educationEntries.isNotEmpty ? educationEntries.first : null;
    if (e == null) return null;
    final parts = [e.title, e.institution, e.year].where((s) => s.trim().isNotEmpty);
    final line = parts.join(' · ');
    return line.isEmpty ? null : line;
  }

  String? get primaryCertLine {
    if (certifications.isEmpty) return null;
    return certifications.take(2).join(' · ');
  }

  static List<ResumeDemoEducationEntry> _education(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ResumeDemoEducationEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class ResumeDemoEducationEntry {
  const ResumeDemoEducationEntry({
    required this.title,
    required this.institution,
    required this.year,
    required this.marks,
  });

  final String title;
  final String institution;
  final String year;
  final String marks;

  factory ResumeDemoEducationEntry.fromJson(Map<String, dynamic> json) {
    return ResumeDemoEducationEntry(
      title: json['title']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      marks: json['marks']?.toString() ?? '',
    );
  }
}

class ResumeDemoExperienceBlock {
  const ResumeDemoExperienceBlock({
    required this.heading,
    required this.dates,
    required this.body,
  });

  final String heading;
  final String dates;
  final String body;

  factory ResumeDemoExperienceBlock.fromJson(Map<String, dynamic> json) {
    return ResumeDemoExperienceBlock(
      heading: json['heading']?.toString() ?? '',
      dates: json['dates']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
    );
  }
}
