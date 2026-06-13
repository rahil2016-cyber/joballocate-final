import 'package:flutter/material.dart';
import '../models/job.dart';
import '../models/seeker_profile.dart';
import '../screens/job_seeker/application_submitted_screen.dart';
import '../screens/job_seeker/packages_screen.dart';
import '../screens/job_seeker/my_resumes_screen.dart';
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

  final jobId = job.id;

  String? primaryResumeTitle;
  try {
    final raw = await JobSeekerApiService.instance.getSeekerProfile();
    final pr = raw['primary_resume_draft'];
    if (pr is Map) {
      primaryResumeTitle = pr['title']?.toString();
    }
  } catch (_) {}

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
                  if (primaryResumeTitle != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Linked Resume',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint),
                                ),
                                Text(
                                  primaryResumeTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyResumesScreen()),
                              );
                            },
                            child: const Text('Change', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No resume linked to your profile.',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MyResumesScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.orange.shade800),
                                foregroundColor: Colors.orange.shade800,
                              ),
                              child: const Text('Go to My Resumes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'The selected resume will be shown to ${job.companyName}.',
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
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ApplicationSubmittedScreen(
                                      companyName: job.companyName,
                                    ),
                                  ),
                                );
                              });
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
