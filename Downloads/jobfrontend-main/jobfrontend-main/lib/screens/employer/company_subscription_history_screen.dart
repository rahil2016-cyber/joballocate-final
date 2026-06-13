import 'package:flutter/material.dart';

import '../../services/company_subscription_api_service.dart';
import '../../utils/app_colors.dart';

class CompanySubscriptionHistoryScreen extends StatefulWidget {
  const CompanySubscriptionHistoryScreen({super.key});

  @override
  State<CompanySubscriptionHistoryScreen> createState() =>
      _CompanySubscriptionHistoryScreenState();
}

class _CompanySubscriptionHistoryScreenState
    extends State<CompanySubscriptionHistoryScreen> {
  final _api = CompanySubscriptionApiService.instance;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

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
      final items = await _api.history();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  String _fmtDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Subscription history',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        'No purchases yet.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          final cycle = it['cycle_number'];
                          final amount = it['amount_inr'];
                          final isFree = it['is_free'] == true;
                          final coupon = it['coupon_code_used']?.toString();
                          final purchasedAt = it['purchased_at']?.toString().trim();

                          final cycleStr = cycle?.toString() ?? '—';
                          final amountStr = amount?.toString() ?? '0';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFree
                                            ? AppColors.success.withOpacity(0.12)
                                            : AppColors.primary.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isFree ? 'FREE' : 'INR $amountStr',
                                        style: TextStyle(
                                          color: isFree
                                              ? AppColors.success
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Cycle #$cycleStr',
                                      style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _fmtDate(purchasedAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (coupon != null && coupon.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.confirmation_number_outlined,
                                        size: 16,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Coupon: $coupon',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
