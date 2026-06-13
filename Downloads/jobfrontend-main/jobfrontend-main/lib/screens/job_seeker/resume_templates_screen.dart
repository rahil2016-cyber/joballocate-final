import 'package:flutter/material.dart';

import '../../services/app_session.dart';
import '../../utils/app_colors.dart';
import '../../services/resume_demo_profiles_cache.dart';
import '../../services/resume_html_thumbnail_cache.dart';
import '../../widgets/seeker_html_template_swatch.dart';
import '../../widgets/resume_template_mini_preview.dart';
import 'my_resumes_screen.dart';
import 'resume_dashboard_template_card.dart';
import 'resume_html_preview_screen.dart';
import 'resume_preview_navigation.dart';
import 'seeker_resume_studio_screen.dart';

/// Choose among server-rendered HTML résumé templates (12 layouts).
class ResumeTemplatesScreen extends StatelessWidget {
  const ResumeTemplatesScreen({
    super.key,
    this.userId = 'demo-user',
    this.token = 'demo-token',
    this.seekerProfile,
  });

  final String userId;
  final String token;
  final Map<String, dynamic>? seekerProfile;

  void _openStudio(BuildContext context, String htmlKey) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SeekerResumeStudioScreen(
          templateIdForSave: seekerStudioTemplateIdForHtmlKey(htmlKey),
        ),
      ),
    );
  }

  void _openPreview(BuildContext context, String htmlKey) {
    openResumeHtmlPreviewWithUserData(context, templateKey: htmlKey);
  }

  void _openMyResumes(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MyResumesScreen(
          userId: AppSession.userId ?? userId,
          token: AppSession.token ?? token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResumeDemoProfilesCache.instance.ensureLoaded();
    for (var v = 0; v < 4; v++) {
      ResumeHtmlThumbnailCache.instance.preloadVariant(v);
    }
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resume templates'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _openMyResumes(context),
            child: const Text(
              'My resumes',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12 professional layouts',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill your details in the studio, preview on A4, then purchase to download PDF '
                      '(₹20 demo — recorded in admin purchases).',
                      style: tt.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 460,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                scrollDirection: Axis.horizontal,
                itemCount: kSeekerResumeHtmlTemplates.length,
                itemBuilder: (context, index) {
                  final slot = kSeekerResumeHtmlTemplates[index];
                  final key = slot['key'] ?? 't1_teal_sidebar';
                  final label = slot['label'] ?? 'Template';
                  final variant = index % ResumeDemoProfilesCache.instance.variantCount;
                  return ResumeDashboardTemplateCard(
                    displayLabel: label,
                    htmlTemplateKey: key,
                    demoVariant: variant,
                    onView: () => _openPreview(context, key),
                    onEdit: () => _openStudio(context, key),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList.separated(
              itemCount: kSeekerResumeHtmlTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final slot = kSeekerResumeHtmlTemplates[index];
                final key = slot['key']!;
                final label = slot['label'] ?? key;
                final variant = index % ResumeDemoProfilesCache.instance.variantCount;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openStudio(context, key),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 68,
                            child: ResumeTemplateMiniPreview(
                              templateKey: key,
                              demoVariant: variant,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openPreview(context, key),
                            child: const Text('Preview'),
                          ),
                          FilledButton(
                            onPressed: () => _openStudio(context, key),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
