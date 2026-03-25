class ResumeTemplate {
  final int id;
  final String name;
  final String description;
  final String thumbnail;
  final List<String> sections;
  final String category;

  /// Visual style for PDF header + preview (0–3). Defaults from template [id].
  final int designVariant;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.thumbnail,
    required this.sections,
    required this.category,
    int? designVariant,
  }) : designVariant = designVariant ?? (((id - 1) % 4) + 4) % 4;

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final dv = json['design_variant'];
    final variant = dv is int
        ? dv
        : int.tryParse(dv?.toString() ?? '') ?? (((id - 1) % 4) + 4) % 4;
    return ResumeTemplate(
      id: id,
      name: json['name']?.toString() ?? 'Template',
      description: json['description']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      sections: List<String>.from(
        json['sections'] ??
            ['header', 'summary', 'experience', 'education', 'skills'],
      ),
      category: json['category']?.toString() ?? 'professional',
      designVariant: variant.clamp(0, 3),
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
    };
  }
}

/// Curated layouts at the top (2 options). Distinct PDF header styles (ids 1 & 2).
/// Add more ids here when you ship additional provider templates.
List<ResumeTemplate> get resumeFeaturedTemplates {
  final out = <ResumeTemplate>[];
  for (final id in [1, 2]) {
    for (final t in resumeTemplates) {
      if (t.id == id) {
        out.add(t);
        break;
      }
    }
  }
  if (out.isEmpty && resumeTemplates.length >= 2) {
    return [resumeTemplates[0], resumeTemplates[1]];
  }
  if (out.isEmpty && resumeTemplates.isNotEmpty) {
    return [resumeTemplates.first];
  }
  return out;
}

// Built-in library (full grid). Featured picks from here by id.
List<ResumeTemplate> resumeTemplates = [
  ResumeTemplate(
    id: 1,
    name: 'Classic Centered',
    description: 'Clean, centered header with a straightforward single-column layout.',
    thumbnail: 'assets/templates/stockholm.png', // Or update if needed
    sections: ['about_me', 'education', 'work_experience', 'skills'],
    category: 'professional',
    designVariant: 0,
  ),
  ResumeTemplate(
    id: 2,
    name: 'Modern Sidebar',
    description: 'Green banner header with a two-column split layout for easy reading.',
    thumbnail: 'assets/templates/new_york.png',
    sections: ['contact', 'education', 'skills', 'work_experience'],
    category: 'modern',
    designVariant: 1,
  ),
  ResumeTemplate(
    id: 3,
    name: 'Professional Blue',
    description: 'Blue title with right-aligned contact details and structured sections.',
    thumbnail: 'assets/templates/toronto.png',
    sections: ['summary', 'professional_experience', 'education', 'skills', 'interests'],
    category: 'creative',
    designVariant: 2,
  ),
];
