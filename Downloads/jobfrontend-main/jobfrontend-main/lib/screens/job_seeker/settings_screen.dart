import 'package:flutter/material.dart';
import '../../services/app_session.dart';
import '../../services/refer_earn_api_service.dart';
import '../../utils/app_colors.dart';
import '../common/refer_and_earn_screen.dart';
import 'my_resumes_screen.dart';
import 'resume_templates_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _referLoading = true;
  bool _referEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadReferFlag();
  }

  Future<void> _loadReferFlag() async {
    try {
      final data = await ReferEarnApiService.instance.fetchReferEarn(
        audience: 'job_seeker',
      );
      if (!mounted) return;
      setState(() {
        _referEnabled = data['enabled'] == true;
        _referLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _referEnabled = false;
        _referLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _SettingsTile(
            icon: Icons.description_rounded,
            title: 'Resume',
            subtitle: 'Choose a template, edit, and download PDF (₹20 demo)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResumeTemplatesScreen(
                    userId: AppSession.userId ?? 'demo-user',
                    token: AppSession.token ?? 'demo-token',
                  ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            title: 'My saved resumes',
            subtitle: 'Drafts you saved and which one employers see when you apply',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MyResumesScreen(
                    userId: AppSession.userId ?? 'demo-user',
                    token: AppSession.token ?? 'demo-token',
                  ),
                ),
              );
            },
          ),
          if (!_referLoading && _referEnabled)
            _SettingsTile(
              icon: Icons.card_giftcard_rounded,
              title: 'Refer & earn',
              subtitle: 'Share your code and earn rewards',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReferAndEarnScreen(audience: 'job_seeker'),
                  ),
                );
              },
            ),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Account',
            subtitle: 'Change your primary email, mobile number or password',
            onTap: () => _showComingSoon(context, 'Account Settings'),
          ),
          _SettingsTile(
            icon: Icons.work_outline_rounded,
            title: 'Career preferences',
            subtitle: 'Job recommendations based on your career preferences',
            onTap: () => _showComingSoon(context, 'Career Preferences'),
          ),
          _SettingsTile(
            icon: Icons.block_rounded,
            title: 'Blocked companies',
            subtitle: 'Choose the companies you do not want to show your profile to',
            onTap: () => _showComingSoon(context, 'Blocked Companies'),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'App',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _showComingSoon(context, 'Notifications'),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Manage who can see your profile',
            onTap: () => _showComingSoon(context, 'Privacy Settings'),
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'Select your preferred language',
            onTap: () => _showComingSoon(context, 'Language'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textHint,
        ),
        onTap: onTap,
      ),
    );
  }
}
