import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

/// Published jobs from admin “spotlight” employers (`GET /jobs?from_top_companies=1`).
class SpotlightEmployersJobsScreen extends StatefulWidget {
  const SpotlightEmployersJobsScreen({
    super.key,
    required this.userId,
    required this.token,
  });

  final String userId;
  final String token;

  @override
  State<SpotlightEmployersJobsScreen> createState() =>
      _SpotlightEmployersJobsScreenState();
}

class _SpotlightEmployersJobsScreenState extends State<SpotlightEmployersJobsScreen> {
  List<Job> _jobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshAppliedIds();
    _loadSavedJobIds();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final jobs = await JobSeekerApiService.instance.listJobs(
        fromTopCompanies: true,
        perPage: 50,
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
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
      final apps =
          await JobSeekerApiService.instance.listMyApplications(perPage: 100);
      if (mounted) {
        setState(() => _appliedJobIds = apps.map((a) => a.jobId).toSet());
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
      final saved =
          await JobSeekerApiService.instance.listSavedJobs(perPage: 100);
      if (mounted) {
        setState(() => _savedJobIds = saved.map((j) => j.id).toSet());
      }
    } catch (_) {
      if (mounted) setState(() => _savedJobIds = {});
    }
  }

  Future<void> _saveJob(Job job) async {
    try {
      await JobSeekerApiService.instance.saveJob(job.id);
      if (mounted) setState(() => _savedJobIds.add(job.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _unsaveJob(Job job) async {
    try {
      await JobSeekerApiService.instance.unsaveJob(job.id);
      if (mounted) setState(() => _savedJobIds.remove(job.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Spotlight employer jobs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
        child: _buildBody(tt),
      ),
    );
  }

  Widget _buildBody(TextTheme tt) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: _load, child: const Text('Retry'))),
        ],
      );
    }

    if (_jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          Icon(Icons.business_center_outlined,
              size: 56, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No spotlight jobs right now',
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'When admins mark verified employers as spotlight, their open roles appear here and on your home feed.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
            if (ok && mounted) await _refreshAppliedIds();
          },
          onBookmark: () => isSaved ? _unsaveJob(job) : _saveJob(job),
        );
      },
    );
  }
}
