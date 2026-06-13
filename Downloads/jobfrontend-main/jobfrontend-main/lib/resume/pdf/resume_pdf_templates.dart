import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:joballocate/features/resume/models/resume_model.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_builder_ids.dart';
import '../models/resume_studio_appearance.dart';

PdfColor _pc(Color c) => PdfColor(c.r, c.g, c.b);

pw.Widget _rule(PdfColor divider) =>
    pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: pw.Container(height: 0.7, color: divider));

pw.TextStyle _boldAccent(pw.Font bold, double size, PdfColor accent) =>
    pw.TextStyle(font: bold, fontSize: size, color: accent);

pw.TextStyle _body(pw.Font font, double size, PdfColor ink) =>
    pw.TextStyle(font: font, fontSize: size, color: ink, lineSpacing: 1.2);

pw.Widget _caps(pw.Font bold, PdfColor ink, String title) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(),
            style: pw.TextStyle(font: bold, fontSize: 11, letterSpacing: 0.6, color: ink)),
        _rule(PdfColors.grey400),
      ],
    );

pw.Widget _bullets(pw.Font font, List<String> lines, PdfColor ink) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines
          .where((s) => s.trim().isNotEmpty)
          .map(
            (s) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('- ', style: _body(font, 10, ink)),
                  pw.Expanded(child: pw.Text(s.trim(), style: _body(font, 10, ink))),
                ],
              ),
            ),
          )
          .toList(),
    );

pw.Widget _expMinimalRow(pw.Font font, pw.Font bold, ExperienceItem e, PdfColor ink, PdfColor muted) {
  final company = e.companyName.trim();
  final dates = e.dateRange.trim();
  final bullets = e.bullets.where((b) => b.trim().isNotEmpty).toList();
  if (company.isEmpty && dates.isEmpty && bullets.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(company.isEmpty ? ' ' : company,
                  style: pw.TextStyle(font: bold, fontSize: 10.5, color: ink)),
            ),
            if (dates.isNotEmpty) pw.Text(dates, style: pw.TextStyle(font: bold, fontSize: 9.5, color: muted)),
          ],
        ),
        pw.SizedBox(height: 4),
        ...bullets.map(
          (b) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 4, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: _body(font, 10, ink)),
                pw.Expanded(child: pw.Text(b.trim(), style: _body(font, 10, ink))),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _exp(pw.Font font, pw.Font bold, ExperienceItem e, PdfColor ink, PdfColor accent) {
  final company = e.companyName.trim();
  final dates = e.dateRange.trim();
  final bullets = e.bullets.where((b) => b.trim().isNotEmpty).toList();
  if (company.isEmpty && dates.isEmpty && bullets.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (company.isNotEmpty) pw.Text(company, style: _boldAccent(bold, 11, accent)),
        if (dates.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, bottom: 4),
            child: pw.Text(dates, style: _boldAccent(bold, 10, accent)),
          ),
        _bullets(font, bullets, ink),
      ],
    ),
  );
}

bool _schoolingAnyData(ResumeModel model) {
  final s12 = model.education.schooling.class12;
  final s10 = model.education.schooling.class10;
  return [s12.boardName, s12.medium, s12.yearOfPassing, s12.score, s10.boardName, s10.medium, s10.yearOfPassing, s10.score]
      .any((s) => s.trim().isNotEmpty);
}

pw.Widget _eduTable(pw.Font font, pw.Font bold, ResumeModel r, PdfColor ink, PdfColor accent) {
  final g = r.education.graduation;
  final s12 = r.education.schooling.class12;
  final s10 = r.education.schooling.class10;

  pw.Widget rowLabel(String t) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(t, style: _body(font, 10, ink)),
      );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Graduation', style: _boldAccent(bold, 11.5, accent)),
      pw.SizedBox(height: 4),
      pw.Text('Course: ${g.course}', style: _body(font, 10, ink)),
      pw.Text('College: ${g.college}', style: _body(font, 10, ink)),
      pw.Text('Score: ${g.score}', style: _body(font, 10, ink)),
      pw.SizedBox(height: 8),
      pw.Text('Schooling', style: _boldAccent(bold, 11.5, accent)),
      pw.SizedBox(height: 4),
      pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(92),
          1: pw.FixedColumnWidth(120),
          2: pw.FixedColumnWidth(120),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox()),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Center(child: pw.Text('Class XII', style: _boldAccent(bold, 10, accent))),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Center(child: pw.Text('Class X', style: _boldAccent(bold, 10, accent))),
              ),
            ],
          ),
          pw.TableRow(children: [rowLabel('Board'), rowLabel(s12.boardName), rowLabel(s10.boardName)]),
          pw.TableRow(children: [rowLabel('Medium'), rowLabel(s12.medium), rowLabel(s10.medium)]),
          pw.TableRow(children: [rowLabel('Year'), rowLabel(s12.yearOfPassing), rowLabel(s10.yearOfPassing)]),
          pw.TableRow(children: [rowLabel('Score'), rowLabel(s12.score), rowLabel(s10.score)]),
        ],
      ),
    ],
  );
}

