/// Design canvas for one A4 page at 96dpi (matches Laravel `width: 210mm`).
const double kResumeThumbDesignWidthPx = 794;

/// Visible first-page height for gallery thumbnails (not full 297mm scroll).
const double kResumeThumbDesignHeightPx = 1050;

String _thumbOverrideStyles() => '''
<style id="resume-thumb-overrides">
html.resume-thumb, html.resume-thumb body {
  margin: 0 !important;
  padding: 0 !important;
  overflow: hidden !important;
  background: #ffffff !important;
  width: $kResumeThumbDesignWidthPx !important;
  -webkit-text-size-adjust: 100%;
}
html.resume-thumb body.a4-body--dark { background: #ffffff !important; }
html.resume-thumb .a4-doc {
  width: $kResumeThumbDesignWidthPx !important;
  max-width: $kResumeThumbDesignWidthPx !important;
  min-height: 0 !important;
  height: auto !important;
  margin: 0 auto !important;
  padding: 5mm 6mm 6mm !important;
  box-shadow: none !important;
  overflow: hidden !important;
}
html.resume-thumb .a4-doc--dark { background: inherit !important; }
html.resume-thumb img,
html.resume-thumb .photo,
html.resume-thumb .headshot,
html.resume-thumb .rc-photo {
  max-width: 56px !important;
  max-height: 56px !important;
  width: 56px !important;
  height: 56px !important;
  object-fit: cover !important;
}
html.resume-thumb .rc-photo-ph {
  max-width: 48px !important;
  max-height: 48px !important;
  width: 48px !important;
  height: 48px !important;
  font-size: 9pt !important;
}
html.resume-thumb .t6-top .rc-photo,
html.resume-thumb .t6-top .rc-photo-ph {
  max-width: 44px !important;
  max-height: 44px !important;
  width: 44px !important;
  height: 44px !important;
}
</style>
''';

/// Keeps full server HTML (head styles + layout). Only adds thumbnail overrides.
String wrapResumeHtmlForThumbnail(String fullHtml) {
  final trimmed = fullHtml.trim();
  if (trimmed.isEmpty) return trimmed;

  // Already wrapped in a previous pass.
  if (trimmed.contains('resume-thumb-overrides')) return trimmed;

  var doc = trimmed;

  // Ensure html.resume-thumb class for override selectors.
  if (RegExp(r'<html\b[^>]*\bclass="[^"]*resume-thumb', caseSensitive: false).hasMatch(doc)) {
    // already has class
  } else if (RegExp(r'<html\b[^>]*\bclass="', caseSensitive: false).hasMatch(doc)) {
    doc = doc.replaceFirstMapped(
      RegExp(r'(<html\b[^>]*\bclass=")([^"]*)(")', caseSensitive: false),
      (m) => '${m.group(1)}${m.group(2)} resume-thumb${m.group(3)}',
    );
  } else {
    doc = doc.replaceFirst(
      RegExp(r'<html\b', caseSensitive: false),
      '<html class="resume-thumb"',
    );
  }

  // Consistent viewport for the 794px design canvas (Flutter scales via FittedBox).
  if (RegExp(r'<meta[^>]*name="viewport"', caseSensitive: false).hasMatch(doc)) {
    doc = doc.replaceFirst(
      RegExp(r'<meta[^>]*name="viewport"[^>]*>', caseSensitive: false),
      '<meta name="viewport" content="width=$kResumeThumbDesignWidthPx, initial-scale=1, maximum-scale=1, user-scalable=no">',
    );
  } else {
    doc = doc.replaceFirst(
      RegExp(r'<head[^>]*>', caseSensitive: false),
      '<head>\n<meta name="viewport" content="width=$kResumeThumbDesignWidthPx, initial-scale=1, maximum-scale=1, user-scalable=no">',
    );
  }

  // Inject overrides after template CSS so layout (flex columns, colors) stays intact.
  if (RegExp(r'</head>', caseSensitive: false).hasMatch(doc)) {
    doc = doc.replaceFirst(
      RegExp(r'</head>', caseSensitive: false),
      '${_thumbOverrideStyles()}</head>',
    );
  } else {
    doc = '${_thumbOverrideStyles()}$doc';
  }

  return doc;
}
