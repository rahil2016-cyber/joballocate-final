class PromoBanner {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? backgroundColor;
  final String? textColor;
  final String? buttonText;
  final String? buttonLink;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  PromoBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
    this.buttonText,
    this.buttonLink,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString(),
      backgroundColor: json['background_color']?.toString(),
      textColor: json['text_color']?.toString(),
      buttonText: json['button_text']?.toString(),
      buttonLink: json['button_link']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'background_color': backgroundColor,
      'text_color': textColor,
      'button_text': buttonText,
      'button_link': buttonLink,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
