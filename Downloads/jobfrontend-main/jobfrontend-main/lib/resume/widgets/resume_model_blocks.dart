import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/utils/media_url.dart';

import 'resume_typography.dart';

class ResumeAvatar extends StatelessWidget {
  const ResumeAvatar({
    super.key,
    required this.model,
    required this.diameter,
    required this.accent,
    required this.typography,
  });

  final ResumeModel model;
  final double diameter;
  final Color accent;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final r = diameter / 2;
    final b64 = model.profileImageBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        return CircleAvatar(radius: r, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    final url = model.profileImageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      final resolved = MediaUrl.resolve(url) ?? url;
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: resolved,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _placeholder(r),
        ),
      );
    }
    return _placeholder(r);
  }

  Widget _placeholder(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: typography.secondary.withValues(alpha: 0.15),
      child: Icon(Icons.person_outline, color: accent, size: radius * 0.9),
    );
  }
}

class ResumeDivider extends StatelessWidget {
  const ResumeDivider({super.key, required this.typography});

  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(height: 1, color: typography.secondary.withValues(alpha: 0.22)),
    );
  }
}

class ResumeSectionCaps extends StatelessWidget {
  const ResumeSectionCaps({super.key, required this.title, required this.typography});

  final String title;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.trim().toUpperCase(), style: typography.sectionCaps()),
        ResumeDivider(typography: typography),
      ],
    );
  }
}

class ResumeContactLine extends StatelessWidget {
  const ResumeContactLine({
    super.key,
    required this.mobile,
    required this.email,
    required this.typography,
    this.center = false,
  });

  final String mobile;
  final String email;
  final ResumeTypography typography;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (mobile.trim().isNotEmpty) parts.add(mobile.trim());
    if (email.trim().isNotEmpty) parts.add(email.trim());
    if (parts.isEmpty) return const SizedBox.shrink();
    final text = Text(
      parts.join(' · '),
      style: typography.caption(11),
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
    return center ? Center(child: text) : text;
  }
}

class ResumeSkillsBlock extends StatelessWidget {
  const ResumeSkillsBlock({super.key, required this.skills, required this.typography, this.compact = false});

  final List<String> skills;
  final ResumeTypography typography;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final list = skills.where((s) => s.trim().isNotEmpty).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    if (compact) {
      return Text(list.join(' · '), style: typography.body(10));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $s', style: typography.body()),
            ),
          )
          .toList(),
    );
  }
}

class ResumeBulletStrings extends StatelessWidget {
  const ResumeBulletStrings({super.key, required this.lines, required this.typography});

  final List<String> lines;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final filtered = lines.where((s) => s.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtered
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('- ', style: typography.body()),
                  Expanded(child: Text(line.trim(), style: typography.body())),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class ResumeExperienceTile extends StatelessWidget {
  const ResumeExperienceTile({super.key, required this.item, required this.typography});

  final ExperienceItem item;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final company = item.companyName.trim();
    final dates = item.dateRange.trim();
    final bullets = item.bullets.where((b) => b.trim().isNotEmpty).toList();
    if (company.isEmpty && dates.isEmpty && bullets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (company.isNotEmpty)
            Text(company, style: typography.accentText(11.5, FontWeight.w800)),
          if (dates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(dates, style: typography.accentText(10, FontWeight.w600)),
            ),
          ResumeBulletStrings(lines: bullets, typography: typography),
        ],
      ),
    );
  }
}

class ResumeEducationStandard extends StatelessWidget {
  const ResumeEducationStandard({super.key, required this.model, required this.typography});

  final ResumeModel model;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final g = model.education.graduation;
    final s12 = model.education.schooling.class12;
    final s10 = model.education.schooling.class10;

    Widget row(String label, String value) {
      if (label.trim().isEmpty && value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 84,
              child: Text(
                '$label:',
                style: typography.accentText(11, FontWeight.w700),
              ),
            ),
            Expanded(child: Text(value, style: typography.body())),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Graduation', style: typography.accentText(12.5, FontWeight.w700)),
        const SizedBox(height: 4),
        row('Course', g.course),
        row('College', g.college),
        row('Score', g.score),
        const SizedBox(height: 10),
        Text('Schooling', style: typography.accentText(12.5, FontWeight.w700)),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, cons) {
            final inner = cons.maxWidth.isFinite ? cons.maxWidth : (794 - 44);
            final labelCol = 110.0;
            final dataCol = ((inner - labelCol) / 2).clamp(130.0, 290.0);
            Widget cell(String t, {bool header = false}) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: header
                      ? Center(
                          child: Text(
                            t,
                            textAlign: TextAlign.center,
                            style: typography.accentText(10, FontWeight.w700),
                          ),
                        )
                      : Text(t, style: typography.caption(10)),
                );

            return Table(
              columnWidths: {
                0: FixedColumnWidth(labelCol),
                1: FixedColumnWidth(dataCol),
                2: FixedColumnWidth(dataCol),
              },
              children: [
                TableRow(
                  children: [
                    cell(''),
                    cell('Class XII', header: true),
                    cell('Class X', header: true),
                  ],
                ),
                TableRow(children: [cell('Board'), cell(s12.boardName), cell(s10.boardName)]),
                TableRow(children: [cell('Medium'), cell(s12.medium), cell(s10.medium)]),
                TableRow(children: [cell('Year'), cell(s12.yearOfPassing), cell(s10.yearOfPassing)]),
                TableRow(children: [cell('Score'), cell(s12.score), cell(s10.score)]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ResumePersonalGrid extends StatelessWidget {
  const ResumePersonalGrid({super.key, required this.rows, required this.typography});

  final List<PersonalDetailRow> rows;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final items = rows.where((r) => r.label.trim().isNotEmpty || r.value.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    Widget cell(PersonalDetailRow r) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            style: typography.body(),
            children: [
              TextSpan(
                text: '${r.label}: ',
                style: typography.accentText(11, FontWeight.w700),
              ),
              TextSpan(text: r.value),
            ],
          ),
        ),
      );
    }

    final tableRows = <TableRow>[];
    for (var i = 0; i < items.length; i += 2) {
      tableRows.add(
        TableRow(
          children: [
            Padding(padding: const EdgeInsets.only(right: 6), child: cell(items[i])),
            if (i + 1 < items.length)
              Padding(padding: const EdgeInsets.only(left: 6), child: cell(items[i + 1]))
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: tableRows,
    );
  }
}

class ResumeLanguagesCerts extends StatelessWidget {
  const ResumeLanguagesCerts({
    super.key,
    required this.languages,
    required this.certifications,
    required this.typography,
  });

  final List<String> languages;
  final List<String> certifications;
  final ResumeTypography typography;

  @override
  Widget build(BuildContext context) {
    final langText = languages.where((s) => s.trim().isNotEmpty).join(', ');
    final certs = certifications.where((s) => s.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (langText.isNotEmpty) Text(langText, style: typography.body()),
        if (certs.isNotEmpty) ...[
          if (langText.isNotEmpty) const SizedBox(height: 6),
          ResumeBulletStrings(lines: certs, typography: typography),
        ],
      ],
    );
  }
}
