import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';

import 'seeker_html_template_filled_preview.dart';

Widget _miniTwoColumn({
  required Color accent,
  required Color sideBg,
  required Color headerBorder,
  bool dark = false,
  bool showHeader = true,
}) {
  final line = dark ? Colors.white24 : Colors.black12;
  final titleColor = dark ? Colors.white : const Color(0xFF0F172A);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showHeader)
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                width: 56,
                decoration: BoxDecoration(
                  color: titleColor.withValues(alpha: dark ? 0.9 : 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 4, width: 72, color: accent.withValues(alpha: 0.75)),
            ],
          ),
        ),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              color: sideBg,
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Column(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 3, width: double.infinity, color: line),
                  const SizedBox(height: 3),
                  Container(height: 3, width: double.infinity, color: line),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 4, width: 36, color: accent),
                    const SizedBox(height: 6),
                    Container(height: 2, width: double.infinity, color: line),
                    const SizedBox(height: 4),
                    Container(height: 2, width: double.infinity, color: line),
                    const SizedBox(height: 4),
                    Container(height: 2, width: double.infinity, color: line),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Mini layout hint matching Laravel `resume/html/t*_*.blade.php` designs
/// (not the Flutter PDF widget gallery). Optional [resumePreview] overlays live data.
class SeekerHtmlTemplateSwatch extends StatelessWidget {
  const SeekerHtmlTemplateSwatch({
    super.key,
    required this.templateKey,
    this.resumePreview,
    this.demoVariant = 0,
  });

  final String templateKey;
  final ResumeModel? resumePreview;
  final int demoVariant;

  @override
  Widget build(BuildContext context) {
    if (resumePreview == null) {
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 140,
          height: 180,
          child: SeekerHtmlTemplateFilledPreview(
            templateKey: templateKey,
            demoVariant: demoVariant,
          ),
        ),
      );
    }
    final pattern = _swatchPattern();
    final core = Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              pattern,
              Positioned(
                left: 5,
                right: 5,
                bottom: 5,
                child: _ResumeTemplateMiniSummary(model: resumePreview!),
              ),
            ],
          );

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(width: 140, height: 180, child: core),
    );
  }

  Widget _swatchPattern() {
    switch (templateKey) {
      case 't1_teal_sidebar':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 32,
              child: Container(
                color: const Color(0xFF0D7377),
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 14, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 6),
                    Container(height: 8, width: double.infinity, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 4),
                    Container(height: 8, width: double.infinity, color: Colors.white.withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 68,
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 10, width: 72, color: const Color(0xFF0D7377).withValues(alpha: 0.85)),
                      const SizedBox(height: 6),
                      Container(height: 5, width: 100, color: Colors.black26),
                      const SizedBox(height: 8),
                      Container(height: 4, width: double.infinity, color: Colors.black12),
                      Container(height: 4, margin: const EdgeInsets.only(top: 3), width: double.infinity, color: Colors.black12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 't2_minimal':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF334155)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8, width: 64, color: Colors.white.withValues(alpha: 0.95)),
                        const SizedBox(height: 4),
                        Container(height: 3, width: 80, color: Colors.white38),
                        const SizedBox(height: 4),
                        Container(height: 2, width: 48, color: Colors.white30),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 3, width: 36, color: const Color(0xFF0F172A)),
                      const SizedBox(height: 6),
                      Container(height: 3, width: double.infinity, color: Colors.black12),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 32,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 't3_bold_navy':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)]))),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 11, width: 80, color: const Color(0xFF1E3A5F)),
                      const SizedBox(height: 6),
                      Container(height: 3, width: 50, color: const Color(0xFF3B82F6)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(width: 36, height: 16, decoration: BoxDecoration(color: const Color(0xFFE8EEF9), borderRadius: BorderRadius.circular(10))),
                          const SizedBox(width: 4),
                          Container(width: 36, height: 16, decoration: BoxDecoration(color: const Color(0xFFE8EEF9), borderRadius: BorderRadius.circular(10))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case 't4_classic_serif':
        return ColoredBox(
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 62,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Color(0xFF9F1239), width: 3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 8, width: 72, color: const Color(0xFF0C0A09)),
                            const SizedBox(height: 4),
                            Container(height: 4, width: 56, color: const Color(0xFF78716C)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(height: 4, width: double.infinity, color: Colors.black12),
                      const SizedBox(height: 6),
                      Container(height: 3, width: double.infinity, color: Colors.black12),
                    ],
                  ),
                ),
              ),
              Container(width: 3, color: const Color(0xFF9F1239).withValues(alpha: 0.35)),
              Expanded(
                flex: 32,
                child: ColoredBox(
                  color: const Color(0xFFFFF7ED),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, width: 40, color: const Color(0xFF9F1239)),
                        const SizedBox(height: 6),
                        Container(height: 3, width: double.infinity, color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          height: 24,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 't5_modern_split':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 28,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 8, width: 64, color: Colors.white.withValues(alpha: 0.95)),
                  const SizedBox(height: 4),
                  Container(height: 4, width: 88, color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFF1E293B),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 36,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 8, 4, 6),
                        child: Container(
                          decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
                          height: 40,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 64,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 6, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 5, width: 48, color: const Color(0xFFC7D2FE)),
                            const SizedBox(height: 6),
                            Container(height: 3, width: double.infinity, color: Colors.white24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 't6_navy_two_column':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 32,
              color: const Color(0xFF152238),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38),
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 6, color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 52, color: const Color(0xFFF1F5F9)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 4, width: 40, color: const Color(0xFF152238)),
                          const SizedBox(height: 6),
                          Container(height: 2, width: double.infinity, color: Colors.black12),
                          const SizedBox(height: 4),
                          Container(height: 2, width: double.infinity, color: Colors.black12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 't7_geometric_modern':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 9,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(height: 4, width: 90, color: const Color(0xFF64748B)),
                ],
              ),
            ),
            Expanded(
              child: _miniTwoColumn(
                accent: const Color(0xFF06B6D4),
                sideBg: const Color(0xFFF0FDFA),
                headerBorder: const Color(0xFF06B6D4),
                showHeader: false,
              ),
            ),
          ],
        );
      case 't8_typewriter_retro':
        return ColoredBox(
          color: const Color(0xFFF4E8D0),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(height: 6, width: 72, color: const Color(0xFF78350F))),
                const SizedBox(height: 4),
                Container(height: 2, width: double.infinity, color: const Color(0xFF78350F).withValues(alpha: 0.35)),
                const Spacer(),
                Container(height: 2, width: double.infinity, color: Colors.black12),
              ],
            ),
          ),
        );
      case 't9_vintage_folio':
        return ColoredBox(
          color: const Color(0xFFFAF7F2),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFA8A29E))),
              child: _miniTwoColumn(accent: const Color(0xFF78716C), sideBg: Colors.transparent, headerBorder: const Color(0xFF78716C)),
            ),
          ),
        );
      case 't10_creative_sunset':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEC4899), Color(0xFF8B5CF6)]),
              ),
              padding: const EdgeInsets.all(6),
              child: Align(alignment: Alignment.centerLeft, child: Container(height: 6, width: 56, color: Colors.white)),
            ),
            Expanded(child: _miniTwoColumn(accent: const Color(0xFFEA580C), sideBg: const Color(0xFFFFF7ED), headerBorder: const Color(0xFFEA580C))),
          ],
        );
      case 't11_mono_swiss':
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 10, color: Colors.black)),
                  const SizedBox(width: 8),
                  Container(height: 6, width: 36, color: Colors.black26),
                ],
              ),
              Container(height: 2, margin: const EdgeInsets.only(top: 6), color: Colors.black),
              const Spacer(),
              Container(height: 2, width: double.infinity, color: Colors.black12),
              const SizedBox(height: 4),
              Container(height: 2, width: double.infinity, color: Colors.black12),
            ],
          ),
        );
      case 't12_royal_gold':
        return ColoredBox(
          color: const Color(0xFF0C1929),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC9A227))),
              child: _miniTwoColumn(accent: const Color(0xFFC9A227), sideBg: const Color(0xFF132337), headerBorder: const Color(0xFFC9A227), dark: true),
            ),
          ),
        );
      default:
        return const ColoredBox(color: Color(0xFFF1F5F9), child: SizedBox.expand());
    }
  }
}

