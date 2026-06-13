import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../employer/employer_home.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_dream_job_tagline.dart';
import 'register_screen.dart';

class EmployerOtpLoginScreen extends StatefulWidget {
  const EmployerOtpLoginScreen({super.key});

  @override
  State<EmployerOtpLoginScreen> createState() => _EmployerOtpLoginScreenState();
}

class _EmployerOtpLoginScreenState extends State<EmployerOtpLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo and app name
              const Row(
                children: [
                   AppLogo(),
                ],
              ),
              const SizedBox(height: 16),
              BrandDreamJobTagline(
                crossAxisAlignment: CrossAxisAlignment.start,
                textAlign: TextAlign.start,
                headlineStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                taglineStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                spacing: 6,
              ),
              const SizedBox(height: 24),

              // Employer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_center_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Employer Account',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Welcome,\nEmployer!',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Login to post jobs and manage your candidates.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 48),

              // Email Input
              Text(
                'Business Email',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'company@example.com',
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Password',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Log in',
                onPressed: _login,
                isLoading: _isLoading,
                backgroundColor: AppColors.accent,
              ),

              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'New company? ',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen(showJobSeeker: false)),
                        );
                      },
                      child: Text(
                        'Create account',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
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
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.loginWithPassword(
        identifier: email,
        password: password,
        role: 'company',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                EmployerHomeScreen(token: AppSession.token),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(ApiService.messageFromException(e));
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}