import 'package:joballocate/resume/models/resume_builder_ids.dart';

class ResumeTemplate {
  final int id;
  final String name;
  final String description;
  final String thumbnail;
  final List<String> sections;
  final String category;

  /// Routes Flutter preview + PDF assembly ([ResumeTemplateRegistry]).
  final String builderKey;

  /// Default accent (ARGB); overrides come from [ResumeStudioAppearance.accentOverride].
  final int accentArgb;

  /// Legacy API field — defaults to [id] when omitted.
  final int designVariant;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnail,
    required this.sections,
    required this.category,
    required this.builderKey,
    int? accentArgb,
    int? designVariant,
  })  : accentArgb = accentArgb ?? _defaultAccentArgb(id),
        designVariant = designVariant ?? id;

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id'], 0);
    final variantRaw = _readInt(json['design_variant'], id);
    final variant = variantRaw < 0 ? 0 : variantRaw;

    final bk = json['builder_key']?.toString();
    final accentParse = json['accent_argb'];

    return ResumeTemplate(
      id: id,
      name: json['name']?.toString() ?? 'Template',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      sections: _readSectionsList(json['sections']),
      category: json['category']?.toString() ?? 'professional',
      builderKey: (bk != null && bk.isNotEmpty) ? bk : defaultBuilderKeyForTemplateId(id),
      accentArgb: _parseArgb(accentParse) ?? _defaultAccentArgb(id),
      designVariant: variant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'thumbnail': thumbnail,
      'sections': sections,
      'category': category,
      'design_variant': designVariant,
      'builder_key': builderKey,
      'accent_argb': accentArgb,
    };
  }
}

const List<String> _kDefaultSections = [
  'contact',
  'skills',
  'languages',
  'certifications',
  'summary',
  'personal',
  'education',
  'internships',
  'projects',
  'experience',
];

int _readInt(dynamic raw, [int fallback = 0]) {
  if (raw == null) return fallback;
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is num) return raw.round();
  final s = raw.toString().trim();
  final direct = int.tryParse(s);
  if (direct != null) return direct;
  final asDouble = double.tryParse(s);
  return asDouble?.round() ?? fallback;
}

List<String> _readSectionsList(dynamic raw) {
  if (raw == null) return List<String>.from(_kDefaultSections);
  if (raw is! List) return List<String>.from(_kDefaultSections);
  return raw.map((e) => e?.toString() ?? '').toList();
}

int? _parseArgb(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  if (raw is num) return raw.round();
  final s = raw.toString().trim();
  final hex = int.tryParse(s.replaceFirst('#', ''), radix: 16);
  if (hex != null) {
    return hex <= 0xFFFFFF ? 0xFF000000 | hex : hex;
  }
  return int.tryParse(s);
}

String defaultBuilderKeyForTemplateId(int id) {
  switch (id.clamp(1, 12)) {
    case 1:
      return ResumeBuilderIds.minimalAts;
    case 2:
      return ResumeBuilderIds.modernProfessional;
    case 3:
      return ResumeBuilderIds.corporateBlue;
    case 4:
      return ResumeBuilderIds.creativeClean;
    case 5:
      return ResumeBuilderIds.executiveResume;
    case 6:
      return ResumeBuilderIds.fresherResume;
    case 7:
      return ResumeBuilderIds.darkProfessional;
    case 8:
      return ResumeBuilderIds.twoColumnResume;
    case 9:
      return ResumeBuilderIds.compactAts;
    case 10:
      return ResumeBuilderIds.elegantModern;
    case 11:
      return ResumeBuilderIds.corporateBlue;
    case 12:
      return ResumeBuilderIds.executiveResume;
    default:
      return ResumeBuilderIds.minimalAts;
  }
}

int _defaultAccentArgb(int id) {
  switch (id.clamp(1, 12)) {
    case 1:
      return 0xFF546E7A;
    case 2:
      return 0xFF1565C0;
    case 3:
      return 0xFF0D47A1;
    case 4:
      return 0xFF6A1B9A;
    case 5:
      return 0xFF37474F;
    case 6:
      return 0xFF00897B;
    case 7:
      return 0xFF42A5F5;
    case 8:
      return 0xFF0D7377;
    case 9:
      return 0xFF455A64;
    case 10:
      return 0xFF5D4037;
    case 11:
      return 0xFF00695C;
    case 12:
      return 0xFF283593;
    default:
      return 0xFF1565C0;
  }
}

/// Bundled ATS templates shipped in-app.
const Set<int> kActiveResumeTemplateIds = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};

String? filledPreviewScreenshotPath(int templateId) => null;

