import 'dart:io';

import 'package:flutter/material.dart';
import '../models/json_resume.dart';
import '../models/resume_template.dart';
import '../resume/widgets/resume_thumbnail_preview.dart';
import '../utils/app_colors.dart';

/// Visible name in miniature previews (empty [Basics.name] would otherwise show a blank bar).
String _previewPersonName(Basics? basics, {String fallback = 'YOUR NAME'}) {
  final t = basics?.name.trim() ?? '';
  return t.isNotEmpty ? t : fallback;
}

const Color _priorityTealGlobal = Color(0xFF136A8A); // Fallback if needed outside class

class TemplatePreview extends StatelessWidget {
  final int variant;
  final double height;
  final bool showHeader;
  final JsonResume? resume;
  final bool useMockData;

  /// When [resume] is null and [useMockData] is true, try this asset first (e.g. filled PNG per template id).
  final String? filledScreenshotAsset;

  const TemplatePreview({
    super.key,
    required this.variant,
    this.height = 120,
    this.showHeader = true,
    this.resume,
    this.useMockData = false,
    this.filledScreenshotAsset,
  });

  @override
  Widget build(BuildContext context) {
    // Prioritize high-fidelity screenshot in "preview" contexts (useMockData = true)
    if (filledScreenshotAsset != null && useMockData) {
      final previewPath = filledScreenshotAsset!;
      final isAssetPath = previewPath.startsWith('assets/');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: isAssetPath
              ? Image.asset(
                  previewPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return TemplatePreview(
                      variant: variant,
                      height: height,
                      showHeader: showHeader,
                      resume: null,
                      useMockData: true,
                      filledScreenshotAsset: null,
                    );
                  },
                )
              : Image.file(
                  File(previewPath),
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) {
                    return TemplatePreview(
                      variant: variant,
                      height: height,
                      showHeader: showHeader,
                      resume: null,
                      useMockData: true,
                      filledScreenshotAsset: null,
                    );
                  },
                ),
        ),
      );
    }

    ResumeTemplate? bundledMatch;
    for (final t in resumeTemplates) {
      if (t.id == variant || t.designVariant == variant) {
        bundledMatch = t;
        break;
      }
    }
    if (bundledMatch != null) {
      return ResumeThumbnailPreview(
        template: bundledMatch,
        legacyResume: resume,
        height: height,
      );
    }

    if (variant == 0) return _buildDynamicResume(height); // legacy dynamic thumbnail
    if (variant == 4) {
      return _buildPriorityResumePreview(height, resume, useMockData);
    }
    if (variant == 5) {
      return _buildPriorityResume2Preview(height, resume, useMockData);
    }
    if (variant == 6) {
      return _buildPriorityResume3Preview(height, resume, useMockData);
    }
    if (variant == 7) {
      return _buildPillarBarePreview(height, resume, useMockData);
    }
    if (variant == 8) {
      return _buildProfessionalSidebarPreview(height, resume, useMockData);
    }
    if (variant == 9) {
      return _buildProfessionalGrandPreview(height, resume, useMockData);
    }
    if (variant == 10) {
      return _buildNaukriRealtimePreview(height, resume, useMockData);
    }
    
    final v = variant % 4;
    final hasResume = resume != null || useMockData;
    final basics = resume?.basics;
    
    // Mock data for previews
    final displayName = hasResume ? _previewPersonName(basics, fallback: 'FAIZAN AHMED') : '';
    final displayLabel = hasResume ? (basics?.label ?? 'SOFTWARE ENGINEER') : '';
    final displaySummary = hasResume ? (basics?.summary ?? 'Dedicated professional with experience in building scalable mobile applications and leading technical teams to success.') : '';

    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(hasResume ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: v == 1
                    ? const Color(0xFF0F172A) // Slate Header
                    : (v == 2 ? const Color(0xFFEFF6FF) : (v == 3 ? const Color(0xFFF0FDF4) : Colors.white)),
                borderRadius: BorderRadius.circular(4),
                border: v == 0 ? Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5)) : null,
              ),
              child: Row(
                children: [
                  if (v == 1 || v == 3) // Avatar placeholder for some styles
                    Container(
                      width: height > 300 ? 50 : 20,
                      height: height > 300 ? 50 : 20,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: v == 3 ? const Color(0xFF22C55E).withOpacity(0.2) : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                      ),
                      child: Icon(Icons.person, size: height > 300 ? 30 : 12, color: Colors.white.withOpacity(0.8)),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: height > 300 ? 16 : 8,
                            color: (v == 1 || v == 3) ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                        ),
                        if (height > 100)
                          Text(
                            displayLabel,
                            style: TextStyle(
                              fontSize: height > 300 ? 10 : 6,
                              color: (v == 1 || v == 3) ? Colors.white.withOpacity(0.8) : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (v == 1 || v == 2) // Sidebar style
                  Container(
                    width: height > 300 ? 90 : 35,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: v == 1 ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: hasResume && height > 150
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _miniHeader('CONTACT', inverse: v == 2),
                                ...List.generate(3, (i) => _miniLine(inverse: v == 2)),
                                const SizedBox(height: 16),
                                _miniHeader('SKILLS', inverse: v == 2),
                                ...List.generate(5, (i) => _miniLine(inverse: v == 2)),
                                const SizedBox(height: 16),
                                _miniHeader('LANGS', inverse: v == 2),
                                _miniLine(inverse: v == 2),
                                _miniLine(inverse: v == 2),
                              ],
                            ),
                          )
                        : null,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasResume && displaySummary.isNotEmpty) ...[
                          _miniHeader('PROFILE'),
                          Text(
                            displaySummary,
                            style: TextStyle(
                              fontSize: height > 300 ? 9 : 5, 
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: height > 300 ? 6 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _miniHeader('EXPERIENCE'),
                        ...List.generate(
                          height > 400 ? 3 : 2,
                          (i) => _miniEntry(height),
                        ),
                        if (height > 250) ...[
                          const SizedBox(height: 16),
                          _miniHeader('EDUCATION'),
                          _miniEntry(height),
                        ],
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const Color _priorityTeal = Color(0xFF136A8A);
  static const Color _priorityRoyalBlue = Color(0xFF4169E1);
  static const Color _prioritySlate = Color(0xFF2C3E50);
  static const Color _priorityAmber = Color(0xFFFFBF00);
  static const Color _pillarSlate = Color(0xFF37474F);
  static const Color _pillarAmber = Color(0xFFF57C00);

  /// Priority Resume thumbnail — teal header + section rules (template 14, designVariant 4).
  Widget _buildPriorityResumePreview(double height, JsonResume? resume, bool useMockData) {
    const designW = 260.0;
    const designH = 420.0;
    final hasResume = resume != null || useMockData;
    final basics = resume?.basics;
    final displayName = hasResume ? _previewPersonName(basics) : 'YOUR NAME';
    final phone = hasResume ? (basics?.phone ?? '') : '';
    final email = hasResume ? (basics?.email ?? '') : '';

    Widget tealSectionLine(String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: _priorityTeal,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: _priorityTeal,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(height: 1, color: _priorityTeal),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    color: _priorityTeal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (phone.isNotEmpty || !hasResume) ...[
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'P',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: _priorityTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  phone.isNotEmpty ? phone : 'phone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (email.isNotEmpty || !hasResume) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '@',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: _priorityTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  email.isNotEmpty ? email : 'email',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: SingleChildScrollView(
                        clipBehavior: Clip.hardEdge,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tealSectionLine('RESUME SUMMARY'),
                            if (basics?.summary.trim().isNotEmpty == true)
                              Text(
                                basics!.summary,
                                maxLines: height > 300 ? 6 : 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: height > 300 ? 8 : 6,
                                  color: Colors.grey.shade800,
                                  height: 1.35,
                                ),
                              )
                            else ...[
                              _miniLine(),
                              _miniLine(),
                            ],
                            tealSectionLine('SKILLS'),
                            Builder(
                              builder: (context) {
                                final tokens = <String>[];
                                if (resume != null) {
                                  for (final s in resume.skills) {
                                    if (s.name.trim().isNotEmpty) {
                                      tokens.add(s.name.trim());
                                    }
                                    for (final k in s.keywords) {
                                      if (k.trim().isNotEmpty) {
                                        tokens.add(k.trim());
                                      }
                                    }
                                  }
                                }
                                if (tokens.isEmpty) {
                                  return _miniLine();
                                }
                                return Text(
                                  tokens.take(12).join(' · '),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: height > 300 ? 8 : 6,
                                    color: Colors.grey.shade800,
                                    height: 1.35,
                                  ),
                                );
                              },
                            ),
                            tealSectionLine('EDUCATION'),
                            if (resume != null && resume.education.isNotEmpty)
                              ...resume.education.take(2).map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        [
                                          if (e.area.trim().isNotEmpty) e.area,
                                          if (e.institution.trim().isNotEmpty) e.institution,
                                          if (e.score.trim().isNotEmpty) e.score,
                                        ].where((x) => x.trim().isNotEmpty).join(' · '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: height > 300 ? 8 : 6,
                                          color: Colors.grey.shade800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  )
                            else
                              _miniLine(),
                            tealSectionLine('INTERNSHIPS'),
                            if (resume != null && resume.volunteer.isNotEmpty)
                              ...resume.volunteer.take(2).map(
                                    (v) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.organization.trim().isNotEmpty
                                                ? v.organization
                                                : '—',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade900,
                                            ),
                                          ),
                                          if (v.position.trim().isNotEmpty)
                                            Text(
                                              v.position,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 7,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                            else
                              _miniLine(),
                            tealSectionLine('PROJECTS'),
                            if (resume != null && resume.publications.isNotEmpty)
                              ...resume.publications.take(2).map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name.trim().isNotEmpty ? p.name : 'Project',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              color: _priorityTeal,
                                            ),
                                          ),
                                          if (p.summary.trim().isNotEmpty)
                                            Text(
                                              p.summary,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 6,
                                                color: Colors.grey.shade800,
                                                height: 1.3,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                            else
                              _miniLine(),
                            tealSectionLine('WORK'),
                            if (resume != null && resume.work.isNotEmpty)
                              ...resume.work.take(2).map(
                                    (w) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.name.trim().isNotEmpty
                                                ? w.name
                                                : w.position,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey.shade900,
                                            ),
                                          ),
                                          if (w.position.trim().isNotEmpty &&
                                              w.name.trim().isNotEmpty)
                                            Text(
                                              w.position,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 7,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                            else
                              _miniLine(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Priority Resume 2 (template 15) — white two-column, black titles, yellow accents.
  Widget _buildPriorityResume2Preview(double height, JsonResume? resume, bool useMockData) {
    const designW = 260.0;
    const designH = 400.0;
    final hasResume = resume != null || useMockData;
    final basics = resume?.basics;
    final displayName = hasResume ? _previewPersonName(basics).toUpperCase() : 'YOUR NAME';
    final city = hasResume ? (basics?.location.city ?? '') : '';
    final phone = hasResume ? (basics?.phone ?? '') : '';
    final email = hasResume ? (basics?.email ?? '') : '';
    const yellow = Color(0xFFFFD700);

    Widget sectionHeader(String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 0.1,
          ),
        ),
      );
    }

    Widget languageBars(String level) {
      int bars = 1;
      final l = level.toLowerCase();
      if (l.contains('advanced') || l.contains('expert') || l.contains('native')) {
        bars = 5;
      } else if (l.contains('proficient') || l.contains('fluent')) {
        bars = 4;
      } else if (l.contains('intermediate') || l.contains('good')) {
        bars = 3;
      } else if (l.contains('basic')) {
        bars = 2;
      }
      return Row(
        children: List.generate(5, (index) {
    return Container(
            width: 14,
            height: 2,
            margin: const EdgeInsets.only(right: 1.5),
            color: index < bars ? yellow : Colors.grey.shade200,
          );
        }),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
      height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designW,
              height: designH * 1.5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Left Column ---
                  SizedBox(
                    width: 90,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.person, size: 30, color: Colors.grey),
                          ),
                          sectionHeader('CONTACT'),
                          Text(city.isNotEmpty ? city : 'Location', style: const TextStyle(fontSize: 5)),
                          Text(phone.isNotEmpty ? 'Mobile: $phone' : '', style: const TextStyle(fontSize: 5, fontWeight: FontWeight.bold)),
                          Text(email.isNotEmpty ? email : 'Email', style: const TextStyle(fontSize: 5)),
                          
                          sectionHeader('SKILLS'),
                          if (resume != null && resume.skills.isNotEmpty)
                            ...resume.skills.take(8).map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(padding: const EdgeInsets.only(top: 2, right: 3), child: Container(width: 1.5, height: 1.5, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
                                      Expanded(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 5))),
                                    ],
                                  ),
                                ))
                          else
                            ...List.generate(5, (i) => _miniLineWidget(width: 40)),

                          sectionHeader('EDUCATION'),
                          if (resume != null && resume.education.isNotEmpty)
                            ...resume.education.take(2).map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.endDate, style: const TextStyle(fontSize: 5, color: Colors.grey)),
                                      Text(e.area, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 5, fontWeight: FontWeight.bold)),
                                      Text(e.institution, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 5)),
                                    ],
                                  ),
                                ))
                          else
                            _miniLineWidget(width: 50),

                          sectionHeader('LANGUAGES'),
                          if (resume != null && resume.languages.isNotEmpty)
                            ...resume.languages.take(3).map((l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.language, style: const TextStyle(fontSize: 5, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 1),
                                      languageBars(l.fluency),
                                    ],
                                  ),
                                ))
                          else
                            _miniLineWidget(width: 30),
                        ],
                      ),
                    ),
                  ),

                  // --- Vertical Divider ---
                  Container(width: 1, color: Colors.black),

                  // --- Right Column ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(width: 35, height: 4, color: yellow),
                          
                          sectionHeader('PROFESSIONAL SUMMARY'),
                          if (basics?.summary.isNotEmpty == true)
                            Text(
                              basics!.summary,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 6, height: 1.4),
                            )
                          else
                            ...List.generate(3, (i) => _miniLineWidget()),

                          sectionHeader('WORK HISTORY'),
                          if (resume != null && resume.work.isNotEmpty)
                            ...resume.work.take(3).map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${w.startDate} - ${w.endDate}', style: const TextStyle(fontSize: 5.5)),
                                      Text('${w.position}, ${w.name}', style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(w.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 5.5)),
                                    ],
                                  ),
                                ))
                          else
                            _miniEntry(designH),
                          
                          sectionHeader('PROJECTS'),
                          if (resume != null && resume.publications.isNotEmpty)
                            ...resume.publications.take(2).map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.bold)),
                                      Text(p.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 5.5)),
                                    ],
                                  ),
                                ))
                          else
                            _miniLineWidget(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniLineWidget({double? width}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        width: width ?? double.infinity,
        height: 2,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  /// Priority Resume 3 (template 17) — royal-blue bar, square photo, black sidebar caps + rule below;
  /// main column with rule above section titles.
  Widget _buildPriorityResume3Preview(double height, JsonResume? resume, bool useMockData) {
    const designW = 260.0;
    const designH = 380.0;
    final hasResume = resume != null || useMockData;
    final basics = resume?.basics;
    final displayName = hasResume ? _previewPersonName(basics) : 'YOUR NAME';
    final phone = hasResume ? (basics?.phone ?? '') : '';
    final email = hasResume ? (basics?.email ?? '') : '';

    Widget sidebarBlackCap(String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Container(height: 1, color: Colors.black),
          ],
        ),
      );
    }

    Widget mainRuleAboveCap(String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 1, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
      color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    color: _priorityRoyalBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade500, width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0] : '?',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _priorityRoyalBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                sidebarBlackCap('GET IN TOUCH!'),
                                Text(
                                  'Mobile:',
                                  style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  phone.isNotEmpty ? phone : '—',
                                  style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Email:',
                                  style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  email.isNotEmpty ? email : '—',
                                  style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                ),
                                sidebarBlackCap('SKILLS'),
                                Builder(
                                  builder: (context) {
                                    final tokens = <String>[];
                                    if (resume != null) {
                                      for (final s in resume!.skills) {
                                        if (s.name.trim().isNotEmpty) {
                                          tokens.add(s.name.trim());
                                        }
                                      }
                                    }
                                    if (tokens.isEmpty) {
                                      return Text(
                                        '• —',
                                        style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: tokens
                                          .take(5)
                                          .map(
                                            (t) => Text(
                                              '• $t',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                                sidebarBlackCap('LANGUAGES'),
                                if (resume != null && resume!.languages.isNotEmpty)
                                  ...resume!.languages.take(2).map(
                                        (l) {
                                          final t = l.language.trim().isEmpty
                                              ? l.fluency
                                              : (l.fluency.trim().isEmpty
                                                  ? l.language
                                                  : '${l.language} (${l.fluency})');
                                          return Text(
                                            '• $t',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                          );
                                        },
                                      )
                                else
                                  Text('• —', style: TextStyle(fontSize: 6, color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, color: Colors.black),
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                mainRuleAboveCap('RESUME SUMMARY'),
                                if (basics?.summary.trim().isNotEmpty == true)
                                  Text(
                                    basics!.summary,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 6,
                                      color: Colors.grey.shade800,
                                      height: 1.35,
                                    ),
                                  )
                                else ...[
                                  _miniLine(),
                                  _miniLine(),
                                ],
                                mainRuleAboveCap('PERSONAL DETAILS'),
                                if (basics != null &&
                                    ([basics!.location.city, basics.location.region]
                                            .where((x) => x.trim().isNotEmpty)
                                            .isNotEmpty ||
                                        basics.dateOfBirth.trim().isNotEmpty))
                                  Text(
                                    [
                                      if ([basics.location.city, basics.location.region]
                                          .where((x) => x.trim().isNotEmpty)
                                          .join(', ')
                                          .isNotEmpty)
                                        [basics.location.city, basics.location.region]
                                            .where((x) => x.trim().isNotEmpty)
                                            .join(', '),
                                      if (basics.dateOfBirth.trim().isNotEmpty) basics.dateOfBirth,
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                  )
                                else
                                  _miniLine(),
                                mainRuleAboveCap('EDUCATION'),
                                if (resume != null && resume!.education.isNotEmpty)
                                  ...resume!.education.take(2).map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            [
                                              if (e.area.trim().isNotEmpty) e.area,
                                              if (e.institution.trim().isNotEmpty) e.institution,
                                            ].join(' — '),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                                          ),
                                        ),
                                      )
                                else
                                  _miniEntry(designH),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pillar Bare (template 18) — slate typography, amber accent bars, single column ATS look.
  Widget _buildPillarBarePreview(double height, JsonResume? resume, bool useMockData) {
    const designW = 260.0;
    const designH = 360.0;
    final hasResume = resume != null || useMockData;
    final basics = resume?.basics;
    final displayName = hasResume ? _previewPersonName(basics) : 'YOUR NAME';
    final phone = hasResume ? (basics?.phone ?? '') : '';
    final email = hasResume ? (basics?.email ?? '') : '';

    Widget pillarSection(String label, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: const BoxDecoration(
                color: _pillarAmber,
                borderRadius: BorderRadius.all(Radius.circular(1)),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 11, color: _pillarAmber),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _pillarSlate,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: _pillarAmber, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.person_outline_rounded, size: 16, color: _pillarSlate),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _pillarSlate,
                                ),
                              ),
                              if (basics?.label.trim().isNotEmpty == true)
                                Text(
                                  basics!.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 7, color: Colors.grey.shade700),
                                ),
                              const SizedBox(height: 5),
                              Text(
                                [
                                  if (phone.isNotEmpty) phone,
                                  if (email.isNotEmpty) email,
                                ].join('  |  '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 6, color: Colors.grey.shade800, height: 1.25),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 2, color: _pillarAmber),
                    pillarSection('SUMMARY', Icons.summarize_outlined),
                    if (basics?.summary.trim().isNotEmpty == true)
                      Text(
                        basics!.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 6, color: Colors.grey.shade800, height: 1.35),
                      )
                    else ...[
                      _miniLine(),
                      _miniLine(),
                    ],
                    pillarSection('SKILLS', Icons.bolt_outlined),
                    if (resume != null && resume!.skills.isNotEmpty)
                      Text(
                        resume!.skills.take(4).map((s) => s.name).where((n) => n.trim().isNotEmpty).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 6, color: Colors.grey.shade800),
                      )
                    else
                      Text('—', style: TextStyle(fontSize: 6, color: Colors.grey.shade600)),
                    pillarSection('EXPERIENCE', Icons.work_outline_rounded),
                    _miniEntry(designH),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicResume(double height) {
    // Fixed design canvas scaled to [height] so thumbnails never overflow small cells.
    const designW = 260.0;
    const designH = 300.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniHeader('SKILLS'),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(
                      5,
                      (i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                                  child: Container(
                                    width: 20,
                                    height: 2,
                                    color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                            ),
                            const SizedBox(height: 12),
                  _miniHeader('LANGUAGES'),
                  ...List.generate(3, (i) => _miniLine()),
                ],
              ),
            ),
          ),
                    const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniHeader('PROFILE'),
                _miniLine(),
                _miniLine(),
                          const SizedBox(height: 12),
                _miniHeader('EXPERIENCE'),
                          ...List.generate(2, (i) => _miniEntry(designH)),
                          const SizedBox(height: 12),
                _miniHeader('EDUCATION'),
                          _miniEntry(designH),
              ],
            ),
          ),
        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniHeader(String title, {bool inverse = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: height > 300 ? 9 : 6, 
          fontWeight: FontWeight.w900, 
          color: inverse ? Colors.white : AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _miniLine({bool inverse = false}) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 5),
      width: double.infinity,
      decoration: BoxDecoration(
        color: inverse ? Colors.white.withOpacity(0.2) : Colors.grey.shade200, 
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _miniEntry(double height) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: height > 300 ? 5 : 3.5, 
            width: 50, 
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(1)),
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(1))),
          const SizedBox(height: 2),
          Container(height: 2, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }

  Widget _buildProfessionalSidebarPreview(double height, JsonResume? resume, bool useMockData) {
    const designW = 280.0;
    const designH = 400.0;
    final hasResume = resume != null || useMockData;
    final b = resume?.basics;
    final name = hasResume ? _previewPersonName(b, fallback: 'ETHAN SMITH') : 'ETHAN SMITH';
    final title = (hasResume && b?.label.isNotEmpty == true) ? b!.label : 'CHIEF EXPERIENCE OFFICER';
    final contact = hasResume ? '${b?.email ?? "e.smith@email.com"} | ${b?.location.city ?? "Indianapolis, Indiana"}' : 'e.smith@email.com | Indianapolis, Indiana';
    final summary = (hasResume && b?.summary.isNotEmpty == true) ? b!.summary : 'With over 15 years in customer experience, I excel in creating impactful strategies.';

    Widget sectionRuleTitle(String label) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16, thickness: 0.5, color: Colors.grey),
          Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Row(
                children: [
                   // --- Main Column ---
                   Expanded(
                     flex: 2,
                     child: Padding(
                       padding: const EdgeInsets.all(16),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                           Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w700)),
                           const SizedBox(height: 12),
                           Text(contact, style: const TextStyle(fontSize: 6, color: Colors.grey)),
                           
                           sectionRuleTitle('SUMMARY'),
                           Text(summary, style: const TextStyle(fontSize: 7, height: 1.4)),
                           
                           sectionRuleTitle('EXPERIENCE'),
                           if (resume != null && resume.work.isNotEmpty)
                               ...resume.work.take(2).map((w) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(w.position.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                                    Text(w.name, style: const TextStyle(fontSize: 7)),
                                  ],
                                ),
                              ))
                           else
                              ...List.generate(2, (i) => _miniEntry(height)),
                         ],
                       ),
                     ),
                   ),

                   // --- Sidebar ---
                   Container(
                     width: 90,
                     color: Colors.grey.shade100,
                     padding: const EdgeInsets.all(12),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         sectionRuleTitle('KEY ACHIEVEMENTS'),
                          if (resume != null && resume.awards.isNotEmpty)
                             ...resume.awards.take(2).map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(a.title, style: const TextStyle(fontSize: 6)),
                            ))
                         else
                            ...List.generate(3, (i) => _miniLine()),

                         sectionRuleTitle('SKILLS'),
                          if (resume != null && resume.skills.isNotEmpty)
                             ...resume.skills.take(5).map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(s.name, style: const TextStyle(fontSize: 6)),
                            ))
                         else
                            ...List.generate(4, (i) => _miniLine()),

                         sectionRuleTitle('EDUCATION'),
                          if (resume != null && resume.education.isNotEmpty)
                             ...resume.education.take(1).map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(e.area, style: const TextStyle(fontSize: 6)),
                            ))
                         else
                            _miniLine(),
                            
                         sectionRuleTitle('INTERESTS'),
                          if (resume != null && resume.interests.isNotEmpty)
                             ...resume.interests.take(2).map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(i.name, style: const TextStyle(fontSize: 6)),
                            ))
                         else
                            _miniLine(),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Professional Grand (template 19, variant 9) — teal two-column, specific schooling table preview.
  Widget _buildProfessionalGrandPreview(double height, JsonResume? resume, bool useMockData) {
    const designW = 280.0;
    const designH = 440.0;
    final hasResume = resume != null || useMockData;
    final b = resume?.basics;
    final name = hasResume ? _previewPersonName(b, fallback: 'MOHAMMED RAHIL B') : 'MOHAMMED RAHIL B';
    final teal = const Color(0xFF2AA198);
    final softTeal = const Color(0xFF5EB8B2);
    final displayPhone = hasResume
        ? ((b?.phone.trim().isNotEmpty ?? false) ? b!.phone.trim() : '+91 8431643600')
        : '+91 8431643600';
    final displayEmail = hasResume
        ? ((b?.email.trim().isNotEmpty ?? false) ? b!.email.trim() : 'rahil20160@gmail.com')
        : 'rahil20160@gmail.com';
    final summary = hasResume
        ? ((b?.summary.trim().isNotEmpty ?? false)
            ? b!.summary.trim()
            : 'I am a passionate tech enthusiast skilled in AI, ML, and full-stack development. With experience in creating innovative apps and AI-powered solutions, I aim to build practical tools that solve real-world challenges.')
        : 'I am a passionate tech enthusiast skilled in AI, ML, and full-stack development. With experience in creating innovative apps and AI-powered solutions, I aim to build practical tools that solve real-world challenges.';
    final displayLocation = hasResume
        ? [
            b?.location.city.trim() ?? '',
            b?.location.region.trim() ?? '',
          ].where((s) => s.isNotEmpty).join(', ').trim()
        : 'Davangere';
    final displayDob = hasResume
        ? ((b?.dateOfBirth.trim().isNotEmpty ?? false)
            ? b!.dateOfBirth.trim()
            : 'July 21, 2003')
        : 'July 21, 2003';
    final displayGender = hasResume
        ? ((b?.gender.trim().isNotEmpty ?? false) ? b!.gender.trim() : 'Male')
        : 'Male';
    final skills = (resume?.skills ?? const <Skill>[])
        .map((s) => s.name.trim())
        .where((s) => s.isNotEmpty)
        .take(7)
        .toList();
    final languages = (resume?.languages ?? const <Language>[])
        .map((l) => l.language.trim())
        .where((s) => s.isNotEmpty)
        .take(2)
        .toList();
    final certifications = (resume?.awards ?? const <Award>[])
        .map((c) => c.title.trim())
        .where((s) => s.isNotEmpty)
        .take(2)
        .toList();
    final internships = (resume?.volunteer ?? const <Volunteer>[]);
    final projects = (resume?.publications ?? const <Publication>[]);
    final work = (resume?.work ?? const <Work>[]);
    final education = (resume?.education ?? const <Education>[]);
    final graduation = education.isNotEmpty ? education.first : null;
    final schooling = education.length > 1 ? education.skip(1).take(2).toList() : const <Education>[];
    final projectEntries = projects.isNotEmpty
        ? projects.take(4).map((project) {
            final title = project.name.trim().isNotEmpty
                ? project.name.trim()
                : 'Untitled Project';
            final details = project.summary.trim().isNotEmpty
                ? project.summary.trim()
                : 'Built a polished project with strong problem solving and product thinking.';
            return {'title': title, 'details': details};
          }).toList()
        : const [
            {
              'title': 'JOBALLOCATE | February 2026 - March 2026',
              'details': 'I have created a job portal where people can apply for jobs and companies can post openings.',
            },
            {
              'title': 'Merakish Boutique | January 2026',
              'details': 'Created a modern ecommerce website for a boutique business.',
            },
            {
              'title': 'Garhelp App | July 2025 - September 2025',
              'details': 'Built a home services app focused on ease of booking and user experience.',
            },
            {
              'title': 'AI Powered Interior Designer | March 2025 - September 2025',
              'details': 'Designed a virtual interior planning experience powered by AI.',
            },
          ];
    final workEntries = work.isNotEmpty
        ? work.take(2).map((job) {
            final title = job.name.trim().isNotEmpty ? job.name.trim() : 'Company';
            final subtitle = job.position.trim().isNotEmpty
                ? job.position.trim()
                : 'Professional Role';
            final details = job.summary.trim().isNotEmpty
                ? job.summary.trim()
                : 'Delivered high-quality work, collaborated with teams, and built practical solutions.';
            return {'title': title, 'subtitle': subtitle, 'details': details};
          }).toList()
        : const [
            {
              'title': 'THINKZEAL | September 2024 - February 2026',
              'subtitle': 'Fullstack Developer',
              'details': 'Built websites and apps, improved user journeys, and supported end-to-end feature delivery.',
            },
          ];

    Widget grandSectionTitle(String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Container(height: 1.5, color: Colors.black),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: designW,
              height: designH,
              child: Row(
                children: [
                  Container(
                    width: 92,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300, width: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade100, Colors.grey.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 34,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        grandSectionTitle('GET IN TOUCH!'),
                        Text(
                          'Mobile:',
                          style: TextStyle(
                            fontSize: 5.8,
                            fontWeight: FontWeight.w800,
                            color: teal,
                          ),
                        ),
                        Text(displayPhone, style: const TextStyle(fontSize: 5.4)),
                        const SizedBox(height: 5),
                        Text(
                          'Email:',
                          style: TextStyle(
                            fontSize: 5.8,
                            fontWeight: FontWeight.w800,
                            color: teal,
                          ),
                        ),
                        Text(
                          displayEmail,
                          style: const TextStyle(fontSize: 5.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        grandSectionTitle('SKILLS'),
                        ...(skills.isNotEmpty
                            ? skills.map(
                                (skill) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '- $skill',
                                    style: const TextStyle(fontSize: 5.4),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : [
                                const Text('- DSA', style: TextStyle(fontSize: 5.4)),
                                const Text('- Front End Design', style: TextStyle(fontSize: 5.4)),
                                const Text('- Backend', style: TextStyle(fontSize: 5.4)),
                                const Text('- Deployment', style: TextStyle(fontSize: 5.4)),
                                const Text('- Machine Learning', style: TextStyle(fontSize: 5.4)),
                              ]),
                        grandSectionTitle('LANGUAGES KNOWN'),
                        Text(
                          languages.isNotEmpty ? languages.join(' | ') : 'English | Both',
                          style: const TextStyle(fontSize: 5.4),
                        ),
                        grandSectionTitle('CERTIFICATIONS'),
                        ...(certifications.isNotEmpty
                            ? certifications.map(
                                (cert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '- $cert',
                                    style: const TextStyle(fontSize: 5.2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : [
                                const Text(
                                  '- Data Analyst And Job Stimulation',
                                  style: TextStyle(fontSize: 5.1),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: softTeal,
                              letterSpacing: 0.2,
                            ),
                          ),
                          grandSectionTitle('RESUME SUMMARY'),
                          Text(
                            summary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 5.8, height: 1.35),
                          ),
                          grandSectionTitle('PERSONAL DETAILS'),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Current Location    ${displayLocation.isNotEmpty ? displayLocation : 'Davangere'}\nDate of Birth         $displayDob\n$displayGender',
                                  style: const TextStyle(fontSize: 5.6, height: 1.45),
                                ),
                              ),
                            ],
                          ),
                          grandSectionTitle('EDUCATION'),
                          Text(
                            'Graduation',
                            style: TextStyle(
                              fontSize: 6.2,
                              fontWeight: FontWeight.w800,
                              color: softTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Course                ${graduation?.studyType.trim().isNotEmpty == true ? graduation!.studyType.trim() : 'B.Tech/B.E. - Bachelor of Technology / Engineering'}',
                            style: const TextStyle(fontSize: 5.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Specialization     ${graduation?.area.trim().isNotEmpty == true ? graduation!.area.trim() : 'Artificial Intelligence & Machine Learning'}',
                            style: const TextStyle(fontSize: 5.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'College               ${graduation?.institution.trim().isNotEmpty == true ? graduation!.institution.trim() : 'Bapuji Institute of Engineering and Technology'}',
                            style: const TextStyle(fontSize: 5.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Score                 ${graduation?.score.trim().isNotEmpty == true ? graduation!.score.trim() : '7.8%'}',
                            style: const TextStyle(fontSize: 5.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Schooling',
                            style: TextStyle(
                              fontSize: 6.2,
                              fontWeight: FontWeight.w800,
                              color: softTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(schooling.isNotEmpty ? 'Class XII' : 'Class XII', style: const TextStyle(fontSize: 5.2, fontWeight: FontWeight.w700))),
                                    Expanded(child: Text(schooling.length > 1 ? 'Class X' : 'Class X', style: const TextStyle(fontSize: 5.2, fontWeight: FontWeight.w700))),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(child: Text(schooling.isNotEmpty && schooling.first.institution.trim().isNotEmpty ? schooling.first.institution.trim() : 'Karnataka', style: const TextStyle(fontSize: 5.0))),
                                    Expanded(child: Text(schooling.length > 1 && schooling[1].institution.trim().isNotEmpty ? schooling[1].institution.trim() : 'Karnataka', style: const TextStyle(fontSize: 5.0))),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(child: Text(schooling.isNotEmpty && schooling.first.area.trim().isNotEmpty ? schooling.first.area.trim() : 'English', style: const TextStyle(fontSize: 5.0))),
                                    Expanded(child: Text(schooling.length > 1 && schooling[1].area.trim().isNotEmpty ? schooling[1].area.trim() : 'English', style: const TextStyle(fontSize: 5.0))),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(child: Text(schooling.isNotEmpty && schooling.first.endDate.trim().isNotEmpty ? schooling.first.endDate.trim() : '2021', style: const TextStyle(fontSize: 5.0))),
                                    Expanded(child: Text(schooling.length > 1 && schooling[1].endDate.trim().isNotEmpty ? schooling[1].endDate.trim() : '2019', style: const TextStyle(fontSize: 5.0))),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(child: Text(schooling.isNotEmpty && schooling.first.score.trim().isNotEmpty ? schooling.first.score.trim() : '91.3%', style: const TextStyle(fontSize: 5.0))),
                                    Expanded(child: Text(schooling.length > 1 && schooling[1].score.trim().isNotEmpty ? schooling[1].score.trim() : '87.2%', style: const TextStyle(fontSize: 5.0))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          grandSectionTitle('INTERNSHIPS'),
                          Text(
                            internships.isNotEmpty
                                ? internships.first.organization
                                : 'NULL CLASSES | April 2025 - October 2025',
                            style: TextStyle(
                              fontSize: 5.8,
                              fontWeight: FontWeight.w800,
                              color: softTeal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            internships.isNotEmpty
                                ? '- ${internships.first.position}${internships.first.summary.trim().isNotEmpty ? ' | ${internships.first.summary.trim()}' : ''}'
                                : '- I have worked on many realtime projects and strengthened my problem-solving skills.',
                            style: const TextStyle(fontSize: 5.15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          grandSectionTitle('PROJECTS'),
                          ...projectEntries.map(
                            (project) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project['title']!,
                                    style: TextStyle(
                                      fontSize: 5.8,
                                      fontWeight: FontWeight.w800,
                                      color: softTeal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '- ${project['details']!}',
                                    style: const TextStyle(fontSize: 5.1),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          grandSectionTitle('WORK EXPERIENCE'),
                          ...workEntries.map(
                            (job) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job['title']!,
                                    style: TextStyle(
                                      fontSize: 5.8,
                                      fontWeight: FontWeight.w800,
                                      color: softTeal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '- ${job['subtitle']!}${job['details']!.isNotEmpty ? ' | ${job['details']!}' : ''}',
                                    style: const TextStyle(fontSize: 5.1),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Naukri Realtime Pro (template 24, variant 10) — exact two-column portal-style resume preview.
  Widget _buildNaukriRealtimePreview(double height, JsonResume? resume, bool useMockData) {
    // Keep same proven miniature renderer used by variant 9, but as a dedicated
    // template id/variant so product can evolve it independently.
    return _buildProfessionalGrandPreview(height, resume, useMockData);
  }
}
