import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../widgets/job_card.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';

/// Jobs similar to the seeker's applications (`GET /job-seeker/related-jobs`).
class RelatedJobsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const RelatedJobsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  @override
  State<RelatedJobsScreen> createState() => _RelatedJobsScreenState();
}

class _RelatedJobsScreenState extends State<RelatedJobsScreen> {
  List<Job> _jobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isLoading = true;
  String? _loadError;

  final JobSeekerApiService _api = JobSeekerApiService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshAppliedIds();
    _loadSavedJobIds();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      if (mounted) {
        setState(() {
          _jobs = [];
          _isLoading = false;
          _loadError = null;
        });
      }
      return;
    }
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final jobs = await _api.getRelatedJobs(perPage: 80);
      if (mounted) {
        setState(() {
          _jobs = jobs;
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
      final apps = await _api.listMyApplications(perPage: 100);
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
      final saved = await _api.listSavedJobs(perPage: 100);
      if (mounted) {
        setState(() => _savedJobIds = saved.map((j) => j.id).toSet());
      }
    } catch (_) {
      if (mounted) setState(() => _savedJobIds = {});
    }
  }

  Future<void> _saveJob(Job job) async {
    try {
      await _api.saveJob(job.id);
      if (mounted) {
        setState(() => _savedJobIds.add(job.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
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
      await _api.unsaveJob(job.id);
      if (mounted) {
        setState(() => _savedJobIds.remove(job.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job removed from saved'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
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
          'More like jobs you applied to',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([_load(), _refreshAppliedIds(), _loadSavedJobIds()]);
        },
        child: _buildBody(textTheme),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (!AppSession.isLoggedIn) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Sign in to see jobs matched to your applications.',
              textAlign: TextAlign.center, style: textTheme.titleMedium),
        ],
      );
    }

    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    if (_loadError != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textHint.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text('Could not load jobs', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_loadError!, textAlign: TextAlign.center, style: textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Icon(Icons.work_outline_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No suggestions yet', textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Apply to a few roles and we will suggest similar openings.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
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
              await _load();
              await _refreshAppliedIds();
            }
          },
          onBookmark: () => isSaved ? _unsaveJob(job) : _saveJob(job),
        );
      },
    );
  }
}
