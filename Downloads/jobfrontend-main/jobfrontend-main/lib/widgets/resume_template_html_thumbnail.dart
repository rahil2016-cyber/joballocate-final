import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/resume_html_thumbnail_cache.dart';
import '../utils/resume_thumbnail_html.dart';
import 'seeker_html_template_filled_preview.dart';

/// Gallery thumbnail: full Laravel HTML layout scaled down via [FittedBox] (not viewport zoom).
class ResumeTemplateHtmlThumbnail extends StatefulWidget {
  const ResumeTemplateHtmlThumbnail({
    super.key,
    required this.templateKey,
    required this.demoVariant,
  });

  final String templateKey;
  final int demoVariant;

  @override
  State<ResumeTemplateHtmlThumbnail> createState() => _ResumeTemplateHtmlThumbnailState();
}

class _ResumeTemplateHtmlThumbnailState extends State<ResumeTemplateHtmlThumbnail> {
  WebViewController? _web;
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ResumeTemplateHtmlThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templateKey != widget.templateKey ||
        oldWidget.demoVariant != widget.demoVariant) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _web = null;
    });
    try {
      final html = await ResumeHtmlThumbnailCache.instance.ensureHtml(
        templateKey: widget.templateKey,
        demoVariant: widget.demoVariant,
      );
      if (!mounted) return;
      if (html == null || html.isEmpty) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      await _mountWebView(html);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _mountWebView(String html) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _onPageFinished(),
        ),
      );
    await controller.loadHtmlString(
      wrapResumeHtmlForThumbnail(html),
      baseUrl: 'https://joballocate.tech/',
    );
    if (!mounted) return;
    setState(() {
      _web = controller;
    });
  }

  Future<void> _onPageFinished() async {
    final c = _web;
    if (c == null) return;
    try {
      await c.runJavaScript(
        "try{document.documentElement.classList.add('resume-thumb');"
        "document.body.style.overflow='hidden';"
        "document.querySelectorAll('img').forEach(function(el){"
        "el.style.maxWidth='52px';el.style.maxHeight='52px';"
        "el.style.objectFit='cover';});}catch(e){}",
      );
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return SeekerHtmlTemplateFilledPreview(
        templateKey: widget.templateKey,
        demoVariant: widget.demoVariant,
      );
    }

    final web = _web;
    if (web == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: kResumeThumbDesignWidthPx,
                height: kResumeThumbDesignHeightPx,
                child: WebViewWidget(controller: web),
              ),
            ),
          ),
          if (_loading)
            const ColoredBox(
              color: Color(0xE6FFFFFF),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
