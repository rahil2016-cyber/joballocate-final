import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../job_seeker/job_seeker_home.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';

class JobSeekerOtpLoginScreen extends StatefulWidget {
  const JobSeekerOtpLoginScreen({super.key});

  @override
  State<JobSeekerOtpLoginScreen> createState() => _JobSeekerOtpLoginScreenState();
}

class _JobSeekerOtpLoginScreenState extends State<JobSeekerOtpLoginScreen> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isPhone = true;
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
                        onTap: () => setState(() => _isPhone = true),
                      ),
                    ),
                    Expanded(
                      child: _buildToggleItem(
                        title: 'Email',
                        isSelected: !_isPhone,
                        onTap: () => setState(() => _isPhone = false),
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
                controller: _contactController,
                keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isPhone ? '+91 98765 43210' : 'name@example.com',
                  prefixIcon: Icon(
                    _isPhone ? Icons.phone_iphone_rounded : Icons.alternate_email_rounded,
                    color: AppColors.primary,
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
                          : 'Enter the 6-digit code sent to your ${_isPhone ? 'phone' : 'email'}.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    
                    // OTP Input
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
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text(
                          'Didn\'t receive the code? Resend',
                          style: TextStyle(
                            color: AppColors.primary,
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

  Future<void> _sendOtp() async {
    if (_contactController.text.isEmpty) {
      _showSnackBar('Please enter your contact information');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.sendOtp(
        _contactController.text.trim(),
        intent: 'login',
        role: 'job_seeker',
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
        _contactController.text.trim(),
        _otpController.text.trim(),
        intent: 'login',
        role: 'job_seeker',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
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
      _showSnackBar('Invalid verification code');
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
    _otpController.dispose();
    super.dispose();
  }
}