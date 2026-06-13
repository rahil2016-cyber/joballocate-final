import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_model.dart';

final PdfColor resumeDividerGrey = PdfColors.grey400;

PdfColor _defaultResumeAccentPdf() => PdfColor(13 / 255, 115 / 255, 119 / 255);

pw.Widget _rule() => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Container(height: 0.7, color: resumeDividerGrey),
    );

pw.TextStyle _capsHeader(pw.Font font) => pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.6,
      color: PdfColors.black,
    );

pw.TextStyle _accentBold(pw.Font font, double size, PdfColor accent) => pw.TextStyle(
      font: font,
      fontSize: size,
      fontWeight: pw.FontWeight.bold,
      color: accent,
    );

pw.TextStyle _body(pw.Font font, [double size = 11]) => pw.TextStyle(font: font, fontSize: size, color: PdfColors.black);

pw.Widget _labeled(String label, String value, pw.Font font, PdfColor accent) {
  final lv = label.trim();
  final vv = value.trim();
  if (lv.isEmpty && vv.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (lv.isNotEmpty)
          pw.Text('$lv ', style: _accentBold(font, 11, accent))
        else
          pw.SizedBox(),
        pw.Expanded(child: pw.Text(vv, style: _body(font))),
      ],
    ),
  );
}

pw.Widget _bulletLine(String line, pw.Font font) {
  final t = line.trim();
  if (t.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('- ', style: _body(font)),
        pw.Expanded(child: pw.Text(t, style: _body(font))),
      ],
    ),
  );
}

pw.Widget _experienceBlock(ExperienceItem item, pw.Font font, PdfColor accent) {
  final company = item.companyName.trim();
  final dates = item.dateRange.trim();
  final children = <pw.Widget>[
    if (company.isNotEmpty)
      pw.Text(company, style: _accentBold(font, 11.5, accent)),
    if (dates.isNotEmpty)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2, bottom: 2),
        child: pw.Text(
          dates,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: accent,
          ),
        ),
      ),
    if ((company.isNotEmpty || dates.isNotEmpty) && item.bullets.any((b) => b.trim().isNotEmpty))
      pw.SizedBox(height: 4),
    ...item.bullets.map((b) => _bulletLine(b, font)),
  ];
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
  );
}

pw.Widget _graduationPdfRow(String label, String value, pw.Font font, PdfColor accent) {
  final lv = label.trim();
  final vv = value.trim();
  if (lv.isEmpty && vv.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 74, child: pw.Text('$lv:', style: _accentBold(font, 10, accent))),
        pw.Expanded(child: pw.Text(vv, style: _body(font, 10))),
      ],
    ),
  );
}

pw.Widget _personalDetailCell(PersonalDetailRow row, pw.Font font, PdfColor accent) {
  final lv = row.label.trim();
  final vv = row.value.trim();
  if (lv.isEmpty && vv.isEmpty) return pw.SizedBox();
  return pw.RichText(
    text: pw.TextSpan(
      style: _body(font, 10),
      children: [
        pw.TextSpan(text: '$lv: ', style: _accentBold(font, 10, accent)),
        pw.TextSpan(text: vv),
      ],
    ),
  );
}

