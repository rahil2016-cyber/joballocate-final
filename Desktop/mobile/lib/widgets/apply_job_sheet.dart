import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/seeker_profile.dart';
import '../screens/job_seeker/packages_screen.dart';
import '../services/app_session.dart';
import '../services/job_seeker_api_service.dart';
import '../utils/app_colors.dart';

/// Shows cover letter + submit; calls `POST /job-seeker/jobs/{id}/apply`.
/// Returns `true` if application succeeded.
Future<bool> showApplyJobSheet(BuildContext context, Job job) async {
  final token = AppSession.token;
  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in again to apply.'),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }

  final jobId = int.tryParse(job.id);
  if (jobId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid job.'),
        backgroundColor: AppColors.error,
      ),
    );
    return false;
  }

  try {
    final raw = await JobSeekerApiService.instance.getSeekerProfile();
    final summary = SeekerProfileSummary.fromJson(raw);
    if (!summary.canApply) {
      if (!context.mounted) return false;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Package required'),
          content: Text(
            summary.packageKey == null
                ? 'Choose a job seeker package to unlock applications. You can activate a plan without payment for now.'
                : 'Your package has no applications left or it has expired. Choose a plan again in Packages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('View packages'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const JobSeekerPackagesScreen(),
          ),
        );
      }
      return false;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not verify your package: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }

  if (!context.mounted) return false;

  final coverCtrl = TextEditingController();
  var submitting = false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Apply to ${job.title}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.companyName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: coverCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Cover letter (optional)',
                      hintText: 'Why are you a great fit?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tip: add a resume link in Profile so employers can open it from your application.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            setModalState(() => submitting = true);
                            try {
                              await JobSeekerApiService.instance.apply(
                                jobId,
                                coverLetter: coverCtrl.text.trim().isEmpty
                                    ? null
                                    : coverCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              setModalState(() => submitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('$e'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit application'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  coverCtrl.dispose();
  return result == true;
}
