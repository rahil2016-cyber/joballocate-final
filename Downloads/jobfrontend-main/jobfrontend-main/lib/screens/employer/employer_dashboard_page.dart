import 'package:flutter/material.dart';
import '../../services/app_session.dart';
import '../../services/company_api_service.dart';
import '../../services/job_share_service.dart';
import '../../services/banner_api_service.dart';
import '../../models/banner.dart' as banner_model;
import '../../utils/app_colors.dart';
import '../../utils/network_user_message.dart';
import '../../widgets/connection_error_panel.dart';
import '../../constants/industry_types.dart';
import '../../constants/employer_status_labels.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/banner_carousel.dart';
import '../../config/useresume_config.dart';
import 'post_job_screen.dart';

/// Employer Dashboard - Optimized for immediate visibility and zero-confusion.
class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  State<EmployerDashboardPage> createState() => EmployerDashboardPageState();
}

class EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final _api = CompanyApiService.instance;

  bool _loading = true;
  Object? _errorCause;
  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _jobs = [];
  List<banner_model.PromoBanner> _banners = [];

  int _published = 0;
  int _pendingReview = 0;
  int _totalApplications = 0;
  int _shortlisted = 0;
  int _hired = 0;

  bool get isVerified =>
      (_company?['verification_status']?.toString() ?? '') ==
      CompanyVerificationValue.verified;

  bool get hasAnyJob => _jobs.isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => load());
  }

  Future<List<banner_model.PromoBanner>> _fetchBanners() async {
    try {
      final banners = await BannerApiService.instance.getActiveBanners();
      return banners;
    } catch (_) {
      return [];
    }
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorCause = null;
    });

    try {
      final profile = await _api.getProfile();
      final res = await _api.listJobPosts(perPage: 50);
      final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      int published = 0;
      int pending = 0;

      for (final j in items) {
        final s = j['status']?.toString() ?? '';
        if (s == 'published') published++;
        if (s == 'pending_review') pending++;
      }

      final banners = await _fetchBanners();

      if (!mounted) return;

      setState(() {
        _company = profile;
        _jobs = items;
        _published = published;
        _pendingReview = pending;
        _banners = banners;
        _loading = false;
      });

      final logo = profile['company_logo_url']?.toString() ??
          profile['company_logo']?.toString();
      if (logo != null && logo.trim().isNotEmpty) {
        AppSession.companyLogoNotifier.value = logo.trim();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCause = e;
        _loading = false;
      });
      if (NetworkUserMessage.looksLikeNetwork(e)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showNetworkIssueAlert(context, error: e, onRetry: load);
        });
      }
    }
  }

  String get _greetingName {
    final u = AppSession.user;
    return u?['name']?.toString() ?? 'there';
  }

  String get _companyName =>
      _company?['name']?.toString() ?? 'Your company';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorCause != null
                ? Material(
                    color: AppColors.background,
                    child: ConnectionErrorPanel(
                      title: () {
                        final d = NetworkUserMessage.describe(_errorCause!);
                        return d?.title ?? 'Unable to load dashboard';
                      }(),
                      message: () {
                        final d = NetworkUserMessage.describe(_errorCause!);
                        return d?.message ??
                            'We could not load your company data. Check your internet connection and try again.';
                      }(),
                      onRetry: load,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        /// HEADER - Premium Compact Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ValueListenableBuilder<String?>(
                                    valueListenable: AppSession.companyLogoNotifier,
                                    builder: (context, logoUrl, _) {
                                      if (logoUrl != null && logoUrl.isNotEmpty) {
                                        return Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              logoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.business, color: AppColors.primary, size: 20),
                                            ),
                                          ),
                                        );
                                      }
                                      return const AppLogo(height: 32);
                                    },
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.notifications_none_outlined, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hi, $_greetingName 👋',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.business_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _companyName,
                                      style: textTheme.titleSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// BANNERS
                        if (_banners.isNotEmpty) ...[
                          BannerCarousel(banners: _banners),
                          const SizedBox(height: 20),
                        ],

                        /// STATS GRID
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _statCard('Published', '$_published', Icons.work_rounded, AppColors.primary, AppColors.primaryLight),
                            _statCard('Pending', '$_pendingReview', Icons.hourglass_top_rounded, Colors.orange, Colors.orange.withOpacity(0.1)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Text(
                          "Recent Postings",
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (_jobs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                "No jobs posted yet",
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ..._jobs.take(10).map((j) => _jobCard(j)).toList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _shareJob(Map<String, dynamic> j) async {
    final id = j['id']?.toString();
    if (id == null || id.isEmpty) return;
    final title = j['title']?.toString() ?? 'Job';
    final location = j['location']?.toString();
    final company = _company?['name']?.toString() ?? 'Our company';
    try {
      await JobShareService.instance.shareJob(
        jobId: id,
        title: title,
        companyName: company,
        location: location,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _jobCard(Map<String, dynamic> j) {
    final title = j['title']?.toString() ?? 'Untitled Job';
    final status = j['status']?.toString() ?? 'draft';
    final isPublished = status == 'published';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PostJobScreen(existingJob: j),
            ),
          );
          if (changed == true && mounted) load();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPublished ? AppColors.success : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPublished)
                IconButton(
                  tooltip: 'Share job',
                  icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
                  onPressed: () => _shareJob(j),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
