import 'package:flutter/material.dart';

import '../models/seeker_popular_category.dart';
import '../services/job_seeker_api_service.dart';
import '../screens/job_seeker/category_browse_screen.dart';
import '../utils/app_colors.dart';
import '../constants/industry_types.dart';

IconData popularCategoryIcon(String? iconKey) {
  switch (iconKey) {
    case 'account_balance_rounded':
      return Icons.account_balance_rounded;
    case 'computer_rounded':
      return Icons.computer_rounded;
    case 'phone_in_talk_rounded':
      return Icons.phone_in_talk_rounded;
    case 'show_chart_rounded':
      return Icons.show_chart_rounded;
    case 'work_outline_rounded':
      return Icons.work_outline_rounded;
    case 'home_work_rounded':
      return Icons.home_work_rounded;
    case 'engineering_rounded':
      return Icons.engineering_rounded;
    case 'local_hospital_rounded':
      return Icons.local_hospital_rounded;
    case 'school_rounded':
      return Icons.school_rounded;
    case 'gavel_rounded':
      return Icons.gavel_rounded;
    case 'support_agent_rounded':
      return Icons.support_agent_rounded;
    case 'precision_manufacturing_rounded':
      return Icons.precision_manufacturing_rounded;
    case 'analytics_rounded':
      return Icons.analytics_rounded;
    case 'palette_rounded':
      return Icons.palette_rounded;
    case 'campaign_rounded':
      return Icons.campaign_rounded;
    default:
      return Icons.category_outlined;
  }
}

class CategoryColorTheme {
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  CategoryColorTheme({
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
  });
}

CategoryColorTheme _getCategoryTheme(int index, String? key) {
  final k = (key ?? '').toLowerCase();
  if (k.contains('software') || k.contains('engineering') || k.contains('it') || k.contains('computer')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFEFF6FF),
      iconBackgroundColor: const Color(0xFFDBEAFE),
      iconColor: const Color(0xFF2563EB),
    );
  } else if (k.contains('data') || k.contains('analytics') || k.contains('science')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFF0FDF4),
      iconBackgroundColor: const Color(0xFFDCFCE7),
      iconColor: const Color(0xFF16A34A),
    );
  } else if (k.contains('design') || k.contains('ux') || k.contains('creative') || k.contains('art') || k.contains('palette')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFFAF5FF),
      iconBackgroundColor: const Color(0xFFF3E8FF),
      iconColor: const Color(0xFF7C3AED),
    );
  } else if (k.contains('product') || k.contains('management')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFFDF2F8),
      iconBackgroundColor: const Color(0xFFFCE7F3),
      iconColor: const Color(0xFFDB2777),
    );
  } else if (k.contains('sales') || k.contains('business') || k.contains('dev')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFFEFCE8),
      iconBackgroundColor: const Color(0xFFFEF08A),
      iconColor: const Color(0xFFCA8A04),
    );
  } else if (k.contains('marketing') || k.contains('digital') || k.contains('growth') || k.contains('campaign')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFFEF2F2),
      iconBackgroundColor: const Color(0xFFFEE2E2),
      iconColor: const Color(0xFFDC2626),
    );
  } else if (k.contains('banking') || k.contains('finance')) {
    return CategoryColorTheme(
      backgroundColor: const Color(0xFFEFF6FF),
      iconBackgroundColor: const Color(0xFFDBEAFE),
      iconColor: const Color(0xFF2563EB),
    );
  }

  switch (index % 6) {
    case 0:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFEFF6FF),
        iconBackgroundColor: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF2563EB),
      );
    case 1:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFF0FDF4),
        iconBackgroundColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      );
    case 2:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFFAF5FF),
        iconBackgroundColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7C3AED),
      );
    case 3:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFFDF2F8),
        iconBackgroundColor: const Color(0xFFFCE7F3),
        iconColor: const Color(0xFFDB2777),
      );
    case 4:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFFEFCE8),
        iconBackgroundColor: const Color(0xFFFEF08A),
        iconColor: const Color(0xFFCA8A04),
      );
    default:
      return CategoryColorTheme(
        backgroundColor: const Color(0xFFFEF2F2),
        iconBackgroundColor: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      );
  }
}

class PopularCategoriesSection extends StatefulWidget {
  const PopularCategoriesSection({
    super.key,
    required this.userId,
    required this.token,
  });

  final String userId;
  final String token;

  @override
  State<PopularCategoriesSection> createState() => _PopularCategoriesSectionState();
}

class _PopularCategoriesSectionState extends State<PopularCategoriesSection> {
  List<SeekerPopularCategory> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await JobSeekerApiService.instance.listSeekerHomePopularCategories();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openCategory(BuildContext context, SeekerPopularCategory item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryBrowseScreen(
          title: item.label,
          userId: widget.userId,
          token: widget.token,
          industryType: item.industryType,
          search: item.search,
        ),
      ),
    );
  }

  void _showAllCategoriesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'All Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: kIndustryTypes.length,
                itemBuilder: (context, index) {
                  final ind = kIndustryTypes[index];
                  final theme = _getCategoryTheme(index, ind.key);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: theme.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CategoryBrowseScreen(
                              title: ind.label,
                              userId: widget.userId,
                              token: widget.token,
                              industryType: ind.key,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.iconBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          popularCategoryIcon(ind.key == 'software_engineering_it'
                              ? 'computer_rounded'
                              : (ind.key == 'data_science_analytics'
                                  ? 'analytics_rounded'
                                  : (ind.key == 'design_ux_creative'
                                      ? 'palette_rounded'
                                      : (ind.key == 'marketing_digital_growth'
                                          ? 'campaign_rounded'
                                          : 'work_outline_rounded')))),
                          color: theme.iconColor,
                        ),
                      ),
                      title: Text(
                        ind.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Popular Categories',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Could not load categories. Pull to refresh.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                )
              else if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No categories yet.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final theme = _getCategoryTheme(index, item.industryType ?? item.label);
                    return _CategoryCell(
                      label: item.label,
                      icon: popularCategoryIcon(item.iconKey),
                      accentDot: item.accentDot,
                      theme: theme,
                      onTap: () => _openCategory(context, item),
                    );
                  }),
                ),
              if (_items.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showAllCategoriesSheet(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'View All',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.accentDot = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final CategoryColorTheme theme;
  final bool accentDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: theme.iconColor),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
