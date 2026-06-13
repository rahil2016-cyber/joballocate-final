import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/seeker_html_template_swatch.dart';

/// Keys must match Laravel `ResumeHtmlPreviewController::TEMPLATE_KEYS`.
const List<Map<String, String>> kSeekerResumeHtmlTemplates = [
  {'key': 't1_teal_sidebar', 'label': 'Teal · two column'},
  {'key': 't2_minimal', 'label': 'Slate executive'},
  {'key': 't3_bold_navy', 'label': 'Bold navy'},
  {'key': 't4_classic_serif', 'label': 'Meridian editorial'},
  {'key': 't5_modern_split', 'label': 'Modern split'},
  {'key': 't6_navy_two_column', 'label': 'Navy · corporate'},
  {'key': 't7_geometric_modern', 'label': 'Geometric · modern'},
  {'key': 't8_typewriter_retro', 'label': 'Typewriter · retro'},
  {'key': 't9_vintage_folio', 'label': 'Vintage · folio'},
  {'key': 't10_creative_sunset', 'label': 'Sunset · creative'},
  {'key': 't11_mono_swiss', 'label': 'Swiss · mono'},
  {'key': 't12_royal_gold', 'label': 'Royal · gold'},
];

/// ~A4 width at 96dpi (210mm). Web templates use `width: 210mm` in CSS.
const double kResumeHtmlA4WidthPx = 794;

/// One A4 page height at same scale (297mm).
const double kResumeHtmlA4PageHeightPx = 1123;

/// Tall canvas so multi-page HTML can scroll inside the WebView.
const double kResumeHtmlCanvasHeightPx = 2800;

/// Space reserved under the preview for actions (Purchase, etc.).
const double _kPreviewActionsBarHeight = 56;

/// Matches Laravel `ResumePdfPurchaseController::PRICE_INR` (admin revenue reports).
const int kResumeHtmlPdfPriceInr = 20;

String seekerHtmlTemplateLabel(String key) {
  for (final e in kSeekerResumeHtmlTemplates) {
    if (e['key'] == key) return e['label'] ?? key;
  }
  return key;
}

/// Loads server-rendered HTML via `POST /job-seeker/resume/preview-html`.
class ResumeHtmlPreviewScreen extends StatefulWidget {
  const ResumeHtmlPreviewScreen({
    super.key,
    required this.templateKey,
    this.contentEnvelope,
    this.resumeDraftId,
    this.demoVariant,
  });

  final String templateKey;
  final Map<String, dynamic>? contentEnvelope;
  final int? resumeDraftId;
  /// When set and no saved content, loads demo HTML (avoids empty preview).
  final int? demoVariant;

  @override
  State<ResumeHtmlPreviewScreen> createState() => _ResumeHtmlPreviewScreenState();
}

class _ResumeHtmlPreviewScreenState extends State<ResumeHtmlPreviewScreen> {
  static final Map<String, String> _htmlCache = {};

  late final WebViewController _web;
  late String _templateKey;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  String? _htmlContent;

  String get _cacheKey =>
      '$_templateKey|${widget.resumeDraftId}|${widget.demoVariant}|${widget.contentEnvelope?.hashCode ?? 0}';

