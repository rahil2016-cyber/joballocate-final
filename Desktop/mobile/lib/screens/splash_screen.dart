import 'package:flutter/material.dart';
import 'employer/employer_home.dart';
import 'job_seeker/job_seeker_home.dart';
import '../services/app_session.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  /// Shown when there is no saved session (or unknown role).
  final Widget fallbackScreen;

  const SplashScreen({super.key, required this.fallbackScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      final next = _resolveStartScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => next,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Logged-in users go straight to their dashboard; others see [fallbackScreen].
  Widget _resolveStartScreen() {
    if (!AppSession.isLoggedIn) return widget.fallbackScreen;
    final role = AppSession.user?['role']?.toString();
    if (role == 'company') {
      return EmployerHomeScreen(token: AppSession.token);
    }
    if (role == 'job_seeker') {
      return JobSeekerHomeScreen(
        userId: AppSession.userId,
        token: AppSession.token,
      );
    }
    return widget.fallbackScreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLogo(size: 120),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Animated Text
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    Text(
                      'JOBALLOCATE',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The Future of Job Discovery',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            // Loading indicator
            FadeTransition(
              opacity: _textOpacity,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
