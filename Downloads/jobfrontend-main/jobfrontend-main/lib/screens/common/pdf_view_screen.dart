import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../utils/app_colors.dart';

class PdfViewScreen extends StatelessWidget {
  const PdfViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: uri == null
          ? const Center(
              child: Text(
                'Invalid PDF URL',
                style: TextStyle(color: AppColors.error),
              ),
            )
          : PdfViewer.uri(
              uri,
              params: PdfViewerParams(
                backgroundColor: AppColors.background,
                loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
              ),
            ),
    );
  }
}
