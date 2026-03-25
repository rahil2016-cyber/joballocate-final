import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'screens/auth/job_seeker_otp_login.dart';
import 'screens/auth/employer_otp_login.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_session.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';
import 'widgets/app_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await AppSession.loadFromStorage();
  runApp(const JobAllocateApp());
}

class JobAllocateApp extends StatelessWidget {
  const JobAllocateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobAllocate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(fallbackScreen: RoleSelectionScreen()),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: _buildDecorativeCircle(240, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildDecorativeCircle(200, Colors.white.withOpacity(0.05)),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  
                  // Logo & Brand
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const AppLogo(size: 50),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'JOBALLOCATE',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The Future of Job Discovery',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Role Selection Header
                  Text(
                    'Let\'s Get Started',
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your path to begin your journey.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Role Cards
                  _buildRoleCard(
                    context: context,
                    title: 'Job Seeker',
                    subtitle: 'Find your dream job and apply anywhere.',
                    icon: Icons.person_search_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  _buildRoleCard(
                    context: context,
                    title: 'Employer',
                    subtitle: 'Post jobs and hire top talent instantly.',
                    icon: Icons.business_center_rounded,
                    accent: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(
                            'Register Now',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent ? AppColors.accentLight : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: accent ? AppColors.accent : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
