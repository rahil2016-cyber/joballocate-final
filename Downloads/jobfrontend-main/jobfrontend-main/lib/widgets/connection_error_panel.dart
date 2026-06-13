import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/network_user_message.dart';

/// Modal alert for connectivity / timeout issues (call after load failures).
Future<void> showNetworkIssueAlert(
  BuildContext context, {
  required Object error,
  VoidCallback? onRetry,
}) {
  final d = NetworkUserMessage.describe(error);
  final title = d?.title ?? 'Unable to load';
  final body = d != null
      ? d.message
      : NetworkUserMessage.fullUserMessage(error);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.signal_wifi_off_rounded,
        size: 40,
        color: AppColors.primary.withValues(alpha: 0.9),
      ),
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(body),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
        if (onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRetry();
            },
            child: const Text('Try again'),
          ),
      ],
    ),
  );
}

/// Full-screen style panel: icon, title, message, retry (pull-to-refresh still works on parent).
class ConnectionErrorPanel extends StatelessWidget {
  const ConnectionErrorPanel({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
