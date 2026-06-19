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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Card containing logo and vector tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(height: 52),
                        const SizedBox(height: 12),
                        // Premium vector tagline matching the brand logo design
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53E3E), // Brand Red
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RIGHT JOB, RIGHT CANDIDATE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                color: Color(0xFF1E293B), // Dark slate
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFF174A7E), // Brand Blue
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Handshake Illustration - sized responsively to prevent overlap
                  Image.asset(
                    'assets/images/handshake_illustration.png',
                    height: screenSize.height > 700 ? 180 : 130,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Icon(
                      Icons.handshake_rounded,
                      size: screenSize.height > 700 ? 100 : 80,
                      color: const Color(0xFF174A7E).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions Area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Button: I'm a Job Seeker
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF174A7E),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF174A7E).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'I\'m a Job Seeker',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Button: I'm an Employer
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF174A7E), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'I\'m an Employer',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF174A7E), letterSpacing: 0.5),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF174A7E)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or continue with',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                              borderRadius: BorderRadius.circular(16),
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
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms & Conditions',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
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
    );
  }
}