ResumeTemplate? resumeTemplateById(int id) {
  for (final t in resumeTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

/// Debug hot reload keeps widget [State] alive while replacing class layouts; old
/// [ResumeTemplate] instances can throw when reading fields — fall back via fresh bundled copies.
int safeResumeTemplateAccentArgb(ResumeTemplate t) {
  try {
    return t.accentArgb;
  } catch (_) {
    try {
      final id = t.id;
      final fresh = resumeTemplateById(id);
      if (fresh != null) {
        try {
          return fresh.accentArgb;
        } catch (_) {}
      }
      return _defaultAccentArgb(id);
    } catch (_) {
      return _defaultAccentArgb(1);
    }
  }
}

ResumeTemplate resumeTemplateOrDefaultForDraft(int? templateId) {
  if (templateId != null) {
    final found = resumeTemplateById(templateId);
    if (found != null) return found;
  }
  return resumeTemplates.first;
}

List<ResumeTemplate> get resumeFeaturedTemplates => List<ResumeTemplate>.from(resumeTemplates);

/// Distinct ATS layouts — Flutter widgets + structured PDF (no raster templates).
List<ResumeTemplate> resumeTemplates = [
  ResumeTemplate(
    id: 1,
    name: 'Minimal ATS',
    description: 'Single-column flow with generous whitespace—optimized for parsers and human readers alike.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'minimal',
    builderKey: ResumeBuilderIds.minimalAts,
    accentArgb: _defaultAccentArgb(1),
    designVariant: 1,
  ),
  ResumeTemplate(
    id: 2,
    name: 'Modern Professional',
    description: 'Accent panel header with structured sections—polished like premium SaaS résumé builders.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'professional',
    builderKey: ResumeBuilderIds.modernProfessional,
    accentArgb: _defaultAccentArgb(2),
    designVariant: 2,
  ),
  ResumeTemplate(
    id: 3,
    name: 'Corporate Blue',
    description: 'Formal hierarchy with underline cadence—finance, consulting, and enterprise-ready.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'professional',
    builderKey: ResumeBuilderIds.corporateBlue,
    accentArgb: _defaultAccentArgb(3),
    designVariant: 3,
  ),
  ResumeTemplate(
    id: 4,
    name: 'Creative Clean',
    description: 'Bold accent rail without graphics clutter—creative roles that still need ATS compliance.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'creative',
    builderKey: ResumeBuilderIds.creativeClean,
    accentArgb: _defaultAccentArgb(4),
    designVariant: 4,
  ),
  ResumeTemplate(
    id: 5,
    name: 'Executive Resume',
    description: 'Wide headline with executive summary placement—leadership & board-facing narratives.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'executive',
    builderKey: ResumeBuilderIds.executiveResume,
    accentArgb: _defaultAccentArgb(5),
    designVariant: 5,
  ),
  ResumeTemplate(
    id: 6,
    name: 'Fresher Resume',
    description: 'Education-forward ordering with compact skills rail—campus hiring optimized.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'entry',
    builderKey: ResumeBuilderIds.fresherResume,
    accentArgb: _defaultAccentArgb(6),
    designVariant: 6,
  ),
  ResumeTemplate(
    id: 7,
    name: 'Dark Professional',
    description: 'Glassmorphism-inspired preview panels—toggle dark sheet mode for dramatic reviews.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'modern',
    builderKey: ResumeBuilderIds.darkProfessional,
    accentArgb: _defaultAccentArgb(7),
    designVariant: 7,
  ),
  ResumeTemplate(
    id: 8,
    name: 'Two Column Resume',
    description: 'Sidebar for contact & skills, main column for narrative—classic recruiter-friendly split.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'professional',
    builderKey: ResumeBuilderIds.twoColumnResume,
    accentArgb: _defaultAccentArgb(8),
    designVariant: 8,
  ),
  ResumeTemplate(
    id: 9,
    name: 'Compact ATS',
    description: 'Tighter leading for dense careers—still plain text, linear, and PDF-export safe.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'minimal',
    builderKey: ResumeBuilderIds.compactAts,
    accentArgb: _defaultAccentArgb(9),
    designVariant: 9,
  ),
  ResumeTemplate(
    id: 10,
    name: 'Elegant Modern',
    description: 'Portrait rhythm with serif-friendly headings—pair with Merriweather in studio settings.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'modern',
    builderKey: ResumeBuilderIds.elegantModern,
    accentArgb: _defaultAccentArgb(10),
    designVariant: 10,
  ),
  ResumeTemplate(
    id: 11,
    name: 'ATS Classic',
    description: 'Traditional recruiter-first hierarchy with balanced spacing and fast scanning.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'classic',
    builderKey: ResumeBuilderIds.corporateBlue,
    accentArgb: _defaultAccentArgb(11),
    designVariant: 11,
  ),
  ResumeTemplate(
    id: 12,
    name: 'Leadership Focus',
    description: 'Executive-style layout tuned for senior summaries, impact bullets, and outcomes.',
    thumbnail: 'assets/templates/dynamic.png',
    sections: _kDefaultSections,
    category: 'executive',
    builderKey: ResumeBuilderIds.executiveResume,
    accentArgb: _defaultAccentArgb(12),
    designVariant: 12,
  ),
];
