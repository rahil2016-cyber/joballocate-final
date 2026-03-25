import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../models/banner.dart' as banner_model;
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/banner_api_service.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../widgets/job_card.dart';
import '../../widgets/banner_carousel.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';
import 'job_seeker_profile.dart';
import './packages_screen.dart';
import './resume_templates_screen.dart';
import 'saved_jobs_screen.dart';
import 'recommended_jobs_screen.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/industry_type_dropdown.dart';

class JobSeekerHomeScreen extends StatefulWidget {
  const JobSeekerHomeScreen({super.key, this.userId, this.token});

  /// From API login; falls back to demo credentials if null.
  final String? userId;
  final String? token;

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen> {
  int _currentIndex = 0;

  // Demo user credentials (replace with real auth state)
  static const String _demoUserId = 'demo-user';
  static const String _demoToken = 'demo-token';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final uid = widget.userId ?? _demoUserId;
    final tok = widget.token ?? _demoToken;
    _pages = [
      _JobFeedPage(
        userId: uid,
        token: tok,
        onGoToProfileTab: () => setState(() => _currentIndex = 3),
      ),
      const MyApplicationsScreen(),
      SavedJobsScreen(
        userId: uid,
        token: tok,
      ),
      const JobSeekerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Apply',
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'Saved',
                    index: 2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Me',
                    index: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Job Feed Page (Home Tab)
// ==========================================
class _JobFeedPage extends StatefulWidget {
  final String userId;
  final String token;
  final VoidCallback onGoToProfileTab;

  const _JobFeedPage({
    this.userId = 'demo-user',
    this.token = 'demo-token',
    required this.onGoToProfileTab,
  });

  @override
  State<_JobFeedPage> createState() => _JobFeedPageState();
}

class _JobFeedPageState extends State<_JobFeedPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Job> _jobs = [];
  List<Job> _recommendedJobs = [];
  Set<String> _savedJobIds = {};
  /// Job post IDs the logged-in user has already applied to.
  Set<String> _appliedJobIds = {};
  List<banner_model.PromoBanner> _banners = [];
  bool _isLoading = true;
  String? _loadError;
  Timer? _searchDebounce;
  /// `null` = all industries (server-side filter via `GET /jobs?industry_type=`).
  String? _industryFilter;

  /// From API `profile_completion_percent` — hide prompt when ≥ 70.
  int? _profileCompletionPercent;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadJobs();
    _loadRecommendedJobs();
    _refreshAppliedIds();
    _loadSavedJobIds();
    _loadProfileCompletion();
    _searchController.addListener(_onSearchChanged);
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
        title: 'Get Real With Myntra',
        subtitle: 'The 45-Day Quiz. Real Challenges. Real Wins.',
        imageUrl: null,
        backgroundColor: '#FF5B7D',
        textColor: '#FFFFFF',
        buttonText: 'Play Now!',
        buttonLink: 'https://myntra.com',
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: null,
      ),
      banner_model.PromoBanner(
        id: '2',
        title: 'Accelerate Your Career',
        subtitle: 'Exclusive courses and certifications just for you',
        imageUrl: null,
        backgroundColor: '#6366F1',
        textColor: '#FFFFFF',
        buttonText: 'Explore Courses',
        buttonLink: 'https://example.com/courses',
        isActive: true,
        createdAt: DateTime.now(),
        expiresAt: null,
      ),
    ];
  }

  Future<void> _loadRecommendedJobs() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _recommendedJobs = []);
      return;
    }
    try {
      final jobs = await JobSeekerApiService.instance.getRecommendedJobs(perPage: 10);
      if (mounted) {
        setState(() => _recommendedJobs = jobs);
      }
    } catch (_) {
      if (mounted) setState(() => _recommendedJobs = []);
    }
  }

  Future<void> _loadSavedJobIds() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _savedJobIds = {});
      return;
    }
    try {
      final saved = await JobSeekerApiService.instance.listSavedJobs(perPage: 100);
      if (mounted) {
        setState(() {
          _savedJobIds = saved.map((j) => j.id).toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _savedJobIds = {});
    }
  }

  Future<void> _toggleSaveJob(Job job) async {
    try {
      final jobId = int.tryParse(job.id);
      if (jobId == null) return;

      final isSaved = _savedJobIds.contains(job.id);
      if (isSaved) {
        await JobSeekerApiService.instance.unsaveJob(jobId);
      } else {
        await JobSeekerApiService.instance.saveJob(jobId);
      }

      if (mounted) {
        setState(() {
          if (isSaved) {
            _savedJobIds.remove(job.id);
          } else {
            _savedJobIds.add(job.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _loadProfileCompletion() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _profileCompletionPercent = null);
      return;
    }
    try {
      final raw = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      final p = raw['profile_completion_percent'];
      final pct = p is int ? p : int.tryParse(p?.toString() ?? '');
      setState(() => _profileCompletionPercent = pct);
    } catch (_) {
      if (mounted) setState(() => _profileCompletionPercent = null);
    }
  }

  Future<void> _refreshAppliedIds() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _appliedJobIds = {});
      return;
    }
    try {
      final apps =
          await JobSeekerApiService.instance.listMyApplications(perPage: 100);
      final ids = apps.map((a) => a.jobId).toSet();
      if (mounted) setState(() => _appliedJobIds = ids);
    } catch (_) {
      if (mounted) setState(() => _appliedJobIds = {});
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final list = await JobSeekerApiService.instance.listJobs(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        industryType: _industryFilter,
        perPage: 50,
      );
      if (!mounted) return;
      setState(() {
        _jobs = list;
        _isLoading = false;
      });
      await _refreshAppliedIds();
      await _loadProfileCompletion();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _jobs = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    /// Single scroll surface so the keyboard never causes a [Column] overflow.
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await _loadJobs();
          await _loadProfileCompletion();
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppLogo(showText: true),
                              const SizedBox(height: 12),
                              Text(
                                'Hello, ${AppSession.user?['name']?.toString() ?? 'there'} 👋',
                                style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Find your dream job today.',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                _ActionIconButton(
                                  icon: Icons.shopping_bag_rounded,
                                  color: Colors.deepPurple,
                                  tooltip: 'Plans & packages',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const JobSeekerPackagesScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ActionIconButton(
                              icon: Icons.description_rounded,
                              color: Colors.purple,
                              tooltip: 'Resumes',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResumeTemplatesScreen(
                                    userId: widget.userId,
                                    token: widget.token,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_profileCompletionPercent != null &&
                      _profileCompletionPercent! < 70)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: _ProfileBoostCard(
                        percent:
                            _profileCompletionPercent!.clamp(0, 100),
                        onOpenProfile: widget.onGoToProfileTab,
                      ),
                    ),
                  if (_banners.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: BannerCarousel(banners: _banners),
                    ),
                  if (_recommendedJobs.isNotEmpty)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recommended jobs for you',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecommendedJobsScreen(
                                      userId: widget.userId,
                                      token: widget.token,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'View all',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            children: [
                              Text(
                                'You might like (${_recommendedJobs.length})',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Profile',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            itemCount: _recommendedJobs.length,
                            itemBuilder: (context, index) {
                              final job = _recommendedJobs[index];
                              final isSaved = _savedJobIds.contains(job.id);
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _RecommendedJobCard(
                                  job: job,
                                  isSaved: isSaved,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => JobDetailScreen(
                                          job: job,
                                          userId: widget.userId,
                                          token: widget.token,
                                          hasApplied: _appliedJobIds.contains(job.id),
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      await _loadSavedJobIds();
                                    }
                                  },
                                  onBookmark: () => _toggleSaveJob(job),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        scrollPadding: const EdgeInsets.only(bottom: 120),
                        decoration: InputDecoration(
                          hintText: 'Search jobs, skills, companies...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textHint),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textHint, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : const Icon(Icons.tune_rounded,
                                  color: AppColors.primary, size: 22),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: IndustryTypeDropdown(
                      value: _industryFilter,
                      labelText: 'Industry',
                      dense: true,
                      onChanged: (v) {
                        setState(() => _industryFilter = v);
                        _loadJobs();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          '${_jobs.length} jobs found',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Most Recent',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else if (_loadError != null && _jobs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: AppColors.textHint.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load jobs',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loadJobs,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_jobs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: AppColors.textHint.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs found',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try another search or industry filter.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = _jobs[index];
                      return JobCardWidget(
                        job: job,
                        hasApplied: _appliedJobIds.contains(job.id),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(
                                job: job,
                                userId: widget.userId,
                                token: widget.token,
                                hasApplied:
                                    _appliedJobIds.contains(job.id),
                              ),
                            ),
                          );
                          if (mounted) await _refreshAppliedIds();
                        },
                        onApply: () async {
                          final ok =
                              await showApplyJobSheet(context, job);
                          if (ok && mounted) {
                            await _loadJobs();
                            await _refreshAppliedIds();
                          }
                        },
                        onBookmark: () {},
                      );
                    },
                    childCount: _jobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown on home when profile completion is below 70%.
class _ProfileBoostCard extends StatelessWidget {
  const _ProfileBoostCard({
    required this.percent,
    required this.onOpenProfile,
  });

  final int percent;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenProfile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stand out to employers',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your profile is about $percent% complete. Add headline, bio, skills, location & resume to get shortlisted faster.',
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$percent% complete',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Update profile',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recommended job card for horizontal scrolling
class _RecommendedJobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _RecommendedJobCard({
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        job.companyName.isNotEmpty
                            ? job.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBookmark,
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                job.companyName,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (job.salaryMin != null && job.salaryMax != null)
                Text(
                  '₹${job.salaryMin?.toStringAsFixed(0)} - ${job.salaryMax?.toStringAsFixed(0)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.jobType,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper icon button widget
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}