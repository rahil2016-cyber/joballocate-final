class Resume {
  final String id;
  final String userId;
  final String templateId;
  final String title;
  final Map<String, dynamic> content;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Resume({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.title,
    required this.content,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    final created = json['created_at']?.toString();
    final updated = json['updated_at']?.toString();
    return Resume(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      templateId: json['template_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'] as Map)
          : {},
      isDefault: json['is_default'] == true,
      createdAt: created != null && created.isNotEmpty
          ? (DateTime.tryParse(created) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: updated != null && updated.isNotEmpty
          ? (DateTime.tryParse(updated) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'title': title,
      'content': content,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
