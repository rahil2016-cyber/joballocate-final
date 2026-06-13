import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/media_url.dart';
import '../models/resume_model.dart';
import '../resume_ats_presets.dart';

Color get resumeOneDivider => const Color(0xFFE0E0E0);

/// A4 at ~96 logical px (matches common CSS print sizing).
const double kResumeA4Width = 794;
const double kResumeA4Height = 1123;

/// Margins — generous like print résumés (reference: Mohammed Rahil layout).
const double _pagePadH = 20;
const double _pagePadV = 24;
/// ~30% column for sidebar / ~70% main (A4 content area).
const double _sidebarW = 232;
const double _colGap = 14;

/// Inner width of main column (fixed; never [Expanded]).
double get _resumeMainInnerWidth =>
    kResumeA4Width - 2 * _pagePadH - _sidebarW - _colGap;

/// Typography — tuned to match professional teal two-column résumé reference.
const double _fontName = 31;
const double _fontSection = 13.5;
const double _fontSubHead = 13;
const double _fontBody = 11.5;
const double _fontSmall = 10;

const double _spaceSection = 14;
const double _spaceSm = 8;
const double _spaceXs = 4;

/// Fixed A4 resume page (794×1123). Used by builder preview + thumbnails.
/// Layout uses fixed widths only — no [Expanded] / [Flexible] inside the template.
class ResumeOneA4Sheet extends StatelessWidget {
  ResumeOneA4Sheet({
    super.key,
    required this.model,
    Color? accent,
  }) : accent = accent ?? accentColorForDesignVariant(kResumeAtsVariantMin);

