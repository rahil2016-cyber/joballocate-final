import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/employer_status_labels.dart';
import '../../services/app_session.dart';
import '../../services/company_api_service.dart';
import '../../services/banner_api_service.dart';
import '../../models/banner.dart' as banner_model;
import '../../utils/app_colors.dart';
import '../../constants/industry_types.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/banner_carousel.dart';
import 'post_job_screen.dart';

/// Loads company jobs + stats from API. Call [reload] after posting a job.
class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  State<EmployerDashboardPage> createState() => EmployerDashboardPageState();
}

class EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final _api = CompanyApiService.instance;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _jobs = [];
  List<banner_model.PromoBanner> _banners = [];

  int _published = 0;
  int _pendingReview = 0;
  int _totalApplications = 0;
  int _shortlisted = 0;
  int _hired = 0;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    load();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerApiService.instance.getActiveBanners();
      if (mounted) {
        // Use mock banners if no banners from API for testing
        List<banner_model.PromoBanner> finalBanners = banners;
        if (finalBanners.isEmpty) {
          finalBanners = _getMockBanners();
        }
        setState(() => _banners = finalBanners);
      }
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        // Use mock banners on error
        setState(() => _banners = _getMockBanners());
      }
    }
  }

  List<banner_model.PromoBanner> _getMockBanners() {
    return [
      banner_model.PromoBanner(
        id: '1',
        title: 'Post Your First Job Today',
        subtitle: 'Reach thousands of qualified candidates instantly',
        imageUrl: null,
        backgroundColor: '#F59E0B',
        textColor: '#FFFFFF',
        buttonText: 'Post Now',
        buttonLink: '',
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: null,
      ),
      banner_model.PromoBanner(
        id: '2',
        title: 'Premium Hiring Package',
        subtitle: 'Get featured jobs and priority support',
        imageUrl: null,
        backgroundColor: '#8B5CF6',
        textColor: '#FFFFFF',
        buttonText: 'Learn More',
        buttonLink: '',
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: null,
      ),
    ];
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _api.getProfile();
      final res = await _api.listJobPosts(perPage: 50);
      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      var published = 0;
      var pending = 0;
      var appsTotal = 0;
      var short = 0;
      var hired = 0;

      for (final j in items) {
        final s = j['status']?.toString() ?? '';
        if (s == 'published') published++;
        if (s == 'pending_review') pending++;
      }

      final jobIds = <int>[];
      for (final j in items) {
        final raw = j['id'];
        final id = raw is int ? raw : int.tryParse(raw.toString());
        if (id != null) jobIds.add(id);
      }
      for (final id in jobIds) {
        try {
          final ar = await _api.listApplications(id, perPage: 100);
          final n = ar['total'] as int? ?? 0;
          appsTotal += n;
          final appItems =
              (ar['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          for (final a in appItems) {
            final st = a['status']?.toString() ?? '';
            if (st == 'shortlisted') short++;
            if (st == 'hired') hired++;
          }
        } catch (_) {
          // ignore per-job errors
        }
      }

      if (!mounted) return;
      setState(() {
        _company = profile;
        _jobs = items;
        _published = published;
        _pendingReview = pending;
        _totalApplications = appsTotal;
        _shortlisted = short;
        _hired = hired;
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

  Future<void> _confirmCloseJob(Map<String, dynamic> j) async {
    final raw = j['id'];
    final id = raw is int ? raw : int.tryParse(raw.toString());
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close posting?'),
        content: const Text(
          'This job will no longer appear on the public board. Applicants you already have stay in “Applicants”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.updateJobPost(id, {'status': 'closed'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Job closed.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not close job: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String get _greetingName {
    final u = AppSession.user;
    if (u != null && u['name'] != null) return u['name'].toString();
    return 'there';
  }

  String get _companyName =>
      _company?['name']?.toString() ?? 'Your company';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppLogo(showText: true, color: AppColors.accent),
                          const SizedBox(height: 12),
                          Text(
                            'Hi, $_greetingName 👋',
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _companyName,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your hiring pipeline.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_banners.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: BannerCarousel(banners: _banners),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'Published',
                        value: '$_published',
                        icon: Icons.work_rounded,
                        color: AppColors.primary,
                        bg: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _statCard(
                        title: 'Applications',
                        value: '$_totalApplications',
                        icon: Icons.description_rounded,
                        color: AppColors.accent,
                        bg: AppColors.accentLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        title: 'Pending review',
                        value: '$_pendingReview',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.orange,
                        bg: Colors.orange.withOpacity(0.12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _statCard(
                        title: 'Shortlisted',
                        value: '$_shortlisted',
                        icon: Icons.star_rounded,
                        color: Colors.deepOrange,
                        bg: Colors.deepOrange.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: _statCard(
                  title: 'Hired',
                  value: '$_hired',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                  bg: AppColors.success.withOpacity(0.12),
                  fullWidth: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Text(
                  'Your jobs',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_jobs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Text(
                    'No jobs yet. Tap Post Job to create one.',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _jobCard(_jobs[i]),
                  childCount: _jobs.length.clamp(0, 15),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
    bool fullWidth = false,
  }) {
    final child = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (fullWidth) return child;
    return child;
  }

  Widget _jobCard(Map<String, dynamic> j) {
    final title = j['title']?.toString() ?? 'Job';
    final industryKey = j['industry_type']?.toString();
    final loc = j['location']?.toString() ?? '';
    final status = j['status']?.toString() ?? '';
    final created = j['created_at']?.toString();
    final days = _daysAgo(created);

    DateTime? deadline;
    final rawDl = j['application_deadline_at']?.toString();
    if (rawDl != null && rawDl.isNotEmpty) {
      deadline = DateTime.tryParse(rawDl)?.toLocal();
    }
    final rawMax = j['max_applications'];
    final maxCap = rawMax is int
        ? rawMax
        : int.tryParse(rawMax?.toString() ?? '');
    final rawCnt = j['applications_count'];
    final appCount = rawCnt is int
        ? rawCnt
        : int.tryParse(rawCnt?.toString() ?? '') ?? 0;

    final isPublished = status == JobPostStatusValue.published;
    final isPending = status == JobPostStatusValue.pendingReview;
    final canEdit =
        status != JobPostStatusValue.closed && status != JobPostStatusValue.rejected;
    final canClose = status == JobPostStatusValue.published ||
        status == JobPostStatusValue.pendingReview ||
        status == JobPostStatusValue.draft;
    final statusLabel = JobPostStatusValue.label(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_rounded, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (industryKey != null && industryKey.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    industryTypeLabel(industryKey),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  [if (loc.isNotEmpty) loc, if (days != null) '$days ago']
                      .join(' • '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (deadline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Apply by ${DateFormat('MMM d, y • HH:mm').format(deadline)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (maxCap != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Applicants: $appCount / $maxCap · auto-closes when full',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canEdit || canClose) ...[
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => PostJobScreen(existingJob: j),
                    ),
                  );
                  if (changed == true && mounted) load();
                } else if (value == 'close') {
                  await _confirmCloseJob(j);
                }
              },
              itemBuilder: (context) => [
                if (canEdit)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (canClose)
                  const PopupMenuItem(
                    value: 'close',
                    child: Text('Close posting'),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPublished
                  ? AppColors.success.withOpacity(0.12)
                  : isPending
                      ? Colors.orange.withOpacity(0.12)
                      : AppColors.textHint.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPublished
                    ? AppColors.success
                    : isPending
                        ? Colors.orange
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _daysAgo(String? iso) {
    if (iso == null) return null;
    try {
      final t = DateTime.tryParse(iso);
      if (t == null) return null;
      final d = DateTime.now().difference(t).inDays;
      if (d <= 0) return 'today';
      return '${d}d';
    } catch (_) {
      return null;
    }
  }
}
