import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import 'package_purchase_history_screen.dart';

/// Job-seeker plans for **job applications** only (catalog from API). Resume builder + AI are free.
class JobSeekerPackagesScreen extends StatefulWidget {
  const JobSeekerPackagesScreen({super.key});

  @override
  State<JobSeekerPackagesScreen> createState() =>
      _JobSeekerPackagesScreenState();
}

class _JobSeekerPackagesScreenState extends State<JobSeekerPackagesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _catalog = [];
  SeekerProfileSummary? _profile;
  /// all | job_applications | resume | combo
  String _filter = 'all';

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
      final cat = [
        {
          'key': 'basic_resume',
          'title': '🥉 Basic Resume Package',
          'description': 'Perfect for job seekers getting started.',
          'price_inr': 99,
          'duration_days': 30,
          'features': [
            'Access to 4 Professional Resume Templates',
            'Easy Resume Editing',
            'PDF Download',
            '30 Days Access',
          ],
        },
        {
          'key': 'premium_resume',
          'title': '🥈 Premium Resume Package',
          'description': 'Ideal for professionals looking for more options.',
          'price_inr': 299,
          'duration_days': 90,
          'features': [
            'Access to 8 Professional Resume Templates',
            'Unlimited Resume Editing',
            'PDF Download',
            'Cover Letter Template Included',
            '90 Days Access',
          ],
        },
        {
          'key': 'professional_resume',
          'title': '🥇 Professional Resume Package',
          'description': 'The complete career package for serious job seekers.',
          'price_inr': 499,
          'duration_days': 180,
          'features': [
            'Access to All 12 Premium Resume Templates',
            'Unlimited Resume Editing',
            'Unlimited PDF Downloads',
            'Premium Cover Letter Templates',
            'Priority Customer Support',
            '180 Days (6 Months) Access',
          ],
        },
      ];
      final prof = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      setState(() {
        _catalog = cat;
        _profile = SeekerProfileSummary.fromJson(prof);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _intVal(Map<String, dynamic> row, String k, [String? alt]) {
    final v = row[k] ?? (alt != null ? row[alt] : null);
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  int? _optionalInt(Map<String, dynamic> row, String k) {
    if (!row.containsKey(k) || row[k] == null) return null;
    final v = row[k];
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  String _kind(Map<String, dynamic> row) =>
      row['kind']?.toString() ?? 'resume';

  List<Map<String, dynamic>> get _filtered {
    return _catalog;
  }

  Future<void> _confirmPurchase(Map<String, dynamic> row) async {
    final title = row['title']?.toString() ?? 'Package';
    final price = _intVal(row, 'price_inr');
    final key = row['key']?.toString() ?? '';
    if (key.isEmpty) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text(
          'Activate “$title” for ₹$price?\n\n'
          'This is a demo — no real payment is processed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await _select(key);
  }

  Future<void> _select(String packageKey) async {
    try {
      await JobSeekerApiService.instance.selectPackage(packageKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package activated. Your credits are updated.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plans & packages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Purchase history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PackagePurchaseHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text(
                        'Resume Packages',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a resume package to unlock templates and unlimited exports. Applying to jobs is completely free!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Applying to jobs is completely free! Pick a resume package to unlock premium templates and options.',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No packages available.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._filtered.map((row) {
                          final kind = _kind(row);
                          final featured = row['key']?.toString() == 'premium_resume';
                          final features = List<String>.from(row['features'] ?? []);
                          return _PackageCard(
                            title: row['title']?.toString() ?? '',
                            description: row['description']?.toString(),
                            kind: kind,
                            listPriceInr: _optionalInt(row, 'list_price_inr'),
                            priceInr: _intVal(row, 'price_inr'),
                            features: features,
                            durationDays: _intVal(row, 'duration_days'),
                            featured: featured,
                            onSelect: () => _confirmPurchase(row),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    this.description,
    required this.kind,
    this.listPriceInr,
    required this.priceInr,
    required this.features,
    required this.durationDays,
    required this.featured,
    required this.onSelect,
  });

  final String title;
  final String? description;
  final String kind;
  final int? listPriceInr;
  final int priceInr;
  final List<String> features;
  final int durationDays;
  final bool featured;
  final VoidCallback onSelect;

  IconData get _kindIcon {
    return Icons.description_rounded;
  }

  String get _kindLabel {
    return 'Resume';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bg = featured ? const Color(0xFFFFF9E6) : AppColors.surface;
    final border = featured
        ? const Color(0xFFF59E0B)
        : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: featured ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(
              _kindIcon,
              size: 36,
              color: featured ? const Color(0xFFD97706) : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (featured ? const Color(0xFFD97706) : AppColors.primary).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _kindLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: featured ? const Color(0xFFD97706) : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null && description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            if (listPriceInr != null &&
                listPriceInr! > 0 &&
                listPriceInr! > priceInr) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹ $listPriceInr',
                    style: textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₹ $priceInr',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Limited offer',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.3,
                ),
              ),
            ] else
              Text(
                '₹ $priceInr',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        'Valid for $durationDays days after activation',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: featured
                  ? FilledButton(
                      onPressed: onSelect,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Purchase (demo)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onSelect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Purchase (demo)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