  @override
  void initState() {
    super.initState();
    _templateKey = widget.templateKey;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _scheduleInjectFitZoom(),
        ),
      );
    _load();
  }

  void _scheduleInjectFitZoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _injectFitZoom());
  }

  /// Scale the server HTML so one full A4 page fits inside the preview pane (centered).
  Future<void> _injectFitZoom() async {
    if (!mounted || _error != null) return;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final topChrome = mq.padding.top + kToolbarHeight;
    final bottomChrome = mq.padding.bottom + _kPreviewActionsBarHeight;
    const horizontalMargin = 32.0;
    const verticalMargin = 24.0;
    final availW = (size.width - horizontalMargin).clamp(120.0, size.width);
    final availH = (size.height - topChrome - bottomChrome - verticalMargin).clamp(120.0, size.height);
    final zw = availW / kResumeHtmlA4WidthPx;
    final zh = availH / kResumeHtmlA4PageHeightPx;
    final z = (zw < zh ? zw : zh).clamp(0.22, 1.0);
    final zs = z.toStringAsFixed(4);
    try {
      await _web.runJavaScript(
        'try{document.documentElement.style.setProperty("-webkit-text-size-adjust","100%");'
        "document.body.style.zoom='$zs';"
        "document.querySelectorAll('img').forEach(function(img){"
        "img.style.maxWidth='110px';img.style.maxHeight='110px';img.style.objectFit='cover';});"
        '}catch(e){}',
      );
    } catch (_) {}
  }

  bool get _useDemo =>
      widget.contentEnvelope == null &&
      widget.resumeDraftId == null &&
      widget.demoVariant != null;

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Too Many Attempts') || s.contains('429')) {
      return 'Server is busy. Wait a moment and tap Retry.';
    }
    return s.replaceFirst('Exception: ', '');
  }

  Future<void> _load({int attempt = 0}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cached = _htmlCache[_cacheKey];
      final html = cached ??
          (await JobSeekerApiService.instance.resumePreviewHtml(
            templateKey: _templateKey,
            contentEnvelope: widget.contentEnvelope,
            resumeDraftId: widget.resumeDraftId,
            demoVariant: _useDemo ? widget.demoVariant : null,
          ))['html']
              ?.toString() ??
          '';
      if (html.isEmpty) throw Exception('Empty HTML from server');
      _htmlCache[_cacheKey] = html;
      _htmlContent = html;
      await _web.loadHtmlString(html, baseUrl: 'https://joballocate.tech/');
      if (mounted) {
        setState(() => _loading = false);
        _scheduleInjectFitZoom();
      }
    } catch (e) {
      final msg = e.toString();
      if (attempt < 2 &&
          (msg.contains('Too Many Attempts') || msg.contains('429'))) {
        await Future<void>.delayed(Duration(seconds: 2 + attempt));
        if (mounted) return _load(attempt: attempt + 1);
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _friendlyError(e);
        });
      }
    }
  }

  Future<void> _pickTemplate(String? key) async {
    if (key == null || key == _templateKey) return;
    setState(() => _templateKey = key);
    await _load();
  }

  Future<void> _exportPdf() async {
    final html = _htmlContent;
    if (html == null || html.isEmpty) {
      throw Exception('Resume HTML not loaded yet');
    }
    await Printing.layoutPdf(
      onLayout: (format) => Printing.convertHtml(
        format: format,
        html: html,
        baseUrl: 'https://joballocate.tech/',
      ),
    );
  }

  Future<void> _onPurchaseAndDownload() async {
    if (!AppSession.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to purchase and download your resume PDF.')),
      );
      return;
    }
    if (_loading || _purchasing) return;

    final label = seekerHtmlTemplateLabel(_templateKey);
    final templateId = int.tryParse(seekerStudioTemplateIdForHtmlKey(_templateKey)) ?? 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download resume PDF'),
        content: Text(
          'Pay ₹$kResumeHtmlPdfPriceInr (demo) to download “$label” as PDF.\n\n'
          'This purchase is logged in the admin panel under resume PDF exports.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay & download')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _purchasing = true);
    try {
      await JobSeekerApiService.instance.purchaseResumePdfExport(
        resumeTemplateId: templateId,
        resumeTemplateTitle: label,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase recorded. Opening PDF…'),
          backgroundColor: AppColors.success,
        ),
      );
      await _exportPdf();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF1f1f1f),
      appBar: AppBar(
        title: const Text('Resume preview'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _templateKey,
                dropdownColor: AppColors.primary,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                items: kSeekerResumeHtmlTemplates
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['key'],
                        child: Text(e['label'] ?? '', style: const TextStyle(color: Colors.black87)),
                      ),
                    )
                    .toList(),
                onChanged: _loading ? null : _pickTemplate,
              ),
            ),
          ),
        ],
      ),
      body: _error != null
          ? ColoredBox(
              color: const Color(0xFF2a2a2a),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : () => _load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF3a3a3a),
                          Color(0xFF262626),
                          Color(0xFF1a1a1a),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    width: kResumeHtmlA4WidthPx,
                                    height: kResumeHtmlCanvasHeightPx,
                                    child: WebViewWidget(controller: _web),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_loading)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                ),
                Material(
                  elevation: 12,
                  color: const Color(0xFF141414),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomSafe),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: (_loading || _purchasing) ? null : _onPurchaseAndDownload,
                              icon: _purchasing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.shopping_bag_outlined, size: 20),
                              label: Text(
                                _purchasing ? 'Processing…' : 'Purchase · ₹$kResumeHtmlPdfPriceInr',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
