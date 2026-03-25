import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import '../../constants/industry_types.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  final String userId;
  final String token;
  /// From feed when applications list is already loaded.
  final bool hasApplied;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.userId = 'demo-user',
    this.token = 'demo-token',
    this.hasApplied = false,
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
    _refreshJob();
    _syncAppliedFromApi();
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
    final id = int.tryParse(_job.id);
    if (id == null) return;
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
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
                    final jobId = int.tryParse(_job.id);
                    if (jobId == null) return;

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
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded,
                      size: 20, color: Colors.white),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job link copied to clipboard!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      margin: EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                _job.companyName.isNotEmpty
                                    ? _job.companyName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _job.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _job.companyName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          value: _job.location,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.access_time_rounded,
                          title: 'Job Type',
                          value: _job.jobType.replaceAll('_', ' '),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.currency_rupee_rounded,
                          title: 'Salary',
                          value: _job.salaryRange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoTile(
                          icon: Icons.trending_up_rounded,
                          title: 'Experience',
                          value: _job.experienceDisplay,
                        ),
                      ),
                    ],
                  ),
                  if (_job.industryType != null &&
                      _job.industryType!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.category_outlined,
                            title: 'Industry',
                            value: industryTypeLabel(_job.industryType),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('${_job.viewsCount}', 'Views'),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        _buildStatItem(
                            '${_job.applicationsCount}', 'Applied'),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        _buildStatItem(_job.postedAgoLabel, 'Posted'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Skills Required
                  Text(
                    'Skills Required',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _job.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
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
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Job Description
                  Text(
                    'Job Description',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _job.description,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Requirements
                  Text(
                    'Requirements',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _job.requirements.trim().isEmpty
                        ? 'Not specified'
                        : _job.requirements,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                      fontStyle: _job.requirements.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),

                  if (_job.applicationDeadlineAt != null ||
                      _job.maxApplications != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  color: Colors.orange.shade800, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Application window',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          if (_job.applicationDeadlineAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Apply before ${DateFormat('MMM d, y • HH:mm').format(_job.applicationDeadlineAt!)}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (_job.maxApplications != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${_job.applicationsCount} / ${_job.maxApplications} applicants (closes when full)',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Apply Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _job.salaryRange,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'per annum',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasApplied)
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.45)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 22),
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
              else
                SizedBox(
                  height: 52,
                  width: 160,
                  child: ElevatedButton(
                    onPressed: _refreshing
                        ? null
                        : () async {
                            final ok =
                                await showApplyJobSheet(context, _job);
                            if (!ok || !context.mounted) return;
                            if (mounted) setState(() => _hasApplied = true);
                            await _refreshJob();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Application submitted!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
