import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/api_config.dart';
import 'firebase_bootstrap.dart';
import 'screens/auth/job_seeker_otp_login.dart';
import 'screens/auth/employer_otp_login.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_session.dart';
import 'navigation/app_navigator.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/brand_dream_job_tagline.dart';
import 'widgets/job_deep_link_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await AppSession.loadFromStorage();
  await tryInitializeFirebase();
  runApp(const ProviderScope(child: JobAllocateApp()));
}

class JobAllocateApp extends StatelessWidget {
  const JobAllocateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return JobDeepLinkListener(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'JobAllocate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(fallbackScreen: RoleSelectionScreen()),
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Logo
                      const AppLogo(height: 64),
                      const SizedBox(height: 24),

                      // Heading
                      Text(
                        'Right Job.',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: const Color(0xFF174A7E),
                        ),
                      ),
                      Text(
                        'Right Candidates.',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: const Color(0xFFE53E3E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Connecting the right opportunities with the right people.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Handshake Illustration
                      Image.asset(
                        'assets/images/handshake_illustration.png',
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Icon(
                          Icons.handshake_rounded,
                          size: 100,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Button: I'm a Job Seeker
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D253F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'I\'m a Job Seeker',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button: I'm an Employer
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'I\'m an Employer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D253F)),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF0D253F)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Button: Continue with Google
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Sign-In coming soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          height: 20,
                          width: 20,
                          errorBuilder: (ctx, err, stack) => const Icon(Icons.g_mobiledata_rounded, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Footer
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Conditions',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
