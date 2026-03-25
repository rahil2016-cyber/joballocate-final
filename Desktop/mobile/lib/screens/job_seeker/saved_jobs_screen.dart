import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/job_card.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';
import '../../widgets/apply_job_sheet.dart';

class SavedJobsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const SavedJobsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  List<Job> _savedJobs = [];
  Set<String> _appliedJobIds = {};
  bool _isLoading = true;
  String? _loadError;

  final JobSeekerApiService _apiService = JobSeekerApiService.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
    _refreshAppliedIds();
  }

  Future<void> _loadSavedJobs() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) {
        setState(() {
          _savedJobs = [];
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
      final jobs = await _apiService.listSavedJobs();
      if (mounted) {
        setState(() {
          _savedJobs = jobs;
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

  Future<void> _unsaveJob(Job job) async {
    try {
      final jobId = int.tryParse(job.id);
      if (jobId == null) return;

      await _apiService.unsaveJob(jobId);
      if (mounted) {
        setState(() {
          _savedJobs.removeWhere((j) => j.id == job.id);
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Saved Jobs',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Saved Jobs',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
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
                  'Could not load saved jobs',
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
                  onPressed: _loadSavedJobs,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_savedJobs.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Saved Jobs',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 64,
                color: AppColors.textHint.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No saved jobs yet',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bookmark jobs you like to save them here.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Saved Jobs',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadSavedJobs,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _savedJobs.length,
          itemBuilder: (context, index) {
            final job = _savedJobs[index];
            return JobCardWidget(
              job: job,
              hasApplied: _appliedJobIds.contains(job.id),
              isBookmarked: true,
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
                if (mounted) await _refreshAppliedIds();
              },
              onApply: () async {
                final ok = await showApplyJobSheet(context, job);
                if (ok && mounted) {
                  await _loadSavedJobs();
                  await _refreshAppliedIds();
                }
              },
              onBookmark: () => _unsaveJob(job),
            );
          },
        ),
      ),
    );
  }
}
