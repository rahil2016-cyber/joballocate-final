import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../job_seeker/job_seeker_home.dart';
import '../employer/employer_home.dart';
import 'job_seeker_otp_login.dart';
import 'employer_otp_login.dart';

/// Registration: collect profile details, then OTP (same API as login with [intent]: register).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 0 = details form, 1 = OTP
  int _step = 0;

  bool _isPhone = true;
  bool _isLoading = false;

  // Job seeker
  final TextEditingController _seekerNameController = TextEditingController();
  final TextEditingController _seekerContactController = TextEditingController();
  final TextEditingController _seekerCityController = TextEditingController();
  final TextEditingController _seekerHeadlineController = TextEditingController();

  // Company
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();

  final TextEditingController _otpController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool get _isJobSeeker => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_step == 0) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _seekerNameController.dispose();
    _seekerContactController.dispose();
    _seekerCityController.dispose();
    _seekerHeadlineController.dispose();
    _adminNameController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _gstController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final w = MediaQuery.of(context).size.width;
    final hPad = w > 600 ? 48.0 : 24.0;
    final maxContent = w > 560 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_step == 1) {
              setState(() {
                _step = 0;
                _otpController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContent),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppLogo(
                          size: 40,
                          color: _isJobSeeker || _step == 1 ? null : AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'JOBALLOCATE',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _isJobSeeker || _step == 1 ? AppColors.primary : AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _step == 0 ? 'Create account' : 'Verify your contact',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _isJobSeeker || _step == 1 ? AppColors.primary : AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 0
                          ? 'Tell us a bit about you. We use OTP only — no password to remember.'
                          : 'Enter the 6-digit code we sent. Companies are reviewed before full verification.',
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    if (_step == 0) ...[
                      _buildRoleTabs(),
                      const SizedBox(height: 24),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _isJobSeeker ? _buildJobSeekerForm(textTheme) : _buildCompanyForm(textTheme),
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Send verification code',
                        onPressed: _sendRegistrationOtp,
                        isLoading: _isLoading,
                        backgroundColor: _isJobSeeker ? AppColors.primary : AppColors.accent,
                      ),
                    ] else
                      _buildOtpStep(textTheme, hPad),
                    const SizedBox(height: 28),
                    if (_step == 0) _buildFooter(textTheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (_isJobSeeker ? AppColors.primary : AppColors.accent).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Job seeker'),
          Tab(text: 'Company'),
        ],
      ),
    );
  }

  Widget _buildJobSeekerForm(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Full name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'As on your ID / resume',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        _label('How should we reach you?', textTheme),
        const SizedBox(height: 8),
        _phoneEmailToggle(),
        const SizedBox(height: 12),
        TextField(
          controller: _seekerContactController,
          keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: _isPhone ? '+91 98765 43210' : 'you@email.com',
            prefixIcon: Icon(
              _isPhone ? Icons.phone_iphone_rounded : Icons.alternate_email_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('City (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerCityController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Bengaluru',
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        _label('Professional headline (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerHeadlineController,
          decoration: const InputDecoration(
            hintText: 'e.g. Flutter developer · 3 yrs exp',
            prefixIcon: Icon(Icons.work_outline_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyForm(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _verificationInfoCard(),
        const SizedBox(height: 20),
        _label('Your name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _adminNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Primary contact person',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Company name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Registered business name',
            prefixIcon: Icon(Icons.business_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Business email', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'hr@company.com',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Industry (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _industryController,
          decoration: const InputDecoration(
            hintText: 'e.g. IT Services, Healthcare',
            prefixIcon: Icon(Icons.category_outlined, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Website (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://',
            prefixIcon: Icon(Icons.language_rounded, color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  Widget _verificationInfoCard() {
    return Material(
      color: AppColors.accentLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your company is not verified immediately. '
                'After signup you can post jobs; unverified companies may need admin approval before listings go live.',
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.9),
                  height: 1.4,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneEmailToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleChip(
              title: 'Phone',
              selected: _isPhone,
              onTap: () => setState(() => _isPhone = true),
            ),
          ),
          Expanded(
            child: _toggleChip(
              title: 'Email',
              selected: !_isPhone,
              onTap: () => setState(() => _isPhone = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _label(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOtpStep(TextTheme textTheme, double hPad) {
    final contact = _isJobSeeker
        ? _seekerContactController.text.trim()
        : _companyEmailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isJobSeeker
              ? 'Code sent to ${_isPhone ? 'phone' : 'email'}'
              : 'Code sent to $contact',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(
          ApiService.demoMode
              ? 'Enter the 6-digit code (demo: ${ApiService.demoOtp}).'
              : 'Enter the 6-digit verification code.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Center(
          child: OtpInputField(
            controller: _otpController,
            onCompleted: (_) => _verifyRegistration(),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Verify & create account',
          onPressed: _verifyRegistration,
          isLoading: _isLoading,
          backgroundColor: _isJobSeeker ? AppColors.primary : AppColors.accent,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _sendRegistrationOtp,
            child: Text(
              'Resend code',
              style: TextStyle(
                color: _isJobSeeker ? AppColors.primary : AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Column(
      children: [
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already registered? ', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () {
                if (_isJobSeeker) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                  );
                }
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      ],
    );
  }

  bool _validateSeeker() {
    if (_seekerNameController.text.trim().isEmpty) {
      _snack('Please enter your full name');
      return false;
    }
    final c = _seekerContactController.text.trim();
    if (c.isEmpty) {
      _snack('Please enter phone or email');
      return false;
    }
    if (!_isPhone) {
      if (!c.contains('@') || c.length < 5) {
        _snack('Please enter a valid email');
        return false;
      }
    } else {
      final digits = RegExp(r'\d').allMatches(c).length;
      if (digits < 10) {
        _snack('Please enter a valid phone number');
        return false;
      }
    }
    return true;
  }

  bool _validateCompany() {
    if (_adminNameController.text.trim().isEmpty) {
      _snack('Please enter your name');
      return false;
    }
    if (_companyNameController.text.trim().isEmpty) {
      _snack('Please enter company name');
      return false;
    }
    final email = _companyEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid business email');
      return false;
    }
    return true;
  }

  Future<void> _sendRegistrationOtp() async {
    if (_step == 0) {
      if (_isJobSeeker) {
        if (!_validateSeeker()) return;
      } else {
        if (!_validateCompany()) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final identifier = _isJobSeeker
          ? _seekerContactController.text.trim()
          : _companyEmailController.text.trim();

      final result = await _apiService.sendOtp(
        identifier,
        intent: 'register',
        role: _isJobSeeker ? 'job_seeker' : 'company',
      );

      setState(() {
        _isLoading = false;
        _step = 1;
      });

      final mock = result['data'] is Map ? result['data']['mock_otp'] : null;

      if (ApiService.demoMode) {
        _otpController.text = ApiService.demoOtp;
        _snack('Demo code: ${ApiService.demoOtp}', err: false);
        Future.delayed(const Duration(milliseconds: 350), _verifyRegistration);
      } else if (mock != null) {
        _otpController.text = mock.toString();
        _snack('Dev OTP: $mock', err: false);
      } else {
        _snack('Verification code sent.', err: false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Could not send code: $e');
    }
  }

  Future<void> _verifyRegistration() async {
    if (_otpController.text.length != 6) {
      _snack('Enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final identifier = _isJobSeeker
          ? _seekerContactController.text.trim()
          : _companyEmailController.text.trim();

      if (_isJobSeeker) {
        await _apiService.verifyOtp(
          identifier,
          _otpController.text.trim(),
          intent: 'register',
          role: 'job_seeker',
          name: _seekerNameController.text.trim(),
        );
      } else {
        await _apiService.verifyOtp(
          identifier,
          _otpController.text.trim(),
          intent: 'register',
          role: 'company',
          name: _adminNameController.text.trim(),
          companyName: _companyNameController.text.trim(),
          gstNumber: _gstController.text.trim().isEmpty
              ? null
              : _gstController.text.trim(),
        );
      }

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (_isJobSeeker) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => JobSeekerHomeScreen(
              userId: AppSession.userId,
              token: AppSession.token,
            ),
          ),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmployerHomeScreen(token: AppSession.token),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _snack('Verification failed: $e');
    }
  }

  void _snack(String msg, {bool err = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
