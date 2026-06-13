import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'job_seeker_home.dart';

/// Full-screen confirmation after a job application is sent.
class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({
    super.key,
    required this.companyName,
  });

  final String companyName;

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == JobSeekerHomeScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.82),
                      const Color(0xFF059669),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Successfully applied for job!',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Your application has been sent to $companyName',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textHint.withOpacity(0.85),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We will notify you if you are shortlisted.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textHint.withOpacity(0.85),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _goHome(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Go to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
