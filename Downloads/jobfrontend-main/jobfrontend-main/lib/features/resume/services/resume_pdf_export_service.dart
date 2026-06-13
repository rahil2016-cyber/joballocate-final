import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:joballocate/models/resume_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../resume/models/resume_studio_appearance.dart';
import '../../../resume/templates/resume_template_registry.dart';
import '../models/resume_model.dart';
import '../../../utils/media_url.dart';

Future<Uint8List?> _loadProfileBytes(ResumeModel model) async {
  if (model.profileImageBase64 != null && model.profileImageBase64!.isNotEmpty) {
    try {
      return base64Decode(model.profileImageBase64!);
    } catch (_) {}
  }
  final url = model.profileImageUrl?.trim() ?? '';
  if (url.isEmpty) return null;
  if (url.startsWith('data:image')) {
    final i = url.indexOf(',');
    if (i < 0 || i >= url.length - 1) return null;
    try {
      return base64Decode(url.substring(i + 1));
    } catch (_) {}
  }
  final resolved = MediaUrl.resolve(url);
  if (resolved == null) return null;
  try {
    final res = await http.get(Uri.parse(resolved));
    if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return res.bodyBytes;
  } catch (_) {}
  return null;
}

/// ATS-oriented PDF: vector widgets, linear reading order, selectable text.
Future<Uint8List> exportResumePdf({
  required ResumeModel model,
  required ResumeTemplate templateMeta,
  ResumeStudioAppearance? studioAppearance,
}) async {
  final photo = await _loadProfileBytes(model);
  final appearance = studioAppearance ?? const ResumeStudioAppearance();
  final builder = ResumeTemplateRegistry.instance.resolve(templateMeta.builderKey);

  final pdf = pw.Document(
    author: model.fullName.trim().isNotEmpty ? model.fullName : 'Resume',
    title: model.draftTitle.trim().isNotEmpty ? model.draftTitle : 'Resume',
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => builder.buildPdfWidgets(
        model: model,
        appearance: appearance,
        meta: templateMeta,
        profileBytes: photo,
      ),
    ),
  );

  return Uint8List.fromList(await pdf.save());
}
