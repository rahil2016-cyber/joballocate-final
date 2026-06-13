import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';

/// All plan activations stored on the server (survives app reinstall after login).
class PackagePurchaseHistoryScreen extends StatefulWidget {
  const PackagePurchaseHistoryScreen({super.key});

  @override
  State<PackagePurchaseHistoryScreen> createState() =>
      _PackagePurchaseHistoryScreenState();
}

class _PackagePurchaseHistoryScreenState
    extends State<PackagePurchaseHistoryScreen> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  /// null = all | resume | combo | job_applications
  String? _kindFilter;

  List<Map<String, dynamic>> get _visibleItems {
    if (_kindFilter == null) return List<Map<String, dynamic>>.from(_items);
    return _items
        .where((r) => (r['kind']?.toString() ?? '') == _kindFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && (_loading || _loadingMore)) return;
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _lastPage = 1;
        _items.clear();
      });
    } else {
      if (_page >= _lastPage) return;
      setState(() => _loadingMore = true);
    }

    final pageToLoad = refresh ? 1 : _page + 1;

    try {
      final raw = await JobSeekerApiService.instance.getPackagePurchases(
        page: pageToLoad,
        perPage: 25,
      );
      if (!mounted) return;
      final list = raw['items'];
      final meta = raw['meta'] as Map<String, dynamic>?;
      final items = list is List
          ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      setState(() {
        if (refresh) {
          _items
            ..clear()
            ..addAll(items);
        } else {
          _items.addAll(items);
        }
        _page = pageToLoad;
        if (meta != null) {
          final lp = meta['last_page'];
          _lastPage = lp is int ? lp : int.tryParse('$lp') ?? 1;
        }
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return DateFormat('MMM d, y · HH:mm').format(d);
  }

  String _kindLabel(String? k) {
    switch (k) {
      case 'resume':
        return 'Resume';
      case 'combo':
        return 'Combo';
      default:
        return 'Jobs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase history'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(refresh: true),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _load(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Icon(Icons.receipt_long_rounded,
                              size: 56, color: AppColors.textHint),
                          SizedBox(height: 16),
                          Text(
                            'No purchases yet.\nActivate a plan from Plans & packages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _KindChip(
                                    label: 'All',
                                    selected: _kindFilter == null,
                                    onTap: () =>
                                        setState(() => _kindFilter = null),
                                  ),
                                  const SizedBox(width: 8),
                                  _KindChip(
                                    label: 'Resume',
                                    selected: _kindFilter == 'resume',
                                    onTap: () => setState(
                                        () => _kindFilter = 'resume'),
                                  ),
                                  const SizedBox(width: 8),
                                  _KindChip(
                                    label: 'Combo',
                                    selected: _kindFilter == 'combo',
                                    onTap: () =>
                                        setState(() => _kindFilter = 'combo'),
                                  ),
                                  const SizedBox(width: 8),
                                  _KindChip(
                                    label: 'Jobs',
                                    selected:
                                        _kindFilter == 'job_applications',
                                    onTap: () => setState(
                                      () =>
                                          _kindFilter = 'job_applications',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _visibleItems.isEmpty
                                ? ListView(
                                    children: const [
                                      SizedBox(height: 48),
                                      Text(
                                        'No purchases in this category.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  )
                                : NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n.metrics.pixels >
                                          n.metrics.maxScrollExtent - 120) {
                                        _load();
                                      }
                                      return false;
                                    },
                                    child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: _visibleItems.length +
                              (_loadingMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= _visibleItems.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              );
                            }
                            final row = _visibleItems[i];
                            final title =
                                row['title']?.toString() ?? 'Package';
                            final price = row['price_inr'];
                            final priceStr = price is int
                                ? '₹$price'
                                : '₹${price ?? '—'}';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _kindLabel(
                                                row['kind']?.toString()),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      priceStr,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _line(
                                        Icons.play_circle_outline_rounded,
                                        'Activated',
                                        _fmt(row['activated_at']?.toString())),
                                    _line(
                                        Icons.event_rounded,
                                        'Expires',
                                        _fmt(row['expires_at']?.toString())),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Included: '
                                      '${row['applications_granted'] ?? 0} job applications · '
                                      '${row['resume_builds_granted'] ?? 0} resume builds · '
                                      '${row['duration_days'] ?? 0} days',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Key: ${row['package_key'] ?? '—'}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                                  ),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
