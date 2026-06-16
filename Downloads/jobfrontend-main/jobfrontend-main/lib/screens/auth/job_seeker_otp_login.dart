import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../job_seeker/job_seeker_home.dart';
import '../job_seeker/job_seeker_onboarding_screen.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_dream_job_tagline.dart';
import 'register_screen.dart';

class JobSeekerOtpLoginScreen extends StatefulWidget {
  const JobSeekerOtpLoginScreen({super.key});

  @override
  State<JobSeekerOtpLoginScreen> createState() => _JobSeekerOtpLoginScreenState();
}

class _JobSeekerOtpLoginScreenState extends State<JobSeekerOtpLoginScreen> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPhone = true;
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
              
              // Header
              Text(
                'Welcome Back!',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Login to explore thousands of jobs tailored just for you.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 48),

              // Contact Method Toggle (Custom)
              Container(
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleItem(
                        title: 'Phone',
                        isSelected: _isPhone,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _isPhone = true);
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildToggleItem(
                        title: 'Email',
                        isSelected: !_isPhone,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _isPhone = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Input Field
              Text(
                _isPhone ? 'Phone Number' : 'Email Address',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: ValueKey(_isPhone ? 'phone' : 'email'),
                controller: _contactController,
                keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isPhone ? '+91 98765 43210' : 'name@example.com',
                  prefixIcon: Icon(
                    _isPhone ? Icons.phone_iphone_rounded : Icons.alternate_email_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Password Field
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
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Log in',
                onPressed: _login,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'New to JobAllocate? ',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Create account',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _buildToggleItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final raw = _contactController.text.trim();
    final password = _passwordController.text;

    if (raw.isEmpty) {
      _showSnackBar('Please enter your contact information');
      return;
    }
    if (!_isPhone) {
      final email = raw.toLowerCase();
      if (!email.contains('@') || !email.contains('.')) {
        _showSnackBar('Please enter a valid email address');
        return;
      }
    }
    if (password.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.loginWithPassword(
        identifier: raw,
        password: password,
        role: 'job_seeker',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            settings: const RouteSettings(name: JobSeekerHomeScreen.routeName),
            pageBuilder: (context, animation, secondaryAnimation) => JobSeekerHomeScreen(
              userId: AppSession.userId,
              token: AppSession.token,
            ),
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
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}