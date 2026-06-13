import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'employer/employer_home.dart';
import 'job_seeker/job_seeker_home.dart';
import '../services/app_session.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/brand_dream_job_tagline.dart';

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
          settings: RouteSettings(
            name: next is JobSeekerHomeScreen
                ? JobSeekerHomeScreen.routeName
                : null,
          ),
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
    final role = AppSession.user?['role']?.toString().trim();
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background soft gradient glows (Top Left & Top Right)
          Positioned(
            left: -50,
            top: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFDE8E8).withOpacity(0.6),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: -20,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEBF5FF).withOpacity(0.8),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Wavy Background Curves
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: OnboardingBottomClipper(offset: 12),
              child: Container(
                height: size.height * 0.28,
                color: const Color(0xFF3B82F6).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: OnboardingBottomClipper(offset: 0),
              child: Container(
                height: size.height * 0.26,
                color: const Color(0xFF0F2C59),
              ),
            ),
          ),

          // Main Screen Layout
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Header (Logo & Brand Tagline)
                const AppLogo(height: 52),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 24, height: 1.5, color: const Color(0xFF0F2C59).withOpacity(0.6)),
                    const SizedBox(width: 10),
                    const Text(
                      'Right Job. Right Candidate',
                      style: TextStyle(
                        color: Color(0xFF0F2C59),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 24, height: 1.5, color: const Color(0xFF0F2C59).withOpacity(0.6)),
                  ],
                ),
                
                const Spacer(),

                // Illustration in the middle
                const MatchingIllustration(),
                
                const SizedBox(height: 24),

                // Text titles
                const Text(
                  'Find the Best.',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: Color(0xFF0D253F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Build the Future.',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: Color(0xFFE53E3E),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Smart hiring starts here.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Progress loading spinner inside/above the waves
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingBottomClipper extends CustomClipper<ui.Path> {
  final double offset;
  OnboardingBottomClipper({required this.offset});

  @override
  ui.Path getClip(ui.Size size) {
    final path = ui.Path();
    path.moveTo(0, size.height * 0.42 + offset);

    // Dynamic wave curves matching the mockup
    final control1 = ui.Offset(size.width * 0.25, size.height * 0.24 + offset);
    final end1 = ui.Offset(size.width * 0.5, size.height * 0.48 + offset);
    path.quadraticBezierTo(control1.dx, control1.dy, end1.dx, end1.dy);

    final control2 = ui.Offset(size.width * 0.75, size.height * 0.72 + offset);
    final end2 = ui.Offset(size.width, size.height * 0.56 + offset);
    path.quadraticBezierTo(control2.dx, control2.dy, end2.dx, end2.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<ui.Path> oldClipper) => true;
}

// Vector illustration widgets
class MatchingIllustration extends StatelessWidget {
  const MatchingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background particles/decorations (dots and crosses)
          Positioned(
            left: 60,
            top: 20,
            child: Icon(Icons.add, size: 14, color: Colors.red.shade400),
          ),
          Positioned(
            right: 50,
            top: 50,
            child: Icon(Icons.add, size: 14, color: Colors.blue.shade400),
          ),
          Positioned(
            left: 80,
            bottom: 40,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2C59),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 70,
            bottom: 60,
            child: Icon(Icons.add, size: 14, color: Colors.red.shade400),
          ),

          // Left background card
          Positioned(
            left: 50,
            child: Transform.translate(
              offset: const Offset(0, 10),
              child: Opacity(
                opacity: 0.5,
                child: _buildMiniCard(),
              ),
            ),
          ),

          // Right background card
          Positioned(
            right: 50,
            child: Transform.translate(
              offset: const Offset(0, 10),
              child: Opacity(
                opacity: 0.5,
                child: _buildMiniCard(),
              ),
            ),
          ),

          // Center focused card
          Positioned(
            child: Container(
              width: 130,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Rating Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => const Icon(
                        Icons.star_rounded,
                        color: Colors.red,
                        size: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mock text lines
                  _buildMockLine(width: 70),
                  const SizedBox(height: 6),
                  _buildMockLine(width: 50),
                  const SizedBox(height: 6),
                  _buildMockLine(width: 60),
                ],
              ),
            ),
          ),

          // Magnifying Glass
          Positioned(
            right: 55,
            bottom: 15,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0F2C59),
                  width: 6,
                ),
              ),
            ),
          ),
          Positioned(
            right: 48,
            bottom: 8,
            child: Transform.rotate(
              angle: -0.785, // 45 degrees
              child: Container(
                width: 6,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2C59),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Red badge with checkmark on center card top right
          Positioned(
            top: 22,
            right: 118,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard() {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.blue.shade400,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          _buildMockLine(width: 50),
          const SizedBox(height: 4),
          _buildMockLine(width: 40),
        ],
      ),
    );
  }

  Widget _buildMockLine({required double width}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
