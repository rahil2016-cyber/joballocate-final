/// `GET /companies/top` row.
class TopCompany {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final int openJobsCount;
  /// Admin “spotlight” — shown first in the carousel.
  final bool isTopCompany;

  TopCompany({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    required this.openJobsCount,
    this.isTopCompany = false,
  });

  factory TopCompany.fromApi(Map<String, dynamic> json) {
    final logo = json['company_logo_url']?.toString() ??
        json['logo_url']?.toString();
    final oc = json['open_jobs_count'];
    final top = json['is_top_company'];
    return TopCompany(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Company',
      slug: json['slug']?.toString() ?? '',
      logoUrl: (logo != null && logo.isNotEmpty) ? logo : null,
      openJobsCount: oc is int ? oc : int.tryParse(oc?.toString() ?? '0') ?? 0,
      isTopCompany: top == true || top == 1 || top == '1',
    );
  }
}
