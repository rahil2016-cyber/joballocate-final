import 'package:flutter/material.dart';
import '../../models/seeker_profile.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import 'package_purchase_history_screen.dart';

/// Unified job-seeker plans: job applications, resume credits, combos (catalog from API / DB).
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
      final cat = await JobSeekerApiService.instance.getPackageCatalog();
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

  String _kind(Map<String, dynamic> row) =>
      row['kind']?.toString() ?? 'job_applications';

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _catalog;
    return _catalog.where((r) => _kind(r) == _filter).toList();
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
                        'Job applications & resume',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick a plan for applying to jobs, resume exports, or both. '
                        'Catalog comes from the server — admins can change packages later.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Jobs',
                              selected: _filter == 'job_applications',
                              onTap: () =>
                                  setState(() => _filter = 'job_applications'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Resume',
                              selected: _filter == 'resume',
                              onTap: () => setState(() => _filter = 'resume'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Combo',
                              selected: _filter == 'combo',
                              onTap: () => setState(() => _filter = 'combo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_profile != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _profile!.canApply || _profile!.canBuildResume
                                ? AppColors.accentLight
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _profile!.canApply ||
                                      _profile!.canBuildResume
                                  ? AppColors.accent.withOpacity(0.35)
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _profile!.canApply || _profile!.canBuildResume
                                    ? Icons.verified_rounded
                                    : Icons.info_outline_rounded,
                                color: _profile!.canApply ||
                                        _profile!.canBuildResume
                                    ? AppColors.accent
                                    : Colors.orange.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _profile!.statusLine,
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
                      ],
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No packages in this category.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ..._filtered.map((row) {
                          final apps = _intVal(
                              row, 'applications_included', 'applications');
                          final resumes =
                              _intVal(row, 'resume_builds_included');
                          final kind = _kind(row);
                          final featured = row['key']?.toString() == 'standard';
                          return _PackageCard(
                            title: row['title']?.toString() ?? '',
                            description: row['description']?.toString(),
                            kind: kind,
                            priceInr: _intVal(row, 'price_inr'),
                            applications: apps,
                            resumeBuilds: resumes,
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
    required this.priceInr,
    required this.applications,
    required this.resumeBuilds,
    required this.durationDays,
    required this.featured,
    required this.onSelect,
  });

  final String title;
  final String? description;
  final String kind;
  final int priceInr;
  final int applications;
  final int resumeBuilds;
  final int durationDays;
  final bool featured;
  final VoidCallback onSelect;

  IconData get _kindIcon {
    switch (kind) {
      case 'resume':
        return Icons.description_rounded;
      case 'combo':
        return Icons.inventory_2_rounded;
      default:
        return Icons.send_rounded;
    }
  }

  String get _kindLabel {
    switch (kind) {
      case 'resume':
        return 'Resume';
      case 'combo':
        return 'Combo';
      default:
        return 'Job applications';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bg = featured ? const Color(0xFFFFF4B8) : AppColors.surface;
    final border = featured
        ? const Color(0xFFE6C200)
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
              color: featured ? Colors.black87 : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _kindLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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
            const SizedBox(height: 8),
            Text(
              '₹ $priceInr',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (applications > 0)
                    Text(
                      'Job applications: $applications',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  if (resumeBuilds > 0) ...[
                    if (applications > 0) const SizedBox(height: 6),
                    Text(
                      'Resume builds: $resumeBuilds',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (applications == 0 && resumeBuilds == 0)
                    Text(
                      'Credits defined when you activate (see server package).',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Valid for $durationDays days after activation',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                        backgroundColor: Colors.black87,
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
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black54),
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
