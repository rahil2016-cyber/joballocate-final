// Default PDF fonts (Helvetica) lack many Unicode glyphs (bullets, em dash); they render as tofu.
// Use [pdfSafe] on user-facing strings and [pdfListPrefix] for list markers.

const String pdfListPrefix = '- ';

String pdfSafe(String s) {
  return s
      .replaceAll('\u2022', '-') // bullet
      .replaceAll('\u2023', '-')
      .replaceAll('\u2043', '-')
      .replaceAll('\u2219', '-')
      .replaceAll('\u25AA', '-')
      .replaceAll('\u25CF', '-')
      .replaceAll('\u25E6', '-')
      .replaceAll('\u2014', '-') // em dash
      .replaceAll('\u2013', '-') // en dash
      .replaceAll('\u2212', '-'); // minus sign
}
