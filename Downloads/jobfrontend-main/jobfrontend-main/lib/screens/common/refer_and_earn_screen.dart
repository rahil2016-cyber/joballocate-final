import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/refer_earn_api_service.dart';
import '../../utils/app_colors.dart';

/// Refer & earn for job seekers (`audience=job_seeker`) or employers (`company`).
class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key, required this.audience});

  final String audience;

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ReferEarnApiService.instance.fetchReferEarn(
        audience: widget.audience,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open download link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final title = widget.audience == 'company' ? 'Refer & earn' : 'Refer & earn';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_data['enabled'] != true)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Text(
                            'Refer & earn is currently turned off by admin.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else ...[
                        Text(
                          'Your benefits',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (_data['benefits_text']?.toString().trim().isNotEmpty == true)
                              ? _data['benefits_text'].toString()
                              : 'Share your code with friends and earn rewards when they join.',
                          style: tt.bodyMedium?.copyWith(height: 1.4, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if ((_data['my_referral_code']?.toString() ?? '').isNotEmpty) ...[
                          Text('Your referral code', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _data['my_referral_code'].toString(),
                                    style: tt.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _copy(_data['my_referral_code'].toString(), 'Code'),
                                  icon: const Icon(Icons.copy_rounded),
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final share = _data['share_message']?.toString() ?? '';
                                if (share.isNotEmpty) _copy(share, 'Share message');
                              },
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Copy share message'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_data['play_store_coming_soon'] == true) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.android_rounded, color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Play Store — coming soon',
                                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Share your referral code now. When someone registers, they can enter this code on the sign-up screen.',
                                ),
                              ],
                            ),
                          ),
                        ] else if ((_data['app_download_url']?.toString() ?? '').isNotEmpty) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _openDownload(_data['app_download_url'].toString()),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Download the app'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          widget.audience == 'company'
                              ? 'Employer subscription coupons (e.g. first month free) are used on the Subscriptions tab — not at registration.'
                              : 'Company-only coupons cannot be used on job seeker sign-up.',
                          style: tt.bodySmall?.copyWith(color: AppColors.textHint, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
