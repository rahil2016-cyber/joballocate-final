import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo placeholder / App Name
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'JobAllocate',
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Empowering careers through smart matching and powerful resume building tools.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            
            _buildSectionTitle('Connect with us'),
            const SizedBox(height: 20),

            _SocialTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'WhatsApp Support',
              color: const Color(0xFF25D366),
              onTap: () => _launchUrl('https://wa.me/918884644432'),
            ),
            
            _SocialTile(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () => _launchUrl('https://facebook.com/joballocate'),
            ),
            _SocialTile(
              icon: Icons.play_circle_fill_rounded,
              label: 'YouTube',
              color: const Color(0xFFFF0000),
              onTap: () => _launchUrl('https://youtube.com/@joballocate'),
            ),
            _SocialTile(
              icon: Icons.camera_alt_rounded,
              label: 'Instagram',
              color: const Color(0xFFE4405F),
              onTap: () => _launchUrl('https://instagram.com/joballocate'),
            ),
            _SocialTile(
              icon: Icons.business_rounded,
              label: 'LinkedIn',
              color: const Color(0xFF0A66C2),
              onTap: () => _launchUrl('https://linkedin.com/company/joballocate'),
            ),
            _SocialTile(
              icon: Icons.language_rounded,
              label: 'Official Website',
              color: AppColors.primary,
              onTap: () => _launchUrl('https://joballocate.com'),
            ),
            
            const SizedBox(height: 40),
            Text(
              'Version 1.0.0',
              style: tt.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
