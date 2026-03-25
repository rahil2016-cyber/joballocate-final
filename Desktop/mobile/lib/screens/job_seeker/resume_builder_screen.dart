import 'package:flutter/material.dart';
import 'package:joballocate/models/resume_template.dart';
import 'package:joballocate/services/app_session.dart';
import 'package:joballocate/services/job_seeker_api_service.dart';
import 'package:joballocate/services/resume_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:joballocate/models/seeker_profile.dart';
import 'packages_screen.dart';

String _humanizeSectionKey(String key) {
  if (key.isEmpty) return 'Section';
  return key
      .split('_')
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1) : ''}')
      .join(' ');
}

/// One resume block: editable heading + body (not limited to fixed labels).
class _ResumeSection {
  _ResumeSection({
    required this.id,
    required this.titleCtrl,
    required this.bodyCtrl,
  });

  final String id;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
}

class ResumeBuilderScreen extends StatefulWidget {
  final ResumeTemplate template;
  final String userId;
  final String token;

  const ResumeBuilderScreen({
    Key? key,
    required this.template,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  late final ResumeService _resumeService;
  late TextEditingController _titleController;
  final List<_ResumeSection> _sections = [];
  bool _isLoading = false;
  /// Section [id] while OpenRouter request is in flight.
  String? _aiLoadingSectionId;

  String _headerName = '—';
  String _headerPhone = '—';
  String _headerDob = '—';

  @override
  void initState() {
    super.initState();
    _resumeService = ResumeService();
    _titleController = TextEditingController();

    final u = AppSession.user;
    final n = u?['name']?.toString().trim();
    final p = u?['phone']?.toString().trim();
    if (n != null && n.isNotEmpty) _headerName = n;
    if (p != null && p.isNotEmpty) _headerPhone = p;
    _loadProfileHeader();

    for (final sectionKey in widget.template.sections) {
      _sections.add(
        _ResumeSection(
          id: sectionKey,
          titleCtrl:
              TextEditingController(text: _humanizeSectionKey(sectionKey)),
          bodyCtrl: TextEditingController(),
        ),
      );
    }
    if (_sections.isEmpty) {
      _sections.add(
        _ResumeSection(
          id: 'section_0',
          titleCtrl: TextEditingController(text: 'Summary'),
          bodyCtrl: TextEditingController(),
        ),
      );
    }
  }

  Future<void> _loadProfileHeader() async {
    try {
      final prof = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      final u = AppSession.user;
      final n = u?['name']?.toString().trim();
      final ph = u?['phone']?.toString().trim();
      setState(() {
        if (n != null && n.isNotEmpty) _headerName = n;
        if (ph != null && ph.isNotEmpty) _headerPhone = ph;
        _headerDob = _formatDobForPdf(prof['date_of_birth']);
      });
    } catch (_) {}
  }

  String _formatDobForPdf(dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s.isEmpty ? '—' : s;
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final s in _sections) {
      s.titleCtrl.dispose();
      s.bodyCtrl.dispose();
    }
    super.dispose();
  }

  void _addCustomSection() {
    setState(() {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _sections.add(
        _ResumeSection(
          id: id,
          titleCtrl: TextEditingController(text: 'New section'),
          bodyCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one section')),
      );
      return;
    }
    setState(() {
      final s = _sections.removeAt(index);
      s.titleCtrl.dispose();
      s.bodyCtrl.dispose();
    });
  }

  String _displayTitle(_ResumeSection s) {
    final t = s.titleCtrl.text.trim();
    if (t.isNotEmpty) return t;
    return _humanizeSectionKey(s.id);
  }

  List<pw.Widget> _pdfHeaderBand() {
    final v = widget.template.designVariant % 4;
    const small = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final name = _headerName;
    final phone = _headerPhone;
    final dob = _headerDob;

    switch (v) {
      case 0:
        return [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              border: pw.Border.all(color: PdfColors.blue800, width: 0.8),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('Phone: $phone', style: small),
                    ),
                    pw.Text('DOB: $dob', style: small),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ];
      case 1:
        return [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 5,
                height: 52,
                color: PdfColors.teal700,
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      name,
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('$phone  ·  $dob', style: small),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
        ];
      case 2:
        return [
          pw.Column(
            children: [
              pw.Text(
                name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey500, thickness: 0.6),
              pw.SizedBox(height: 4),
              pw.Text(
                'Phone: $phone',
                textAlign: pw.TextAlign.center,
                style: small,
              ),
              pw.Text(
                'Date of birth: $dob',
                textAlign: pw.TextAlign.center,
                style: small,
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.grey500, thickness: 0.6),
            ],
          ),
          pw.SizedBox(height: 16),
        ];
      default:
        return [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CONTACT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Container(width: 1, height: 48, color: PdfColors.grey400),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROFILE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(name, style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('DOB: $dob', style: small),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ];
    }
  }

  Future<bool> _handlePaymentCheck() async {
    try {
      final raw = await JobSeekerApiService.instance.getSeekerProfile();
      final summary = SeekerProfileSummary.fromJson(raw);
      if (summary.canBuildResume) return true;

      final pay = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pay to Download'),
          content: const Text(
            'Downloading your resume costs ₹20. Pay to download your built resume.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pay ₹20'),
            ),
          ],
        ),
      );
      if (pay != true || !mounted) return false;

      // Ensure mock API actually lets them pay
      await JobSeekerApiService.instance.purchaseOneOffResume();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return false;
    }
  }

  Future<void> _exportPdf() async {
    final canDownload = await _handlePaymentCheck();
    if (!canDownload) return;

    final title = _titleController.text.trim().isEmpty
        ? widget.template.name
        : _titleController.text.trim();

    final v = widget.template.designVariant;
    final pdf = pw.Document();

    final name = _headerName;
    final phone = _headerPhone;
    final dob = _headerDob;

    // Filters sections that actually have content
    final validSections = _sections.where((s) {
      final heading = _displayTitle(s).trim();
      final body = s.bodyCtrl.text.trim();
      return heading.isNotEmpty && body.isNotEmpty;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: v == 1
            ? const pw.EdgeInsets.all(0) // No margin for full banner in variant 1
            : const pw.EdgeInsets.all(32),
        build: (ctx) {
          if (v == 0) {
            // Variant 0: Classic Centered
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                   pw.Text(
                    name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('PHONE: $phone', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(width: 16),
                      pw.Text('DOB: $dob', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 1.5, color: PdfColors.black),
                  pw.SizedBox(height: 16),
                  ...validSections.map((s) {
                    final isBulletList = s.id.toLowerCase().contains('skill');
                    final lines = s.bodyCtrl.text.split('\n');
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 16),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _displayTitle(s).toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                          pw.SizedBox(height: 6),
                          if (isBulletList)
                            pw.Wrap(
                              spacing: 20,
                              runSpacing: 4,
                              children: lines.map((l) => pw.Text('• ${l.trim()}', style: const pw.TextStyle(fontSize: 10))).toList(),
                            )
                          else
                            pw.Text(s.bodyCtrl.text.trim(), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ];
          } else if (v == 1) {
            // Variant 1: Modern Sidebar (Green Banner)
            // Left column has Contact, Education, Skills
            final leftSections = validSections.where((s) => ['contact', 'education', 'skills'].any((k) => s.id.toLowerCase().contains(k))).toList();
            final rightSections = validSections.where((s) => !leftSections.contains(s)).toList();

            return [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(32),
                color: PdfColor.fromHex('#41786f'), // Teal/Green color
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      name.toUpperCase(),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 26, fontWeight: pw.FontWeight.bold, letterSpacing: 2),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                ),
              ),
              // Main content grid
              pw.Padding(
                padding: const pw.EdgeInsets.all(32),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Add Contact info explicitly if wanted, or let sections handle it
                          pw.Text('CONTACT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('DOB: $dob', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 16),
                          ...leftSections.map((s) => _buildVariant1Section(s)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 32),
                    // Right Column
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: rightSections.map((s) => _buildVariant1Section(s)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          } else {
            // Variant 2: Professional Blue
            final bottomSections = validSections.where((s) => ['skills', 'interests'].any((k) => s.id.toLowerCase().contains(k))).toList();
            final topSections = validSections.where((s) => !bottomSections.contains(s)).toList();

            return [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(color: PdfColors.blueAccent, fontSize: 26, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        title.toUpperCase(),
                        style: const pw.TextStyle(fontSize: 12, letterSpacing: 1.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('DOB: $dob', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              ...topSections.map((s) => _buildVariant2Section(s)),
              if (bottomSections.isNotEmpty)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: bottomSections.map((s) => pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 16),
                      child: _buildVariant2Section(s, disableDivider: true),
                    ),
                  )).toList(),
                )
            ];
          }
        },
      ),
    );

    await Printing.layoutPdf(
      name: '${title.replaceAll(' ', '_')}.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildVariant1Section(_ResumeSection s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _displayTitle(s).toUpperCase(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(s.bodyCtrl.text.trim(), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildVariant2Section(_ResumeSection s, {bool disableDivider = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _displayTitle(s),
            style: pw.TextStyle(color: PdfColors.blueAccent, fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          if (!disableDivider) pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 6),
          pw.Text(s.bodyCtrl.text.trim(), style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _openPlans() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const JobSeekerPackagesScreen(),
      ),
    );
  }

  Future<void> _aiImprove(_ResumeSection section) async {
    final result = await showDialog<_AiAssistResult?>(
      context: context,
      builder: (ctx) => _ResumeAiAssistDialog(
        sectionLabel: _displayTitle(section),
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _aiLoadingSectionId = section.id);
    try {
      final improved = await JobSeekerApiService.instance.resumeAiAssist(
        sectionName: _displayTitle(section),
        currentText: section.bodyCtrl.text,
        instruction: result.instruction,
        jobContext: result.jobContext,
      );
      if (!mounted) return;
      section.bodyCtrl.text = improved;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Section updated. One resume credit was used.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final needsPlan = msg.contains('credits') ||
          msg.contains('402') ||
          msg.contains('MODEL_KEY') ||
          msg.contains('configured');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.replaceFirst('Exception: ', '')),
          action: needsPlan
              ? SnackBarAction(
                  label: 'Plans',
                  onPressed: _openPlans,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _aiLoadingSectionId = null);
    }
  }

  Future<void> _buildAndSaveResume() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resume title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final content = <String, dynamic>{
        'format': 'sections_v2',
        'sections': _sections
            .map(
              (s) => {
                'id': s.id,
                'title': s.titleCtrl.text,
                'body': s.bodyCtrl.text,
              },
            )
            .toList(),
      };

      // Create resume
      await _resumeService.createResume(
        userId: widget.userId,
        token: widget.token,
        templateId: widget.template.id.toString(),
        title: _titleController.text,
        content: content,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.template.name} - Resume Builder'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card with template name
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.template.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.template.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Save may use server billing when connected. Use Export PDF anytime for a local copy.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 20),
          // Resume title input
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Resume Title',
              hintText: 'e.g., My Professional Resume',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.blue.shade800, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sections — edit titles freely or add your own',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_sections.length, (index) {
            final s = _sections[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: s.titleCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Section title',
                              hintText: 'e.g. Experience, Projects, Certifications',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_sections.length > 1)
                          IconButton(
                            tooltip: 'Remove section',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => _removeSection(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: s.bodyCtrl,
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _aiLoadingSectionId == s.id
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.auto_awesome),
                                tooltip: 'AI improve (1 resume credit)',
                                onPressed: () => _aiImprove(s),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: _addCustomSection,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add section'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          // Save button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _buildAndSaveResume,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save & sync resume'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green.shade600,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Values returned when the user confirms the AI assist dialog.
class _AiAssistResult {
  const _AiAssistResult({
    required this.instruction,
    required this.jobContext,
  });

  final String instruction;
  final String jobContext;
}

/// Owns [TextEditingController]s for the dialog so disposal happens after the
/// route is removed (avoids Flutter `_dependents.isEmpty` assertion).
class _ResumeAiAssistDialog extends StatefulWidget {
  const _ResumeAiAssistDialog({required this.sectionLabel});

  final String sectionLabel;

  @override
  State<_ResumeAiAssistDialog> createState() => _ResumeAiAssistDialogState();
}

class _ResumeAiAssistDialogState extends State<_ResumeAiAssistDialog> {
  late final TextEditingController _instruction;
  late final TextEditingController _jobContext;

  @override
  void initState() {
    super.initState();
    _instruction = TextEditingController();
    _jobContext = TextEditingController();
  }

  @override
  void dispose() {
    _instruction.dispose();
    _jobContext.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI resume assist'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section: ${widget.sectionLabel}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uses 1 resume build credit from your package (server). '
              'Powered by OpenRouter — arcee-ai/trinity-large-preview:free.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instruction,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instructions (optional)',
                hintText: 'e.g. Emphasize leadership and metrics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _jobContext,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Target role / job (optional)',
                hintText: 'e.g. Senior Flutter developer, Bangalore',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _AiAssistResult(
              instruction: _instruction.text,
              jobContext: _jobContext.text,
            ),
          ),
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