pw.ImageProvider? _avatar(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  try {
    return pw.MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}

/// ATS PDF widgets matching each Flutter template family.
List<pw.Widget> buildResumePdfForTemplate({
  required String builderKey,
  required ResumeModel model,
  required ResumeStudioAppearance appearance,
  required ResumeTemplate meta,
  Uint8List? profileBytes,
}) {
  final accent = _pc(appearance.resolvedAccent(Color(safeResumeTemplateAccentArgb(meta))));
  // ATS exports stay high-contrast black on white for parsers/scanners.
  final ink = PdfColors.black;
  final subtle = PdfColors.grey700;
  final font = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final v = model.sectionVisible;

  pw.Widget headerMinimal() {
    final img = _avatar(profileBytes);
    return pw.Column(
      children: [
        if (img != null)
          pw.Container(
            width: 72,
            height: 72,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, image: pw.DecorationImage(image: img, fit: pw.BoxFit.cover)),
          )
        else
          pw.Container(
            width: 72,
            height: 72,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.grey)),
          ),
        pw.SizedBox(height: 10),
        pw.Center(child: pw.Text(model.fullName.trim().isEmpty ? ' ' : model.fullName,
            style: pw.TextStyle(font: bold, fontSize: 22, color: ink))),
        if (model.professionalTitle.trim().isNotEmpty)
          pw.Center(child: pw.Text(model.professionalTitle, style: _boldAccent(bold, 11.5, accent))),
        pw.SizedBox(height: 10),
        if (v[ResumeSectionKeys.sidebar] ?? true)
          pw.Center(
            child: pw.Text(
              [model.contact.mobile, model.contact.email].where((s) => s.trim().isNotEmpty).join(' · '),
              style: _body(font, 10, subtle),
            ),
          ),
      ],
    );
  }

  List<pw.Widget> linearSections({bool compact = false}) {
    final fs = compact ? 9.5 : 10.5;
    final kids = <pw.Widget>[headerMinimal(), pw.SizedBox(height: 14)];
    void addSec(String title, List<pw.Widget> inner) {
      kids.add(_caps(bold, ink, title));
      kids.add(pw.SizedBox(height: 6));
      kids.addAll(inner);
      kids.add(pw.SizedBox(height: 12));
    }

    if (v[ResumeSectionKeys.summary] ?? true) {
      addSec('Summary', [pw.Text(model.summary, style: _body(font, fs, ink))]);
    }
    if ((v[ResumeSectionKeys.personal] ?? true) &&
        model.personalDetails.any((e) => e.label.trim().isNotEmpty || e.value.trim().isNotEmpty)) {
      final rows = model.personalDetails.where((e) => e.label.trim().isNotEmpty || e.value.trim().isNotEmpty).toList();
      addSec(
        'Personal details',
        rows
            .map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: _body(font, fs, ink),
                    children: [
                      pw.TextSpan(text: '${r.label}: ', style: _boldAccent(bold, fs, accent)),
                      pw.TextSpan(text: r.value),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }
    if (v[ResumeSectionKeys.skills] ?? true) {
      addSec('Skills', [_bullets(font, model.skills, ink)]);
    }
    if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) {
      addSec(
        'Languages & certifications',
        [
          if (model.languages.any((s) => s.trim().isNotEmpty))
            pw.Text(model.languages.where((s) => s.trim().isNotEmpty).join(', '), style: _body(font, fs, ink)),
          _bullets(font, model.certifications, ink),
        ],
      );
    }
    if (v[ResumeSectionKeys.education] ?? true) {
      addSec('Education', [_eduTable(font, bold, model, ink, accent)]);
    }
    if (v[ResumeSectionKeys.work] ?? true) {
      addSec('Experience', model.workExperience.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    if (v[ResumeSectionKeys.internships] ?? true) {
      addSec('Internships', model.internships.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    if (v[ResumeSectionKeys.projects] ?? true) {
      addSec('Projects', model.projects.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    return kids;
  }

  List<pw.Widget> fresherOrder({bool compact = false}) {
    final fs = compact ? 9.5 : 10.5;
    final kids = <pw.Widget>[headerMinimal(), pw.SizedBox(height: 14)];
    void addSec(String title, List<pw.Widget> inner) {
      kids.add(_caps(bold, ink, title));
      kids.add(pw.SizedBox(height: 6));
      kids.addAll(inner);
      kids.add(pw.SizedBox(height: 12));
    }
    if (v[ResumeSectionKeys.summary] ?? true) {
      addSec('Objective', [pw.Text(model.summary, style: _body(font, fs, ink))]);
    }
    if (v[ResumeSectionKeys.education] ?? true) {
      addSec('Education', [_eduTable(font, bold, model, ink, accent)]);
    }
    if (v[ResumeSectionKeys.projects] ?? true) {
      addSec('Projects', model.projects.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    if (v[ResumeSectionKeys.internships] ?? true) {
      addSec('Internships', model.internships.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    if (v[ResumeSectionKeys.skills] ?? true) {
      addSec('Skills', [_bullets(font, model.skills, ink)]);
    }
    if (v[ResumeSectionKeys.work] ?? true) {
      addSec('Experience', model.workExperience.map((e) => _exp(font, bold, e, ink, accent)).toList());
    }
    if ((v[ResumeSectionKeys.personal] ?? true) && model.personalDetails.isNotEmpty) {
      addSec(
        'Personal details',
        model.personalDetails
            .where((e) => e.label.trim().isNotEmpty || e.value.trim().isNotEmpty)
            .map(
              (r) => pw.Text('${r.label}: ${r.value}', style: _body(font, fs, ink)),
            )
            .toList(),
      );
    }
    if ((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) {
      addSec(
        'Languages & certifications',
        [
          pw.Text(model.languages.where((s) => s.trim().isNotEmpty).join(', '), style: _body(font, fs, ink)),
          _bullets(font, model.certifications, ink),
        ],
      );
    }
    return kids;
  }

  pw.Widget twoColumn() {
    final img = _avatar(profileBytes);
    final avatar = img != null
        ? pw.Container(
            width: 68,
            height: 68,
            decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, image: pw.DecorationImage(image: img, fit: pw.BoxFit.cover)),
          )
        : pw.Container(
            width: 68,
            height: 68,
            decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.grey300),
          );

    final sidebar = pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          avatar,
          pw.SizedBox(height: 10),
          if (v[ResumeSectionKeys.sidebar] ?? true) ...[
            _caps(bold, ink, 'Contact'),
            pw.Text(model.contact.mobile, style: _body(font, 10, ink)),
            pw.Text(model.contact.email, style: _body(font, 10, ink)),
            pw.SizedBox(height: 10),
          ],
          if (v[ResumeSectionKeys.skills] ?? true) ...[
            _caps(bold, ink, 'Skills'),
            _bullets(font, model.skills, ink),
            pw.SizedBox(height: 10),
          ],
          if (v[ResumeSectionKeys.languages] ?? true) ...[
            _caps(bold, ink, 'Languages'),
            pw.Text(model.languages.where((s) => s.trim().isNotEmpty).join(', '), style: _body(font, 9.5, ink)),
            pw.SizedBox(height: 10),
          ],
          if (v[ResumeSectionKeys.certifications] ?? true) ...[
            _caps(bold, ink, 'Certs'),
            _bullets(font, model.certifications, ink),
          ],
        ],
      ),
    );

    final main = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(model.fullName.trim().isEmpty ? ' ' : model.fullName, style: pw.TextStyle(font: bold, fontSize: 20, color: ink)),
        if (model.professionalTitle.trim().isNotEmpty)
          pw.Text(model.professionalTitle, style: _boldAccent(bold, 11.5, accent)),
        pw.SizedBox(height: 10),
        if (v[ResumeSectionKeys.summary] ?? true) ...[
          _caps(bold, ink, 'Summary'),
          pw.Text(model.summary, style: _body(font, 10.5, ink)),
          pw.SizedBox(height: 10),
        ],
        if (v[ResumeSectionKeys.personal] ?? true) ...[
          _caps(bold, ink, 'Personal'),
          ...model.personalDetails
              .where((e) => e.label.trim().isNotEmpty || e.value.trim().isNotEmpty)
              .map((r) => pw.Text('${r.label}: ${r.value}', style: _body(font, 10, ink))),
          pw.SizedBox(height: 10),
        ],
        if (v[ResumeSectionKeys.education] ?? true) ...[
          _caps(bold, ink, 'Education'),
          _eduTable(font, bold, model, ink, accent),
          pw.SizedBox(height: 10),
        ],
        if (v[ResumeSectionKeys.work] ?? true) ...[
          _caps(bold, ink, 'Experience'),
          ...model.workExperience.map((e) => _exp(font, bold, e, ink, accent)),
        ],
        if (v[ResumeSectionKeys.internships] ?? true) ...[
          _caps(bold, ink, 'Internships'),
          ...model.internships.map((e) => _exp(font, bold, e, ink, accent)),
        ],
        if (v[ResumeSectionKeys.projects] ?? true) ...[
          _caps(bold, ink, 'Projects'),
          ...model.projects.map((e) => _exp(font, bold, e, ink, accent)),
        ],
      ],
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 150, child: sidebar),
        pw.SizedBox(width: 12),
        pw.Expanded(child: main),
      ],
    );
  }

  pw.Widget executive() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(model.fullName.trim().isEmpty ? ' ' : model.fullName,
                      style: pw.TextStyle(font: bold, fontSize: 26, color: ink)),
                  if (model.professionalTitle.trim().isNotEmpty)
                    pw.Text(model.professionalTitle, style: _boldAccent(bold, 12, accent)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (model.contact.mobile.trim().isNotEmpty)
                  pw.Text(model.contact.mobile, style: _body(font, 10, subtle)),
                if (model.contact.email.trim().isNotEmpty)
                  pw.Text(model.contact.email, style: _body(font, 10, subtle)),
              ],
            ),
          ],
        ),
        pw.Container(height: 1, color: accent),
        pw.SizedBox(height: 10),
        ...linearSections(compact: false).skip(2),
      ],
    );
  }

  List<pw.Widget> minimalAtsPdf({bool compact = false}) {
    final fs = compact ? 9.8 : 10.5;
    final muted = subtle;

    String pdfDetail(String label) {
      final want = label.trim().toLowerCase();
      for (final r in model.personalDetails) {
        if (r.label.trim().toLowerCase() == want) return r.value.trim();
      }
      return '';
    }

    pw.Widget pdfMinimalSection(String title) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title.toUpperCase(),
                style: pw.TextStyle(font: bold, fontSize: 11, letterSpacing: 0.85, color: ink)),
            pw.Container(height: 1, color: ink),
            pw.SizedBox(height: 8),
          ],
        );

    pw.Widget pdfMinimalHeader() {
      final li = pdfDetail('LinkedIn');
      final loc = pdfDetail('Current Location');
      final segs = <String>[];
      if (model.contact.mobile.trim().isNotEmpty) segs.add(model.contact.mobile.trim());
      if (model.contact.email.trim().isNotEmpty) segs.add(model.contact.email.trim());
      if (li.isNotEmpty) segs.add(li);
      if (loc.isNotEmpty) segs.add(loc);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              model.fullName.trim().isEmpty ? ' ' : model.fullName.trim().toUpperCase(),
              style: pw.TextStyle(font: bold, fontSize: 20, color: ink),
            ),
          ),
          if (model.professionalTitle.trim().isNotEmpty)
            pw.Center(
              child: pw.Text(
                model.professionalTitle.trim().toUpperCase(),
                style: pw.TextStyle(font: bold, fontSize: 10, color: muted, letterSpacing: 0.2),
              ),
            ),
          if ((v[ResumeSectionKeys.sidebar] ?? true) && segs.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text(segs.join('  |  '), style: _body(font, 9.5, ink))),
          ],
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
            child: pw.Container(height: 1, color: ink),
          ),
        ],
      );
    }

    pw.Widget pdfGradRow() {
      final g = model.education.graduation;
      final left =
          '${g.course.trim()}${g.course.trim().isNotEmpty && g.college.trim().isNotEmpty ? ' | ' : ''}${g.college.trim()}';
      final date = g.score.trim();
      if (left.isEmpty && date.isEmpty) return pw.SizedBox();
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(left.isEmpty ? ' ' : left, style: pw.TextStyle(font: bold, fontSize: 10.5, color: ink)),
          ),
          if (date.isNotEmpty) pw.Text(date, style: pw.TextStyle(font: bold, fontSize: 9.5, color: muted)),
        ],
      );
    }

    final kids = <pw.Widget>[pdfMinimalHeader(), pw.SizedBox(height: 8)];
    void addSec(String title, List<pw.Widget> inner) {
      kids.add(pdfMinimalSection(title));
      kids.addAll(inner);
      kids.add(pw.SizedBox(height: 12));
    }

    if (v[ResumeSectionKeys.summary] ?? true) {
      addSec('Summary', [pw.Text(model.summary, style: _body(font, fs, ink))]);
    }
    if (v[ResumeSectionKeys.work] ?? true) {
      final rows = model.workExperience.map((e) => _expMinimalRow(font, bold, e, ink, muted)).toList();
      addSec('Experience', rows);
    }
    if ((v[ResumeSectionKeys.internships] ?? true) && model.internships.isNotEmpty) {
      addSec('Internships', model.internships.map((e) => _expMinimalRow(font, bold, e, ink, muted)).toList());
    }
    if (v[ResumeSectionKeys.education] ?? true) {
      final eduKids = <pw.Widget>[pdfGradRow()];
      if (_schoolingAnyData(model)) {
        eduKids.add(pw.SizedBox(height: 10));
        eduKids.add(_eduTable(font, bold, model, ink, accent));
      }
      addSec('Education', eduKids);
    }
    if (v[ResumeSectionKeys.skills] ?? true) {
      final skills = model.skills.where((s) => s.trim().isNotEmpty).toList();
      if (skills.isEmpty) {
        addSec('Skills', [pw.SizedBox(height: 2)]);
      } else {
        addSec(
          'Skills',
          [
            pw.Wrap(
              spacing: 10,
              runSpacing: 6,
              children: skills
                  .map(
                    (s) => pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('• ', style: _body(font, 9.8, ink)),
                        pw.Text(s.trim(), style: _body(font, 9.8, ink)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      }
    }
    if (((v[ResumeSectionKeys.languages] ?? true) || (v[ResumeSectionKeys.certifications] ?? true)) &&
        (model.languages.any((s) => s.trim().isNotEmpty) || model.certifications.any((s) => s.trim().isNotEmpty))) {
      addSec(
        'Languages & certifications',
        [
          if (model.languages.any((s) => s.trim().isNotEmpty))
            pw.Text(model.languages.where((s) => s.trim().isNotEmpty).join(', '), style: _body(font, fs, ink)),
          _bullets(font, model.certifications, ink),
        ],
      );
    }
    final extraPersonal = model.personalDetails.where((r) {
      final k = r.label.trim().toLowerCase();
      const skip = {'linkedin', 'current location'};
      return !skip.contains(k) && (r.label.trim().isNotEmpty || r.value.trim().isNotEmpty);
    }).toList();
    if ((v[ResumeSectionKeys.personal] ?? true) && extraPersonal.isNotEmpty) {
      addSec(
        'Personal details',
        extraPersonal
            .map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: _body(font, fs, ink),
                    children: [
                      pw.TextSpan(text: '${r.label}: ', style: _boldAccent(bold, fs, accent)),
                      pw.TextSpan(text: r.value),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    }
    if ((v[ResumeSectionKeys.projects] ?? true) && model.projects.isNotEmpty) {
      addSec('Projects', model.projects.map((e) => _expMinimalRow(font, bold, e, ink, muted)).toList());
    }
    return kids;
  }

  switch (builderKey) {
    case ResumeBuilderIds.modernProfessional:
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            border: pw.Border(left: pw.BorderSide(color: accent, width: 4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(model.fullName.trim().isEmpty ? ' ' : model.fullName,
                  style: pw.TextStyle(font: bold, fontSize: 22, color: ink)),
              if (model.professionalTitle.trim().isNotEmpty)
                pw.Text(model.professionalTitle, style: _boldAccent(bold, 11.5, accent)),
              pw.SizedBox(height: 8),
              if (v[ResumeSectionKeys.sidebar] ?? true)
                pw.Text(
                  [model.contact.mobile, model.contact.email].where((s) => s.trim().isNotEmpty).join(' · '),
                  style: _body(font, 10, subtle),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        ...linearSections().skip(2),
      ];
    case ResumeBuilderIds.corporateBlue:
      return linearSections();
    case ResumeBuilderIds.creativeClean:
      return [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: accent, width: 6))),
          padding: const pw.EdgeInsets.only(left: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: linearSections(),
          ),
        ),
      ];
    case ResumeBuilderIds.executiveResume:
      return [executive()];
    case ResumeBuilderIds.fresherResume:
      return fresherOrder();
    case ResumeBuilderIds.darkProfessional:
      return linearSections();
    case ResumeBuilderIds.twoColumnResume:
      return [twoColumn()];
    case ResumeBuilderIds.compactAts:
      return minimalAtsPdf(compact: true);
    case ResumeBuilderIds.elegantModern:
      return linearSections();
    case ResumeBuilderIds.minimalAts:
      return minimalAtsPdf(compact: false);
    default:
      return linearSections();
  }
}
