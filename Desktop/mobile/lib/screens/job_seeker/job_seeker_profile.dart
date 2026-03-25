import 'package:flutter/material.dart';
import '../../constants/industry_types.dart';
import '../../main.dart' show RoleSelectionScreen;
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import './package_purchase_history_screen.dart';
import './packages_screen.dart';
import './resume_templates_screen.dart';
import 'job_seeker_profile_edit_sheet.dart';

int _profileCompletenessPercent(Map<String, dynamic> p) {
  int s = 0;
  bool ne(dynamic v) =>
      v != null && v.toString().trim().isNotEmpty;

  if (ne(p['headline'])) s += 14;
  if (ne(p['bio'])) s += 14;
  final skills = p['skills'];
  if (skills is List && skills.isNotEmpty) s += 20;
  if (ne(p['city'])) s += 14;
  if (ne(p['country'])) s += 14;
  if (p['experience_years'] != null) s += 12;
  if (p['expected_salary_min'] != null || p['expected_salary_max'] != null) {
    s += 12;
  }
  return s.clamp(0, 100);
}

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
  return (p.first[0] + p.last[0]).toUpperCase();
}

class JobSeekerProfileScreen extends StatefulWidget {
  const JobSeekerProfileScreen({super.key});

  @override
  State<JobSeekerProfileScreen> createState() => _JobSeekerProfileScreenState();
}

class _JobSeekerProfileScreenState extends State<JobSeekerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!AppSession.isLoggedIn) {
      setState(() {
        _loading = false;
        _error = 'Not logged in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
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

  Map<String, dynamic>? get _user => AppSession.user;

  String get _displayName =>
      _user?['name']?.toString().trim().isNotEmpty == true
          ? _user!['name'].toString()
          : 'Job seeker';

  String get _email => _user?['email']?.toString() ?? '—';

  String get _phone => _user?['phone']?.toString() ?? '—';

  void _openEdit() {
    final p = _profile;
    if (p == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobSeekerProfileEditSheet(
        initial: Map<String, dynamic>.from(p),
        onSaved: () async {
          await _load();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use JobAllocate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = _profile;
    final complete = p != null ? _profileCompletenessPercent(p) : 0;

    final city = p?['city']?.toString() ?? '';
    final country = p?['country']?.toString() ?? '';
    final location = [city, country].where((e) => e.isNotEmpty).join(', ');
    final headline = p?['headline']?.toString() ?? '';
    final bio = p?['bio']?.toString() ?? '';
    final skills = p?['skills'] is List
        ? (p!['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final expYears = p?['experience_years'];
    final smin = p?['expected_salary_min'];
    final smax = p?['expected_salary_max'];

    final uid = AppSession.userId ?? '';
    final tok = AppSession.token ?? '';

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null && p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _initials(_displayName),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          location.isEmpty ? 'Add location in Edit profile' : location,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 60),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Profile completeness',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$complete%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: complete / 100,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.edit_document,
                            label: 'Edit Profile',
                            onTap: _openEdit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.description_rounded,
                            label: 'My Resume',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResumeTemplatesScreen(
                                  userId: uid.isEmpty ? 'demo-user' : uid,
                                  token: tok.isEmpty ? 'demo-token' : tok,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Plans & packages',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JobSeekerPackagesScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.receipt_long_rounded,
                            label: 'Purchase history',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PackagePurchaseHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('More settings coming soon'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (headline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          headline,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    _buildSectionCard(
                      title: 'About Me',
                      icon: Icons.person_outline_rounded,
                      child: Text(
                        bio.isEmpty
                            ? 'Tell employers about yourself — tap Edit Profile.'
                            : bio,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontStyle:
                              bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      child: Column(
                        children: [
                          _buildContactRow(Icons.email_outlined, _email),
                          const SizedBox(height: 12),
                          _buildContactRow(Icons.phone_outlined, _phone),
                          const SizedBox(height: 12),
                          _buildContactRow(
                            Icons.location_on_outlined,
                            location.isEmpty ? '—' : location,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (p != null &&
                        (p['industry_type']?.toString().trim().isNotEmpty ??
                            false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSectionCard(
                          title: 'Industry / role type',
                          icon: Icons.business_center_outlined,
                          child: Text(
                            industryTypeLabel(p['industry_type']?.toString()),
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    _buildEducationCard(p, textTheme),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Skills',
                      icon: Icons.code_rounded,
                      child: skills.isEmpty
                          ? Text(
                              'No skills yet — add them in Edit Profile.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: skills.map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Career preferences',
                      icon: Icons.work_outline_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expYears != null
                                ? 'Experience: $expYears years'
                                : 'Experience: not set',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            smin != null || smax != null
                                ? 'Expected salary: ₹${smin ?? '—'} – ₹${smax ?? '—'} / year'
                                : 'Expected salary: not set',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic>? p, TextTheme textTheme) {
    final raw = p?['education'];
    final rows = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        }
      }
    }
    final hasContent = rows.any((m) =>
        (m['title']?.toString().trim().isNotEmpty == true) ||
        (m['institution']?.toString().trim().isNotEmpty == true));

    return _buildSectionCard(
      title: 'Education',
      icon: Icons.school_outlined,
      child: !hasContent
          ? Text(
              'Add Class 10, 12, diploma or degree — tap Edit Profile.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in rows)
                  if ((m['title']?.toString().trim().isNotEmpty == true) ||
                      (m['institution']?.toString().trim().isNotEmpty == true))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['title']?.toString().trim().isNotEmpty == true
                                ? m['title'].toString()
                                : m['institution'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (m['title']?.toString().trim().isNotEmpty ==
                                  true &&
                              m['institution']?.toString().trim().isNotEmpty ==
                                  true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                m['institution'].toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (m['board_or_stream']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true)
                            Text(
                              m['board_or_stream'].toString(),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          if (m['marks_or_grade']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true ||
                              m['year_completed']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true)
                            Text(
                              [
                                if (m['marks_or_grade']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                  m['marks_or_grade'].toString(),
                                if (m['year_completed']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ==
                                    true)
                                  m['year_completed'].toString(),
                              ].join(' · '),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
