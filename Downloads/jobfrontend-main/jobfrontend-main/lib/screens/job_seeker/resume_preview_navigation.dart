import 'package:flutter/material.dart';

import '../../features/resume/models/resume_model.dart';
import '../../features/resume/services/resume_seed_from_profile.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/resume_draft_utils.dart';
import '../../features/resume/adapters/draft_resume_parse.dart';
import 'resume_html_preview_screen.dart';

/// Full A4 preview with the signed-in user's draft / profile — never demo profiles.
Future<void> openResumeHtmlPreviewWithUserData(
  BuildContext context, {
  required String templateKey,
}) async {
  if (!AppSession.isLoggedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to preview your resume.')),
      );
    }
    return;
  }

  try {
    final raw = await JobSeekerApiService.instance.getResumeDrafts();
    final draft = pickBestResumeDraftForPrefill(raw) ?? pickPrimaryResumeDraft(raw);
    int? draftId;
    Map<String, dynamic>? envelope;
    if (draft != null) {
      final id = int.tryParse(draft['id']?.toString() ?? '') ?? 0;
      draftId = id > 0 ? id : null;
      final parsed = resumeDraftParseForBuilder(draft['content']);
      if (parsed.model != null) {
        envelope = resumeModelToApiEnvelope(parsed.model!);
      } else if (parsed.legacy != null) {
        envelope = resumeModelToApiEnvelope(ResumeModel.fromLegacyJsonResume(parsed.legacy!));
      }
    }
    envelope ??= resumeModelToApiEnvelope(
      resumeModelFromSeekerProfileMaps(
        profile: await JobSeekerApiService.instance.getSeekerProfile(),
        sessionUser: AppSession.user,
      ),
    );
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResumeHtmlPreviewScreen(
          templateKey: templateKey,
          contentEnvelope: envelope,
          resumeDraftId: draftId,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}