  final ResumeModel model;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kResumeA4Width,
      height: kResumeA4Height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePadH, vertical: _pagePadV),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: _sidebarW, child: _SidebarColumn(model: model, accent: accent)),
              const SizedBox(width: _colGap),
              SizedBox(
                width: _resumeMainInnerWidth,
                child: _MainColumn(model: model, accent: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back-compat wrapper — renders [ResumeOneA4Sheet]. [maxWidth] is ignored.
class ResumeOneLivePreview extends StatelessWidget {
  const ResumeOneLivePreview({
    super.key,
    required this.model,
    this.maxWidth = 640,
    this.accent,
  });

  final ResumeModel model;

  /// Deprecated: layout is always A4 width; kept for call-site compatibility.
  final double maxWidth;

  final Color? accent;

  @override
  Widget build(BuildContext context) => ResumeOneA4Sheet(model: model, accent: accent);
}

class _SidebarColumn extends StatelessWidget {
  const _SidebarColumn({required this.model, required this.accent});

  final ResumeModel model;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bodySmall = _styleSmall();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _sidebarW,
          child: Center(child: _Avatar(model: model, diameter: 86, accent: accent)),
        ),
        const SizedBox(height: _spaceSection),
        if (model.sectionVisible[ResumeSectionKeys.sidebar] ?? true) ...[
          _SectionHeader(title: 'GET IN TOUCH!'),
          _LabelValue(label: 'Mobile:', value: model.contact.mobile, accent: accent),
          _LabelValue(label: 'Email:', value: model.contact.email, accent: accent),
        ],
        if (model.sectionVisible[ResumeSectionKeys.skills] ?? true) ...[
          SizedBox(height: model.sectionVisible[ResumeSectionKeys.sidebar] ?? true ? _spaceSm : 0),
          _SectionHeader(title: 'SKILLS'),
          ...model.skills.where((s) => s.trim().isNotEmpty).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '- $s',
                    style: bodySmall,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
        if (model.sectionVisible[ResumeSectionKeys.languages] ?? true) ...[
          const SizedBox(height: _spaceSm),
          _SectionHeader(title: 'LANGUAGES KNOWN'),
          Text(
            model.languages.where((e) => e.trim().isNotEmpty).join(', '),
            style: _styleBody(),
          ),
        ],
        if (model.sectionVisible[ResumeSectionKeys.certifications] ?? true) ...[
          const SizedBox(height: _spaceSm),
          _SectionHeader(title: 'CERTIFICATIONS'),
          ...model.certifications.where((s) => s.trim().isNotEmpty).map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '- $s',
                    style: bodySmall,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.openSans(
            fontSize: _fontSection,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.85,
            color: Colors.black87,
            height: 1.25,
          ),
        ),
        const SizedBox(height: _spaceXs),
        Container(height: 1, color: resumeOneDivider),
        const SizedBox(height: _spaceSm),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _spaceXs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          textAlign: TextAlign.left,
          text: TextSpan(
            style: _styleBody(),
            children: [
              TextSpan(
                text: '$label ',
                style: GoogleFonts.openSans(
                  fontSize: _fontBody,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _styleBody() => GoogleFonts.openSans(fontSize: _fontBody, height: 1.35, color: Colors.black87);

TextStyle _styleSmall() => GoogleFonts.openSans(fontSize: _fontSmall, height: 1.35, color: Colors.black87);

class _Avatar extends StatelessWidget {
  const _Avatar({required this.model, required this.diameter, required this.accent});

  final ResumeModel model;
  final double diameter;
  final Color accent;

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
      backgroundColor: resumeOneDivider,
      child: Icon(Icons.person_outline, color: accent, size: radius * 0.9),
    );
  }
}

class _MainColumn extends StatelessWidget {
  const _MainColumn({required this.model, required this.accent});

  final ResumeModel model;
  final Color accent;

  TextStyle _subHeadAccent() => GoogleFonts.openSans(
        color: accent,
        fontWeight: FontWeight.w700,
        fontSize: _fontSubHead,
      );

  @override
  Widget build(BuildContext context) {
    final mainW = _resumeMainInnerWidth;
    final nameStyle = GoogleFonts.openSans(
      fontSize: _fontName,
      fontWeight: FontWeight.w800,
      color: accent,
      letterSpacing: -0.3,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          model.fullName.trim().isEmpty ? '\u00A0' : model.fullName,
          style: nameStyle,
        ),
        if (model.professionalTitle.trim().isNotEmpty) ...[
          const SizedBox(height: _spaceXs),
          Text(
            model.professionalTitle,
            style: GoogleFonts.openSans(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: _fontSubHead,
            ),
          ),
        ],
        const SizedBox(height: _spaceSection + 2),
        if (model.sectionVisible[ResumeSectionKeys.summary] ?? true) ...[
          const _SectionHeader(title: 'Resume summary'),
          Text(model.summary, style: _styleBody()),
          const SizedBox(height: _spaceSection),
        ],
        if (model.sectionVisible[ResumeSectionKeys.personal] ?? true) ...[
          const _SectionHeader(title: 'Personal details'),
          _PersonalDetailsTable(rows: model.personalDetails, totalWidth: mainW, accent: accent),
          const SizedBox(height: _spaceSection),
        ],
        if (model.sectionVisible[ResumeSectionKeys.education] ?? true) ...[
          const _SectionHeader(title: 'Education'),
          Text('Graduation', style: _subHeadAccent()),
          const SizedBox(height: _spaceXs + 2),
          _GraduationRows(g: model.education.graduation, valueWidth: mainW - 88, accent: accent),
          const SizedBox(height: _spaceSm + 4),
          Text('Schooling', style: _subHeadAccent()),
          const SizedBox(height: _spaceXs + 2),
          _SchoolingTable(model: model, accent: accent),
          const SizedBox(height: _spaceSection),
        ],
        if (model.sectionVisible[ResumeSectionKeys.internships] ?? true &&
            model.internships.isNotEmpty) ...[
          const _SectionHeader(title: 'Internships'),
          ...model.internships.map((e) => _ExpBlock(item: e, contentWidth: mainW, accent: accent)),
        ],
        if (model.sectionVisible[ResumeSectionKeys.projects] ?? true && model.projects.isNotEmpty) ...[
          const _SectionHeader(title: 'Projects'),
          ...model.projects.map((e) => _ExpBlock(item: e, contentWidth: mainW, accent: accent)),
        ],
        if (model.sectionVisible[ResumeSectionKeys.work] ?? true &&
            model.workExperience.isNotEmpty) ...[
          const _SectionHeader(title: 'Work experience'),
          ...model.workExperience.map((e) => _ExpBlock(item: e, contentWidth: mainW, accent: accent)),
        ],
        if (model.sectionVisible[ResumeSectionKeys.custom] ?? true &&
            model.extraSections.isNotEmpty)
          for (final sec in model.extraSections) ...[
            if (sec.title.trim().isNotEmpty ||
                sec.lines.any((l) => l.trim().isNotEmpty)) ...[
              _SectionHeader(
                title: sec.title.trim().isEmpty ? 'SECTION' : sec.title.toUpperCase(),
              ),
              for (final line in sec.lines)
                if (line.trim().isNotEmpty)
                  _BulletLine(text: line, width: mainW - 12),
              const SizedBox(height: _spaceSm),
            ],
          ],
      ],
    );
  }
}

/// Label / value rows — matches reference “Graduation” grid (teal label, black value).
class _GraduationRows extends StatelessWidget {
  const _GraduationRows({required this.g, required this.valueWidth, required this.accent});

  final GraduationBlock g;
  final double valueWidth;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) {
      if (label.trim().isEmpty && value.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                '$label:',
                style: GoogleFonts.openSans(
                  fontSize: _fontBody,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            SizedBox(
              width: valueWidth,
              child: Text(value, style: _styleBody()),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Course', g.course),
        row('College', g.college),
        row('Score', g.score),
      ],
    );
  }
}

/// Two-column personal grid like reference résumé (pairs read left→right).
class _PersonalDetailsTable extends StatelessWidget {
  const _PersonalDetailsTable({required this.rows, required this.totalWidth, required this.accent});

  final List<PersonalDetailRow> rows;
  final double totalWidth;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final items = rows.where((r) => r.label.trim().isNotEmpty || r.value.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final half = (totalWidth - 10) / 2;
    Widget cell(PersonalDetailRow r) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            style: _styleBody(),
            children: [
              TextSpan(
                text: '${r.label}: ',
                style: GoogleFonts.openSans(
                  fontSize: _fontBody,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
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
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: cell(items[i]),
            ),
            if (i + 1 < items.length)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: cell(items[i + 1]),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Table(
      columnWidths: {
        0: FixedColumnWidth(half),
        1: FixedColumnWidth(half),
      },
      children: tableRows,
    );
  }
}

class _SchoolingTable extends StatelessWidget {
  const _SchoolingTable({required this.model, required this.accent});

  final ResumeModel model;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s12 = model.education.schooling.class12;
    final s10 = model.education.schooling.class10;
    final total = _resumeMainInnerWidth;
    const labelCol = 120.0;
    final dataCol = ((total - labelCol) / 2).clamp(140.0, 320.0);

    Widget cell(String t, {bool header = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: _spaceSm, vertical: 7),
          child: header
              ? Center(
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: _fontSmall,
                    ),
                  ),
                )
              : Text(t, style: _styleSmall()),
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
        TableRow(
          children: [
            cell('Board Name'),
            cell(s12.boardName),
            cell(s10.boardName),
          ],
        ),
        TableRow(
          children: [
            cell('Medium'),
            cell(s12.medium),
            cell(s10.medium),
          ],
        ),
        TableRow(
          children: [
            cell('Year of Passing'),
            cell(s12.yearOfPassing),
            cell(s10.yearOfPassing),
          ],
        ),
        TableRow(
          children: [
            cell('Score'),
            cell(s12.score),
            cell(s10.score),
          ],
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: _spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Text('- ', style: _styleBody()),
          ),
          SizedBox(
            width: width,
            child: Text(text, style: _styleBody()),
          ),
        ],
      ),
    );
  }
}

class _ExpBlock extends StatelessWidget {
  const _ExpBlock({required this.item, required this.contentWidth, required this.accent});

  final ExperienceItem item;
  final double contentWidth;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final company = item.companyName.trim();
    final dates = item.dateRange.trim();
    final bulletTextW = contentWidth - 20;
    return Padding(
      padding: const EdgeInsets.only(bottom: _spaceSection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (company.isNotEmpty)
            Text(
              company,
              style: GoogleFonts.openSans(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: _fontBody + 0.5,
                height: 1.2,
              ),
            ),
          if (dates.isNotEmpty) ...[
            SizedBox(height: company.isNotEmpty ? 2 : 0),
            Text(
              dates,
              style: GoogleFonts.openSans(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: _fontSmall + 0.5,
                height: 1.2,
              ),
            ),
          ],
          if ((company.isNotEmpty || dates.isNotEmpty) &&
              item.bullets.any((b) => b.trim().isNotEmpty))
            const SizedBox(height: 6),
          ...item.bullets.where((b) => b.trim().isNotEmpty).map(
                (b) => Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 14, child: Text('- ', style: _styleBody())),
                      SizedBox(
                        width: bulletTextW,
                        child: Text(b, style: _styleBody()),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
