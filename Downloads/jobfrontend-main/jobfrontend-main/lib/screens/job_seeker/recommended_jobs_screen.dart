import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/job_card.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';

class RecommendedJobsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const RecommendedJobsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<RecommendedJobsScreen> createState() => _RecommendedJobsScreenState();
}

class _RecommendedJobsScreenState extends State<RecommendedJobsScreen> {
  List<Job> _recommendedJobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isLoading = true;
  String? _loadError;

  final JobSeekerApiService _apiService = JobSeekerApiService.instance;

  @override
  void initState() {
    super.initState();
    _loadRecommendedJobs();
    _refreshAppliedIds();
    _loadSavedJobIds();
  }

  Future<void> _loadRecommendedJobs() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) {
        setState(() {
          _recommendedJobs = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      final jobs = await _apiService.getRecommendedJobs();
      if (mounted) {
        setState(() {
          _recommendedJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAppliedIds() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _appliedJobIds = {});
      return;
    }
    try {
      final apps = await _apiService.listMyApplications();
      if (mounted) {
        setState(() {
          _appliedJobIds = apps.map((a) => a.jobId.toString()).toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _appliedJobIds = {});
    }
  }

  Future<void> _loadSavedJobIds() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) setState(() => _savedJobIds = {});
      return;
    }
    try {
      final saved = await _apiService.listSavedJobs();
      if (mounted) {
        setState(() {
          _savedJobIds = saved.map((j) => j.id).toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _savedJobIds = {});
    }
  }

  Future<void> _saveJob(Job job) async {
    try {
      final jobId = job.id;

      await _apiService.saveJob(jobId);
      if (mounted) {
        setState(() {
          _savedJobIds.add(job.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
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
  }

  Future<void> _unsaveJob(Job job) async {
    try {
      final jobId = job.id;

      await _apiService.unsaveJob(jobId);
      if (mounted) {
        setState(() {
          _savedJobIds.remove(job.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job removed from saved'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
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
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Recommended Jobs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(textTheme),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Finding jobs for you...',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Center(
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
                'Could not load recommendations',
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
                onPressed: _loadRecommendedJobs,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 64,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations yet',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your profile to get personalized job recommendations.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _recommendedJobs.length,
      itemBuilder: (context, index) {
        final job = _recommendedJobs[index];
        final isSaved = _savedJobIds.contains(job.id);
        return JobCardWidget(
          job: job,
          hasApplied: _appliedJobIds.contains(job.id),
          isBookmarked: isSaved,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(
                  job: job,
                  userId: widget.userId,
                  token: widget.token,
                  isBookmarked: isSaved,
                  hasApplied: _appliedJobIds.contains(job.id),
                ),
              ),
            );
            if (mounted) {
              await _refreshAppliedIds();
              await _loadSavedJobIds();
            }
          },
          onApply: () async {
            final ok = await showApplyJobSheet(context, job);
            if (ok && mounted) {
              await _loadRecommendedJobs();
              await _refreshAppliedIds();
            }
          },
          onBookmark: () =>
              isSaved ? _unsaveJob(job) : _saveJob(job),
        );
      },
    );
  }
}
