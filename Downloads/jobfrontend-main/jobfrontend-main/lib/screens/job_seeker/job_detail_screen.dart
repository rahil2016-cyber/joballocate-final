import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/job_share_service.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import '../../constants/industry_types.dart';
import 'similar_jobs_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  final String userId;
  final String token;
  /// From feed when applications list is already loaded.
  final bool hasApplied;
  final bool isBookmarked;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.userId = 'demo-user',
    this.token = 'demo-token',
    this.hasApplied = false,
    this.isBookmarked = false,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isBookmarked = false;
  late Job _job;
  bool _refreshing = false;
  late bool _hasApplied;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _hasApplied = widget.hasApplied;
    _isBookmarked = widget.isBookmarked;
    _refreshJob();
    _syncAppliedFromApi();
    _syncSavedStatusFromApi();
  }

  Future<void> _syncSavedStatusFromApi() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final saved = await JobSeekerApiService.instance.listSavedJobs(perPage: 100);
      final hit = saved.any((j) => j.id == _job.id);
      if (mounted) setState(() => _isBookmarked = hit);
    } catch (_) {}
  }

  Future<void> _syncAppliedFromApi() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final apps =
          await JobSeekerApiService.instance.listMyApplications(perPage: 100);
      final hit = apps.any((a) => a.jobId == _job.id);
      if (mounted) setState(() => _hasApplied = hit);
    } catch (_) {}
  }

  Future<void> _refreshJob() async {
    final id = _job.id;
    setState(() => _refreshing = true);
    try {
      final j = await JobSeekerApiService.instance.getJob(id);
      if (mounted) setState(() => _job = j);
    } catch (_) {
      // keep passed-in job
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _shareJob() async {
    try {
      await JobShareService.instance.shareJob(
        jobId: _job.id,
        title: _job.title,
        companyName: _job.companyName,
        location: _job.location,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3, // Job Details, About Company, Salaries
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Job Details',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _isBookmarked ? AppColors.primary : AppColors.textPrimary,
                size: 24,
              ),
              onPressed: () async {
                if (!AppSession.isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to save jobs'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    ),
                  );
                  return;
                }

                try {
                  final jobId = _job.id;

                  if (_isBookmarked) {
                    await JobSeekerApiService.instance.unsaveJob(jobId);
                  } else {
                    await JobSeekerApiService.instance.saveJob(jobId);
                  }

                  if (mounted) {
                    setState(() => _isBookmarked = !_isBookmarked);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isBookmarked ? 'Job saved!' : 'Job removed from saved',
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
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
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 24),
              onPressed: () => _shareJob(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildHeader(textTheme),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Job Details'),
                Tab(text: 'About Company'),
                Tab(text: 'Salaries'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildJobDetailsTab(textTheme),
                  _buildAboutCompanyTab(textTheme),
                  _buildSalariesTab(textTheme),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(textTheme),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: _job.companyLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: _job.companyLogoUrl!,
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                _job.companyName.isNotEmpty ? _job.companyName[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          _job.companyName.isNotEmpty ? _job.companyName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _job.title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _job.companyName,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '${_job.applicationsCount} applicants',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _job.postedAgoLabel,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetailsTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHighlightsCard(textTheme),
        const SizedBox(height: 24),
        Text(
          'Job description',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          'What you\'ll do',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          _job.description,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 24),
        if (_job.requirements.trim().isNotEmpty) ...[
          Text(
            'Requirements',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            _job.requirements,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
        if (_job.skills.isNotEmpty) ...[
          Text(
            'Skills Required',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _job.skills.map((skill) => _buildSkillChip(skill)).toList(),
          ),
          const SizedBox(height: 28),
        ],
        _buildDisclaimerCard(textTheme),
        const SizedBox(height: 24),
        _buildRoleDetails(textTheme),
        const SizedBox(height: 24),
        _buildWarningCard(textTheme),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHighlightsCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job highlights',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildHighlightItem(Icons.work_outline_rounded, '${_job.experienceDisplay} Yrs'),
          const SizedBox(height: 12),
          _buildHighlightItem(Icons.people_outline_rounded, '1 Opening'),
          const SizedBox(height: 12),
          _buildHighlightItem(Icons.location_on_outlined, 'Hiring office located in ${_job.location.isEmpty ? "REMOTE" : _job.location}'),
          const SizedBox(height: 12),
          _buildHighlightItem(Icons.currency_rupee_rounded, _job.salaryRange),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Disclaimer: This job posting has been aggregated from external source. Role details, content, and availability are subject to change. Applicants are advised to confirm the latest information directly on the company website before applying.',
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildWarningCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Safety Notice',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Disclaimer: No company and consultancy will ask for money. Fraudsters may ask you to pay under the pretext of registration fee, refundable fee etc.',
            style: TextStyle(
              color: Colors.orange.shade900,
              height: 1.45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDetails(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_job.industryType != null && _job.industryType!.isNotEmpty)
          _buildRoleDetailRow('Industry type', industryTypeLabel(_job.industryType)),
        if (_job.functionalArea != null && _job.functionalArea!.isNotEmpty)
          _buildRoleDetailRow('Functional area', _job.functionalArea!),
        _buildRoleDetailRow('Role', _job.title),
        if (_job.roleCategory != null && _job.roleCategory!.isNotEmpty)
          _buildRoleDetailRow('Role category', _job.roleCategory!),
        _buildRoleDetailRow('Employment type', _job.jobType.replaceAll('_', ' ').toUpperCase()),
        if (_job.education != null && _job.education!.isNotEmpty)
          _buildRoleDetailRow('Education', _job.education!),
      ],
    );
  }

  Widget _buildRoleDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCompanyTab(TextTheme textTheme) {
    final about = _job.aboutCompany ?? '';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'About ${_job.companyName}',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Text(
          about.trim().isEmpty ? 'No description available for this company.' : about,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildSalariesTab(TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Salary Details',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salary Range',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _job.salaryRange,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_job.benefits != null && _job.benefits!.trim().isNotEmpty) ...[
          Text(
            'Benefits & Perks',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildBulletList(_job.benefits!, textTheme),
          const SizedBox(height: 24),
        ],
        if (_job.salaryInsights != null && _job.salaryInsights!.trim().isNotEmpty) ...[
          Text(
            'Salary Insights',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildBulletList(_job.salaryInsights!, textTheme),
        ],
      ],
    );
  }

  Widget _buildBulletList(String text, TextTheme textTheme) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final lines = text
        .split(RegExp(r'\n|,'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  line,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }

  Widget _buildBottomBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                label: const Text(
                  'Similar jobs',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SimilarJobsScreen(
                        job: _job,
                        userId: widget.userId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: _hasApplied
                  ? Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withOpacity(0.45)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Applied',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _refreshing
                            ? null
                            : () async {
                                final ok = await showApplyJobSheet(context, _job);
                                if (!ok || !context.mounted) return;
                                if (mounted) setState(() => _hasApplied = true);
                                await _refreshJob();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