class _ResumeTemplateMiniSummary extends StatelessWidget {
  const _ResumeTemplateMiniSummary({required this.model});

  final ResumeModel model;

  @override
  Widget build(BuildContext context) {
    final name = model.fullName.trim().isEmpty ? 'Your name' : model.fullName.trim();
    final title = model.professionalTitle.trim();
    var sub = model.summary.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (sub.length > 80) sub = '${sub.substring(0, 80)}…';
    if (sub.isEmpty) {
      sub = model.skills.where((s) => s.trim().isNotEmpty).take(4).join(' · ');
    }
    if (sub.length > 80) sub = '${sub.substring(0, 80)}…';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0F172A)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (sub.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  sub,
                  style: TextStyle(fontSize: 8, height: 1.25, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Maps HTML preview keys to resume draft `template_id` strings used by [SeekerResumeStudioScreen].
String seekerStudioTemplateIdForHtmlKey(String htmlTemplateKey) {
  switch (htmlTemplateKey) {
    case 't1_teal_sidebar':
      return '1';
    case 't2_minimal':
      return '2';
    case 't3_bold_navy':
      return '3';
    case 't4_classic_serif':
      return '4';
    case 't5_modern_split':
      return '5';
    case 't6_navy_two_column':
      return '6';
    case 't7_geometric_modern':
      return '7';
    case 't8_typewriter_retro':
      return '8';
    case 't9_vintage_folio':
      return '9';
    case 't10_creative_sunset':
      return '10';
    case 't11_mono_swiss':
      return '11';
    case 't12_royal_gold':
      return '12';
    default:
      return '1';
  }
}

/// Inverse of [seekerStudioTemplateIdForHtmlKey] — maps saved draft `template_id` to Laravel HTML `template_key`.
String seekerHtmlTemplateKeyForStudioTemplateId(String templateId) {
  switch (templateId) {
    case '1':
      return 't1_teal_sidebar';
    case '2':
      return 't2_minimal';
    case '3':
      return 't3_bold_navy';
    case '4':
      return 't4_classic_serif';
    case '5':
      return 't5_modern_split';
    case '6':
      return 't6_navy_two_column';
    case '7':
      return 't7_geometric_modern';
    case '8':
      return 't8_typewriter_retro';
    case '9':
      return 't9_vintage_folio';
    case '10':
      return 't10_creative_sunset';
    case '11':
      return 't11_mono_swiss';
    case '12':
      return 't12_royal_gold';
    default:
      return 't1_teal_sidebar';
  }
}
