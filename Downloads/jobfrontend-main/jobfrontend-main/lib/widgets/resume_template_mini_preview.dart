import 'package:flutter/material.dart';

import 'resume_template_html_thumbnail.dart';

/// List-row thumbnail — same filled preview as dashboard carousel.
class ResumeTemplateMiniPreview extends StatelessWidget {
  const ResumeTemplateMiniPreview({
    super.key,
    required this.templateKey,
    this.demoVariant = 0,
  });

  final String templateKey;
  final int demoVariant;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: ResumeTemplateHtmlThumbnail(
          templateKey: templateKey,
          demoVariant: demoVariant,
        ),
      ),
    );
  }
}
