/// One tile from `GET /seeker-home-popular-categories` (Laravel industry_types + home fields).
class SeekerPopularCategory {
  const SeekerPopularCategory({
    required this.label,
    this.industryType,
    this.search,
    this.iconKey,
    this.accentDot = false,
  });

  final String label;
  final String? industryType;
  final String? search;
  final String? iconKey;
  final bool accentDot;

  static SeekerPopularCategory fromApi(Map<String, dynamic> m) {
    return SeekerPopularCategory(
      label: m['label']?.toString() ?? 'Category',
      industryType: m['industry_type']?.toString(),
      search: m['search']?.toString(),
      iconKey: m['icon']?.toString(),
      accentDot: m['accent_dot'] == true,
    );
  }
}
