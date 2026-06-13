import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/job.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';

/// Application status, cover letter, employer note, withdraw — plus full job details (same as job view).
class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({
    super.key,
    required this.application,
  });

  final JobApplication application;

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  late JobApplication _app;
  bool _withdrawing = false;
  Job? _job;
  bool _jobLoading = true;
  String? _jobError;

  @override
  void initState() {
    super.initState();
    _app = widget.application;
    _loadJob();
  }

  Future<void> _loadJob() async {
    final id = _app.jobId;
    setState(() {
      _jobLoading = true;
      _jobError = null;
    });
    try {
      final j = await JobSeekerApiService.instance.getJob(id);
      if (!mounted) return;
      setState(() {
        _job = j;
        _jobLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _jobError = '$e';
        _jobLoading = false;
      });
    }
  }

  bool get _canWithdraw =>
      _app.status == 'applied' || _app.status == 'shortlisted';

  Future<void> _withdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: const Text(
          'This removes your application and returns one application credit to your package.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final id = _app.id;

    setState(() => _withdrawing = true);
    try {
      await JobSeekerApiService.instance.withdrawApplication(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y · h:mm a');
    final textTheme = Theme.of(context).textTheme;
    final job = _job;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Application'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _app.jobTitle,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _app.companyName,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _app.getStatusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _app.getStatusLabel(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _app.getStatusColor(),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Job details',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (_jobLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_jobError != null)
            _jobCardPlaceholder(
              textTheme,
              'Could not load live job data.',
              _jobError!,
            )
          else if (job != null) ...[
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    value: job.location,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.access_time_rounded,
                    title: 'Job type',
                    value: job.jobType.replaceAll('_', ' '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Salary',
                    value: job.salaryRange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.trending_up_rounded,
                    title: 'Experience',
                    value: job.experienceDisplay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Skills',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Description',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Requirements',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              job.requirements.trim().isEmpty
                  ? 'Not specified'
                  : job.requirements,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
                fontStyle: job.requirements.trim().isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
            if (job.applicationDeadlineAt != null ||
                job.maxApplications != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
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
                        Icon(Icons.schedule_rounded,
                            color: Colors.orange.shade800, size: 20),
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
                    if (job.applicationDeadlineAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Apply before ${DateFormat('MMM d, y • HH:mm').format(job.applicationDeadlineAt!)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (job.maxApplications != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${job.applicationsCount} / ${job.maxApplications} applicants',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ] else
            _jobCardPlaceholder(
              textTheme,
              'Job details unavailable.',
              'Try again later.',
            ),
          const SizedBox(height: 28),
          _section('Timeline', [
            _kv('Applied', fmt.format(_app.appliedAt)),
            _kv('Last updated', fmt.format(_app.updatedAt)),
          ]),
          if (_app.coverLetter != null && _app.coverLetter!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _section(
              'Your cover letter',
              [
                Text(
                  _app.coverLetter!,
                  style: const TextStyle(
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (_app.notes != null && _app.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _section(
              'Message from employer',
              [
                Text(
                  _app.notes!,
                  style: const TextStyle(
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ] else if (_app.status != 'applied' &&
              _app.status != 'shortlisted') ...[
            const SizedBox(height: 20),
            Text(
              'No employer message yet.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ],
          if (_canWithdraw) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _withdrawing ? null : _withdraw,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _withdrawing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_rounded),
              label: Text(_withdrawing ? 'Withdrawing…' : 'Withdraw application'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _jobCardPlaceholder(
      TextTheme textTheme, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadJob,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
