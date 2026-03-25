import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../employer/employer_home.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';

class EmployerOtpLoginScreen extends StatefulWidget {
  const EmployerOtpLoginScreen({super.key});

  @override
  State<EmployerOtpLoginScreen> createState() => _EmployerOtpLoginScreenState();
}

class _EmployerOtpLoginScreenState extends State<EmployerOtpLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
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
              Row(
                children: [
                   const AppLogo(size: 40),
                   const SizedBox(width: 12),
                   Text(
                     'JOBALLOCATE',
                     style: textTheme.headlineSmall?.copyWith(
                       fontWeight: FontWeight.w900,
                       color: AppColors.primary,
                       letterSpacing: 0.5,
                     ),
                   ),
                ],
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
                decoration: InputDecoration(
                  hintText: 'company@example.com',
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.accent,
                  ),
                ),
                onChanged: (_) {
                  if (_otpSent) setState(() => _otpSent = false);
                },
              ),

              const SizedBox(height: 32),

              if (!_otpSent)
                CustomButton(
                  text: 'Send Verification Code',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.accent,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Code',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ApiService.demoMode
                          ? 'Enter the 6-digit code (demo: ${ApiService.demoOtp}).'
                          : 'Enter the 6-digit code sent to your email.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: OtpInputField(
                        controller: _otpController,
                        onCompleted: (otp) => _verifyOtp(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Verify & Continue',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                      backgroundColor: AppColors.accent,
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text(
                          'Didn\'t receive the code? Resend',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
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

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.sendOtp(
        _emailController.text.trim(),
        intent: 'login',
        role: 'company',
      );

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      final mock = result['data'] is Map ? result['data']['mock_otp'] : null;

      if (ApiService.demoMode) {
        _otpController.text = ApiService.demoOtp;
        _showSnackBar('Verification code sent (demo: ${ApiService.demoOtp})', isError: false);
        Future.delayed(const Duration(milliseconds: 300), _verifyOtp);
      } else if (mock != null) {
        _otpController.text = mock.toString();
        _showSnackBar('OTP from server (dev): $mock', isError: false);
      } else {
        _showSnackBar('Verification code sent.', isError: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to send code: $e');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.verifyOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
        intent: 'login',
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
      _showSnackBar('Invalid verification code: $e');
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
    _otpController.dispose();
    super.dispose();
  }
}