/// Builds ATS-friendly widgets: standard fonts, clear hierarchy, no scanned-image dependencies.
List<pw.Widget> buildResumeOnePdf(
  ResumeModel r, {
  Uint8List? profileBytes,
  PdfColor? accent,
}) {
  final PdfColor acc = accent ?? _defaultResumeAccentPdf();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();

  pw.ImageProvider? avatar;
  if (profileBytes != null && profileBytes.isNotEmpty) {
    try {
      avatar = pw.MemoryImage(profileBytes);
    } catch (_) {}
  }

  final sidebar = pw.Container(
    padding: const pw.EdgeInsets.only(right: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (avatar != null)
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              image: pw.DecorationImage(image: avatar, fit: pw.BoxFit.cover),
            ),
          )
        else
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: resumeDividerGrey),
            ),
          ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GET IN TOUCH!', style: _capsHeader(fontBold)),
              _rule(),
              _labeled('Mobile:', r.contact.mobile, font, acc),
              _labeled('Email:', r.contact.email, font, acc),
              pw.SizedBox(height: 10),
              if (r.sectionVisible[ResumeSectionKeys.skills] ?? true) ...[
                pw.Text('SKILLS', style: _capsHeader(fontBold)),
                _rule(),
                ...r.skills
                    .where((s) => s.trim().isNotEmpty)
                    .map((s) => _bulletLine(s, font)),
                pw.SizedBox(height: 10),
              ],
              if (r.sectionVisible[ResumeSectionKeys.languages] ?? true) ...[
                pw.Text('LANGUAGES KNOWN', style: _capsHeader(fontBold)),
                _rule(),
                pw.Text(r.languages.join(', '), style: _body(font)),
                pw.SizedBox(height: 10),
              ],
              if (r.sectionVisible[ResumeSectionKeys.certifications] ?? true) ...[
                pw.Text('CERTIFICATIONS', style: _capsHeader(fontBold)),
                _rule(),
                ...r.certifications
                    .where((s) => s.trim().isNotEmpty)
                    .map((s) => _bulletLine(s, font)),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  final pdItems = r.personalDetails
      .where((e) => e.label.trim().isNotEmpty || e.value.trim().isNotEmpty)
      .toList();

  final main = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        r.fullName.trim().isEmpty ? ' ' : r.fullName.trim(),
        style: pw.TextStyle(font: fontBold, fontSize: 28, color: acc),
      ),
      if (r.professionalTitle.trim().isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(
          r.professionalTitle.trim(),
          style: pw.TextStyle(font: fontBold, fontSize: 13, color: acc),
        ),
      ],
      pw.SizedBox(height: 12),
      if (r.sectionVisible[ResumeSectionKeys.summary] ?? true) ...[
        pw.Text('RESUME SUMMARY', style: _capsHeader(fontBold)),
        _rule(),
        pw.Text(r.summary.trim(), style: _body(font, 11)),
        pw.SizedBox(height: 10),
      ],
      if (r.sectionVisible[ResumeSectionKeys.personal] ?? true) ...[
        pw.Text('PERSONAL DETAILS', style: _capsHeader(fontBold)),
        _rule(),
        if (pdItems.isNotEmpty)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < pdItems.length; i += 2)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: _personalDetailCell(pdItems[i], font, acc)),
                      if (i + 1 < pdItems.length)
                        pw.Expanded(child: _personalDetailCell(pdItems[i + 1], font, acc)),
                    ],
                  ),
                ),
            ],
          ),
        pw.SizedBox(height: 10),
      ],
      if (r.sectionVisible[ResumeSectionKeys.education] ?? true) ...[
        pw.Text('EDUCATION', style: _capsHeader(fontBold)),
        _rule(),
        pw.Text('Graduation', style: _accentBold(font, 12, acc)),
        pw.SizedBox(height: 4),
        _graduationPdfRow('Course', r.education.graduation.course, font, acc),
        _graduationPdfRow('College', r.education.graduation.college, font, acc),
        _graduationPdfRow('Score', r.education.graduation.score, font, acc),
        pw.SizedBox(height: 8),
        pw.Text('Schooling', style: _accentBold(font, 12, acc)),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: {
            0: const pw.FixedColumnWidth(92),
            1: const pw.FixedColumnWidth(128),
            2: const pw.FixedColumnWidth(128),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox()),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(child: pw.Text('Class XII', style: _accentBold(font, 10, acc))),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(child: pw.Text('Class X', style: _accentBold(font, 10, acc))),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Board Name', style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class12.boardName, style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class10.boardName, style: _body(font, 10)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Medium', style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class12.medium, style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class10.medium, style: _body(font, 10)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Year of Passing', style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class12.yearOfPassing, style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class10.yearOfPassing, style: _body(font, 10)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Score', style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class12.score, style: _body(font, 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r.education.schooling.class10.score, style: _body(font, 10)),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
      if (r.sectionVisible[ResumeSectionKeys.internships] ?? true && r.internships.isNotEmpty) ...[
        pw.Text('INTERNSHIPS', style: _capsHeader(fontBold)),
        _rule(),
        ...r.internships.map((e) => _experienceBlock(e, font, acc)),
      ],
      if (r.sectionVisible[ResumeSectionKeys.projects] ?? true && r.projects.isNotEmpty) ...[
        pw.Text('PROJECTS', style: _capsHeader(fontBold)),
        _rule(),
        ...r.projects.map((e) => _experienceBlock(e, font, acc)),
      ],
      if (r.sectionVisible[ResumeSectionKeys.work] ?? true && r.workExperience.isNotEmpty) ...[
        pw.Text('WORK EXPERIENCE', style: _capsHeader(fontBold)),
        _rule(),
        ...r.workExperience.map((e) => _experienceBlock(e, font, acc)),
      ],
      if (r.sectionVisible[ResumeSectionKeys.custom] ?? true && r.extraSections.isNotEmpty) ...[
        for (final sec in r.extraSections) ...[
          if (sec.title.trim().isNotEmpty ||
              sec.lines.any((line) => line.trim().isNotEmpty)) ...[
            pw.Text(
              sec.title.trim().isEmpty ? 'SECTION' : sec.title.toUpperCase(),
              style: _capsHeader(fontBold),
            ),
            _rule(),
            for (final line in sec.lines)
              if (line.trim().isNotEmpty) _bulletLine(line, font),
            pw.SizedBox(height: 8),
          ],
        ],
      ],
    ],
  );

  /// Sidebar ~30% / main ~70% of printable row (~539pt).
  return [
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 165, child: sidebar),
        pw.SizedBox(width: 10),
        pw.SizedBox(width: 364, child: main),
      ],
    ),
  ];
}
