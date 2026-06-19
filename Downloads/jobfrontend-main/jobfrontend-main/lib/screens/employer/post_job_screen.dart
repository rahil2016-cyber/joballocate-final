import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/company_api_service.dart';
import '../../services/company_subscription_api_service.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';
import '../../constants/employer_status_labels.dart';
import '../../widgets/industry_type_dropdown.dart';
import '../../constants/industry_roles_skills.dart';
import '../../constants/industry_types.dart';

/// Maps UI dropdown values to API strings
String _employmentTypeApi(String ui) {
  switch (ui) {
    case 'full_time':
      return 'full_time';
    case 'part_time':
      return 'part_time';
    case 'contract':
      return 'contract';
    case 'internship':
      return 'internship';
    case 'freelance':
      return 'freelance';
    default:
      return ui;
  }
}

String _experienceApi(String ui) {
  switch (ui) {
    case 'fresher':
      return 'fresher';
    case 'junior':
      return 'junior';
    case 'mid':
      return 'mid_level';
    case 'senior':
      return 'senior';
    case 'lead':
      return 'lead';
    default:
      return ui;
  }
}

String _workModeApi(String ui) {
  switch (ui) {
    case 'office':
      return 'office';
    case 'home':
      return 'home';
    case 'hybrid':
    case 'both':
      return 'hybrid';
    default:
      return 'office';
  }
}

String _employmentFromApi(String? api) {
  final v = (api ?? 'full_time').trim();
  const keys = {'full_time', 'part_time', 'contract', 'internship', 'freelance'};
  return keys.contains(v) ? v : 'full_time';
}

String _experienceFromApi(String? api) {
  switch (api) {
    case 'fresher':
      return 'fresher';
    case 'junior':
      return 'junior';
    case 'mid_level':
      return 'mid';
    case 'senior':
      return 'senior';
    case 'lead':
      return 'lead';
    default:
      return 'mid';
  }
}

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key, this.existingJob});

  final Map<String, dynamic>? existingJob;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Scroll and Step tracker
  final _scrollController = ScrollController();
  int _currentStep = 0; // 0: Job Details, 1: Job Descriptions, 2: Company Details

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _skillsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _salaryInsightsController = TextEditingController();
  final _roleCategoryController = TextEditingController();
  final _functionalAreaController = TextEditingController();
  final _educationController = TextEditingController(); // Min qualification

  // Extended form fields
  final _assetsRequiredController = TextEditingController();
  final _languagesController = TextEditingController(); // English speaking level
  final _incentiveDetailController = TextEditingController();
  final _jobTimingsController = TextEditingController();
  final _interviewTimingsController = TextEditingController();
  final _workingDaysController = TextEditingController();
  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();
  String _genderPreference = 'any';
  String _contactPreference = 'phone_call';
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _roleController = TextEditingController();

  // Company / Consultancy fields
  String _postingAs = 'company';
  final _consultancyNameController = TextEditingController();
  final _hiringForCompanyController = TextEditingController();
  final _companyAddressController = TextEditingController();
  bool _hideHiringCompany = false;

  // Selection states
  String _selectedJobType = 'full_time';
  String _selectedExperience = 'mid';
  String _selectedWorkMode = 'office';
  bool _securityDeposit = false;
  final _securityDepositAmountController = TextEditingController();
  bool _hasIncentive = false;
  String _lastAutoSetRole = '';
  String? _industryType;
  final _customIndustryController = TextEditingController();

  // Experience level preference: 'any', 'fresher', 'experienced'
  String _experiencePreference = 'any';

  final List<String> _addedSkills = [];
  bool _submitting = false;
  bool _isVerified = false;
  final _companyAboutController = TextEditingController();

  DateTime? _deadline;
  final _maxApplicationsController = TextEditingController();

  final _api = CompanyApiService.instance;

  int? get _editJobId {
    final j = widget.existingJob;
    if (j == null) return null;
    final raw = j['id'];
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static const List<String> _commonBenefits = [
    'Health Insurance',
    'Work From Home',
    'Flexible Hours',
    'Free Snacks / Meals',
    'Paid Time Off (PTO)',
    'Performance Bonus',
    'Travel Allowance',
    'Retirement Plan (PF)',
    'Sick Leave',
    'Free Training',
  ];

  List<String> get _parsedBenefits {
    final txt = _benefitsController.text.trim();
    if (txt.isEmpty) return [];
    return txt.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _toggleBenefit(String benefit) {
    final current = _parsedBenefits;
    if (current.contains(benefit)) {
      current.remove(benefit);
    } else {
      current.add(benefit);
    }
    setState(() {
      _benefitsController.text = current.join(', ');
    });
  }

  static const List<String> _timeOptions = [
    '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM',
    '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
    '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM',
    '05:00 PM', '05:30 PM', '06:00 PM', '06:30 PM', '07:00 PM', '07:30 PM',
    '08:00 PM'
  ];

  static const List<String> _dayRangeOptions = [
    'Monday to Saturday',
    'Monday to Friday',
    'Monday to Thursday',
    'Flexible / All Days',
    'Custom'
  ];

  String _selectedWorkDayRange = 'Monday to Saturday';
  String _workStartTime = '09:30 AM';
  String _workEndTime = '06:30 PM';

  String _selectedInterviewDayRange = 'Monday to Saturday';
  String _interviewStartTime = '11:00 AM';
  String _interviewEndTime = '04:00 PM';

  void _initTimings() {
    final workTxt = _jobTimingsController.text.trim();
    if (workTxt.isNotEmpty) {
      _parseTimingString(
        workTxt,
        (dayRange, start, end) {
          _selectedWorkDayRange = dayRange;
          _workStartTime = start;
          _workEndTime = end;
        },
      );
    } else {
      _updateWorkTimingText();
    }

    final interviewTxt = _interviewTimingsController.text.trim();
    if (interviewTxt.isNotEmpty) {
      _parseTimingString(
        interviewTxt,
        (dayRange, start, end) {
          _selectedInterviewDayRange = dayRange;
          _interviewStartTime = start;
          _interviewEndTime = end;
        },
      );
    } else {
      _updateInterviewTimingText();
    }
  }

  void _parseTimingString(String txt, void Function(String dayRange, String start, String end) onParsed) {
    try {
      final parts = txt.split('|');
      String dayRange = 'Custom';
      if (parts.length > 1) {
        final possibleDayRange = parts[1].trim();
        if (_dayRangeOptions.contains(possibleDayRange)) {
          dayRange = possibleDayRange;
        }
      }
      
      final timesPart = parts[0].trim();
      final timeSplit = timesPart.split('-');
      String start = '09:00 AM';
      String end = '05:00 PM';
      if (timeSplit.length > 1) {
        final possibleStart = _normalizeTime(timeSplit[0].trim());
        final possibleEnd = _normalizeTime(timeSplit[1].trim());
        if (_timeOptions.contains(possibleStart)) {
          start = possibleStart;
        }
        if (_timeOptions.contains(possibleEnd)) {
          end = possibleEnd;
        }
      }
      onParsed(dayRange, start, end);
    } catch (_) {
      onParsed('Custom', '09:00 AM', '05:00 PM');
    }
  }

  String _normalizeTime(String raw) {
    var clean = raw.toLowerCase().replaceAll('.', ':').replaceAll(' ', '');
    bool isPm = clean.contains('pm');
    bool isAm = clean.contains('am');
    clean = clean.replaceAll('pm', '').replaceAll('am', '');
    final parts = clean.split(':');
    if (parts.isEmpty) return '09:00 AM';
    
    int hour = int.tryParse(parts[0]) ?? 9;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    
    String period = 'AM';
    if (isPm) {
      period = 'PM';
    } else if (isAm) {
      period = 'AM';
    } else {
      if (hour >= 1 && hour <= 7) {
        period = 'PM';
      } else if (hour == 12) {
        period = 'PM';
      } else {
        period = 'AM';
      }
    }
    
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr $period';
  }

  void _updateWorkTimingText() {
    if (_selectedWorkDayRange == 'Custom') return;
    _jobTimingsController.text = '$_workStartTime - $_workEndTime | $_selectedWorkDayRange';
  }

  void _updateInterviewTimingText() {
    if (_selectedInterviewDayRange == 'Custom') return;
    _interviewTimingsController.text = '$_interviewStartTime - $_interviewEndTime | $_selectedInterviewDayRange';
  }

  bool get _isEdit => _editJobId != null;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    final j = widget.existingJob;
    if (j == null) {
      _initTimings();
      return;
    }
    
    _titleController.text = j['title']?.toString() ?? '';
    _descController.text = j['description']?.toString() ?? '';
    _requirementsController.text = j['requirements']?.toString() ?? '';
    _locationController.text = j['location']?.toString() ?? '';
    _companyAddressController.text = j['location']?.toString() ?? '';
    
    final sm = j['salary_min'];
    final sx = j['salary_max'];
    if (sm != null) _salaryMinController.text = sm.toString();
    if (sx != null) _salaryMaxController.text = sx.toString();
    
    _selectedJobType = _employmentFromApi(j['employment_type']?.toString());
    _selectedExperience = _experienceFromApi(j['experience_level']?.toString());
    
    final rawWorkMode = j['mode_of_work']?.toString() ?? j['work_mode']?.toString();
    final wm = rawWorkMode?.trim().toLowerCase();
    if (wm == 'home') {
      _selectedWorkMode = 'home';
    } else {
      _selectedWorkMode = 'office';
    }

    _securityDeposit = j['security_deposit'] == true;
    _securityDepositAmountController.text = j['security_deposit_amount']?.toString() ?? '';

    final skills = j['skills'];
    if (skills is List) {
      for (final s in skills) {
        if (s != null) {
          final t = s.toString().trim();
          if (t.isNotEmpty) _addedSkills.add(t);
        }
      }
    }
    
    final dl = j['application_deadline_at']?.toString();
    if (dl != null && dl.isNotEmpty) {
      _deadline = DateTime.tryParse(dl)?.toLocal();
    }
    
    final ma = j['max_applications'];
    if (ma != null) {
      _maxApplicationsController.text = ma.toString();
    }
    
    final itk = j['industry_type']?.toString();
    if (itk != null && itk.isNotEmpty) {
      final canonicalKeys = kIndustryTypes.map((e) => e.key).toSet();
      if (canonicalKeys.contains(itk)) {
        _industryType = itk;
      } else {
        _industryType = 'none_of_above';
        _customIndustryController.text = itk;
      }
    }
    
    _benefitsController.text = j['benefits']?.toString() ?? '';
    _salaryInsightsController.text = j['salary_insights']?.toString() ?? '';
    _companyAboutController.text = j['about_company']?.toString() ?? '';

    _postingAs = j['is_consultancy'] == true ? 'consultancy' : 'company';
    _consultancyNameController.text = j['consultancy_name']?.toString() ?? '';
    _hiringForCompanyController.text = j['hiring_for_company']?.toString() ?? '';
    _hideHiringCompany = j['hide_hiring_company'] == true;
    _roleCategoryController.text = j['role_category']?.toString() ?? '';
    _functionalAreaController.text = j['functional_area']?.toString() ?? '';
    _educationController.text = j['education']?.toString() ?? '12th pass or above';

    _assetsRequiredController.text = j['assets_required']?.toString() ?? '';
    _languagesController.text = j['languages']?.toString() ?? 'Speaks thoda english';
    _incentiveDetailController.text = j['incentive_detail']?.toString() ?? '';
    _hasIncentive = _incentiveDetailController.text.trim().isNotEmpty;
    _jobTimingsController.text = j['job_timings']?.toString() ?? '';
    _interviewTimingsController.text = j['interview_timings']?.toString() ?? '';
    _workingDaysController.text = j['working_days']?.toString() ?? '';
    _ageMinController.text = j['age_min']?.toString() ?? '';
    _ageMaxController.text = j['age_max']?.toString() ?? '';
    _genderPreference = j['gender_preference']?.toString() ?? 'any';
    _contactPreference = j['contact_preference']?.toString() ?? 'phone_call';
    _contactPersonController.text = j['contact_person']?.toString() ?? '';
    _contactPhoneController.text = j['contact_phone']?.toString() ?? '';
    _contactEmailController.text = j['contact_email']?.toString() ?? '';
    _departmentController.text = j['department']?.toString() ?? '';
    _roleController.text = j['role']?.toString() ?? '';
    _lastAutoSetRole = j['role']?.toString() ?? '';

    if (_selectedExperience == 'fresher') {
      _experiencePreference = 'fresher';
    } else {
      _experiencePreference = 'experienced';
    }
    _initTimings();
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await _api.getProfile();
      if (mounted) {
        setState(() {
          _isVerified = profile['verification_status'] == 'verified';
          if (_companyAboutController.text.trim().isEmpty) {
            _companyAboutController.text =
                profile['about_company']?.toString() ??
                profile['company_bio']?.toString() ??
                profile['description']?.toString() ??
                '';
          }
          if (_benefitsController.text.trim().isEmpty) {
            _benefitsController.text = profile['benefits']?.toString() ?? '';
          }
          if (_salaryInsightsController.text.trim().isEmpty) {
            _salaryInsightsController.text =
                profile['salary_insights']?.toString() ??
                profile['perks']?.toString() ??
                '';
          }
          if (_consultancyNameController.text.trim().isEmpty) {
            _consultancyNameController.text =
                profile['company_name']?.toString() ?? '';
          }
          if (_contactPhoneController.text.trim().isEmpty) {
            _contactPhoneController.text = profile['phone']?.toString() ?? '';
          }
          if (_contactEmailController.text.trim().isEmpty) {
            _contactEmailController.text = profile['email']?.toString() ?? '';
          }
          if (_contactPersonController.text.trim().isEmpty) {
            _contactPersonController.text = profile['contact_person']?.toString() ?? '';
          }
          if (_companyAddressController.text.trim().isEmpty) {
            _companyAddressController.text = profile['address']?.toString() ?? '';
          }
        });
      }
    } catch (_) {}
  }

  // Visual validation checkmark builder
  Widget _buildFieldCheckmark(bool isValid) {
    return Icon(
      Icons.check_circle_rounded,
      color: isValid ? Colors.green : Colors.grey.shade300,
      size: 20,
    );
  }

  // Navigation validation helper
  bool _validateStep(int step) {
    if (step == 0) {
      if (_titleController.text.trim().isEmpty) return false;
      if (_industryType == null) return false;
      if (_industryType == 'none_of_above' && _customIndustryController.text.trim().isEmpty) return false;
      if (_locationController.text.trim().isEmpty) return false;
      return true;
    } else if (step == 1) {
      if (_descController.text.trim().isEmpty) return false;
      if (_jobTimingsController.text.trim().isEmpty) return false;
      return true;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields marked with *'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _currentStep++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0.0);
                }
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentStep + 1}/3',
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                ),
                Text(
                  'POST JOB',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent_rounded, size: 16),
              label: const Text('Call Customer support', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Styled Step progress bar
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildStepTab(0, 'Job\nDetails'),
                _buildStepTab(1, 'Job\nDescriptions'),
                _buildStepTab(2, 'Company\nDetails'),
              ],
            ),
          ),
          
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepView(textTheme),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStepTab(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0D47A1) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF0D47A1)
                  : isCompleted
                      ? Colors.blue.shade800
                      : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView(TextTheme textTheme) {
    switch (_currentStep) {
      case 0:
        return _buildJobDetailsStep(textTheme);
      case 1:
        return _buildJobDescriptionsStep(textTheme);
      case 2:
        return _buildCompanyDetailsStep(textTheme);
      default:
        return _buildJobDetailsStep(textTheme);
    }
  }

  // --- STEP 1: JOB DETAILS ---
  Widget _buildJobDetailsStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Job Basic Information'),
        const SizedBox(height: 16),
        
        _buildLabel('Job Title *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'e.g. Senior Flutter Developer',
            suffixIcon: _buildFieldCheckmark(_titleController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),
        
        const SizedBox(height: 20),
        
        IndustryTypeDropdown(
          value: _industryType,
          labelText: 'Industry / Job Field *',
          onChanged: (v) {
            setState(() {
              _industryType = v;
              _roleController.clear();
              _addedSkills.clear();
              if (_titleController.text.trim() == _lastAutoSetRole) {
                _titleController.clear();
              }
              _lastAutoSetRole = '';
            });
          },
        ),
        
        if (_industryType == 'none_of_above') ...[
          const SizedBox(height: 16),
          _buildLabel('Write Custom Industry Name *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customIndustryController,
            decoration: InputDecoration(
              hintText: 'e.g. Space Exploration, Robotics',
              suffixIcon: _buildFieldCheckmark(_customIndustryController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        if (_industryType != null && _industryType != 'none_of_above') ...[
          const SizedBox(height: 20),
          _buildRoleSelectionChips(),
        ],



        const SizedBox(height: 24),
        _buildSectionHeader('Job Structure & Location'),
        const SizedBox(height: 16),
        
        _buildLabel('Department'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _departmentController,
          decoration: InputDecoration(
            hintText: 'e.g. Engineering',
            suffixIcon: _buildFieldCheckmark(_departmentController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),



        const SizedBox(height: 20),
        _buildLabel('Job Location *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'e.g. Bangalore, Karnataka',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  onPressed: () async {
                    final loc = await LocationService.instance.getCurrentLocation();
                    if (loc != null) {
                      setState(() => _locationController.text = loc);
                    }
                  },
                ),
                _buildFieldCheckmark(_locationController.text.trim().isNotEmpty),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Job Type'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    value: _selectedJobType,
                    items: const {
                      'full_time': 'Full Time',
                      'part_time': 'Part Time',
                      'contract': 'Contract',
                      'internship': 'Internship',
                      'freelance': 'Freelance',
                    },
                    onChanged: (v) => setState(() => _selectedJobType = v!),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Candidate Minimum Qualification'),
        const SizedBox(height: 16),
        _buildQualificationSelectionChips(),

        const SizedBox(height: 24),
        _buildSectionHeader('Salary Range (₹ / Year)'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _salaryMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Min Salary',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('—', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            Expanded(
              child: TextFormField(
                controller: _salaryMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Max Salary',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- STEP 2: JOB DESCRIPTIONS ---
  Widget _buildJobDescriptionsStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Job Settings'),
        const SizedBox(height: 16),
        
        _buildLabel('Is it a Work From Home Job?'),
        const SizedBox(height: 8),
        _buildYesNoToggle(
          value: _selectedWorkMode == 'home',
          onChanged: (val) {
            setState(() {
              _selectedWorkMode = val ? 'home' : 'office';
            });
          },
        ),

        const SizedBox(height: 20),
        _buildLabel('Is there any security deposit charged to the candidate (Eg. Uniform, Kit, Bike)? *'),
        const SizedBox(height: 8),
        _buildYesNoToggle(
          value: _securityDeposit,
          onChanged: (val) {
            setState(() {
              _securityDeposit = val;
              if (!val) {
                _securityDepositAmountController.clear();
              }
            });
          },
        ),
        if (_securityDeposit) ...[
          const SizedBox(height: 16),
          _buildLabel('Security Deposit Details / Amount *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _securityDepositAmountController,
            decoration: InputDecoration(
              hintText: 'e.g. ₹2000 for Uniform & Bike Kit',
              suffixIcon: _buildFieldCheckmark(_securityDepositAmountController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (_securityDeposit && (value == null || value.trim().isEmpty)) {
                return 'Please enter security deposit details';
              }
              return null;
            },
          ),
        ],

        const SizedBox(height: 24),
        _buildSectionHeader('Job Role Descriptions'),
        const SizedBox(height: 16),

        _buildLabel('Describe The Job Role For The Staff (Please write in points) *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Please write in points / lines (e.g. \n- Coordinate with team\n- Build high-quality APIs\n- Write unit tests)',
            suffixIcon: _buildFieldCheckmark(_descController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Work Timings *'),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedWorkDayRange == 'Custom') {
                    _selectedWorkDayRange = 'Monday to Saturday';
                    _updateWorkTimingText();
                  } else {
                    _selectedWorkDayRange = 'Custom';
                  }
                });
              },
              child: Text(
                _selectedWorkDayRange == 'Custom' ? 'Use automatic timings' : 'Enter manually',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedWorkDayRange != 'Custom') ...[
          DropdownButtonFormField<String>(
            value: _dayRangeOptions.contains(_selectedWorkDayRange) ? _selectedWorkDayRange : 'Monday to Saturday',
            decoration: const InputDecoration(labelText: 'Days'),
            items: _dayRangeOptions.where((d) => d != 'Custom').map((dayRange) {
              return DropdownMenuItem<String>(
                value: dayRange,
                child: Text(dayRange),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedWorkDayRange = val;
                  _updateWorkTimingText();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeOptions.contains(_workStartTime) ? _workStartTime : '09:30 AM',
                  decoration: const InputDecoration(labelText: 'Start Time'),
                  items: _timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _workStartTime = val;
                        _updateWorkTimingText();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeOptions.contains(_workEndTime) ? _workEndTime : '06:30 PM',
                  decoration: const InputDecoration(labelText: 'End Time'),
                  items: _timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _workEndTime = val;
                        _updateWorkTimingText();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          TextFormField(
            controller: _jobTimingsController,
            decoration: InputDecoration(
              hintText: 'e.g. 09:30 am - 6:30pm | Monday to Saturday',
              suffixIcon: _buildFieldCheckmark(_jobTimingsController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Interview Would Be Done Between'),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedInterviewDayRange == 'Custom') {
                    _selectedInterviewDayRange = 'Monday to Saturday';
                    _updateInterviewTimingText();
                  } else {
                    _selectedInterviewDayRange = 'Custom';
                  }
                });
              },
              child: Text(
                _selectedInterviewDayRange == 'Custom' ? 'Use automatic timings' : 'Enter manually',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedInterviewDayRange != 'Custom') ...[
          DropdownButtonFormField<String>(
            value: _dayRangeOptions.contains(_selectedInterviewDayRange) ? _selectedInterviewDayRange : 'Monday to Saturday',
            decoration: const InputDecoration(labelText: 'Days'),
            items: _dayRangeOptions.where((d) => d != 'Custom').map((dayRange) {
              return DropdownMenuItem<String>(
                value: dayRange,
                child: Text(dayRange),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedInterviewDayRange = val;
                  _updateInterviewTimingText();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeOptions.contains(_interviewStartTime) ? _interviewStartTime : '11:00 AM',
                  decoration: const InputDecoration(labelText: 'Start Time'),
                  items: _timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _interviewStartTime = val;
                        _updateInterviewTimingText();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _timeOptions.contains(_interviewEndTime) ? _interviewEndTime : '04:00 PM',
                  decoration: const InputDecoration(labelText: 'End Time'),
                  items: _timeOptions.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _interviewEndTime = val;
                        _updateInterviewTimingText();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          TextFormField(
            controller: _interviewTimingsController,
            decoration: InputDecoration(
              hintText: 'e.g. 11:00 am - 4:00pm | Monday to Saturday',
              suffixIcon: _buildFieldCheckmark(_interviewTimingsController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 20),
        _buildLabel('Is there any Incentive?'),
        const SizedBox(height: 8),
        _buildYesNoToggle(
          value: _hasIncentive,
          onChanged: (val) {
            setState(() {
              _hasIncentive = val;
              if (!val) {
                _incentiveDetailController.clear();
              }
            });
          },
        ),
        if (_hasIncentive) ...[
          const SizedBox(height: 16),
          _buildLabel('Incentive Details *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _incentiveDetailController,
            decoration: InputDecoration(
              hintText: 'e.g. Rs. 12000 as Performance Linked Incentive',
              suffixIcon: _buildFieldCheckmark(_incentiveDetailController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (_hasIncentive && (value == null || value.trim().isEmpty)) {
                return 'Please enter incentive details';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 20),
        _buildLabel('Company Benefits (optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _benefitsController,
          decoration: InputDecoration(
            hintText: 'e.g. Health Insurance, Flexible Hours, PF',
            suffixIcon: _buildFieldCheckmark(_benefitsController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        _buildLabel('Common Benefits (Tap to add)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _commonBenefits.map((benefit) {
            final isAdded = _parsedBenefits.contains(benefit);
            return FilterChip(
              label: Text(benefit),
              selected: isAdded,
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
              onSelected: (_) => _toggleBenefit(benefit),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Requirements & Candidate Criteria'),
        const SizedBox(height: 16),

        _buildLabel('Total Experience of Candidate'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildCustomChip(
              label: 'Any',
              isSelected: _experiencePreference == 'any',
              hasRelevantBadge: true,
              onTap: () => setState(() {
                _experiencePreference = 'any';
                _selectedExperience = 'fresher';
              }),
            ),
            _buildCustomChip(
              label: 'Freshers Only',
              isSelected: _experiencePreference == 'fresher',
              onTap: () => setState(() {
                _experiencePreference = 'fresher';
                _selectedExperience = 'fresher';
              }),
            ),
            _buildCustomChip(
              label: 'Experienced Only',
              isSelected: _experiencePreference == 'experienced',
              onTap: () => setState(() {
                _experiencePreference = 'experienced';
                if (_selectedExperience == 'fresher') {
                  _selectedExperience = 'junior';
                }
              }),
            ),
          ],
        ),
        
        if (_experiencePreference == 'experienced') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Minimum Experience'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedExperience,
                      items: const {
                        'junior': 'Junior (1-2 yrs)',
                        'mid': 'Mid Level (2-5 yrs)',
                        'senior': 'Senior (5-8 yrs)',
                        'lead': 'Lead (8+ yrs)',
                      },
                      onChanged: (v) => setState(() => _selectedExperience = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),
        _buildLabel("Candidate's English Speaking Skill Should Be"),
        const SizedBox(height: 8),
        _buildEnglishSpeakingChips(),

        const SizedBox(height: 24),
        _buildLabel('Skills'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  hintText: 'Type to search for skills',
                ),
                onFieldSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 36),
              onPressed: _addSkill,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildSuggestedSkillsSection(),

        if (_addedSkills.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildLabel('Added Skills:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _addedSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _addedSkills.remove(skill));
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 20),
        _buildLabel('Detailed Candidate Requirements (Please write in points) (optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _requirementsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Please write in points / lines (e.g. \n- 2+ years of experience\n- Strong coding skills\n- Good communication)',
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // --- STEP 3: COMPANY DETAILS ---
  Widget _buildCompanyDetailsStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Posting Recruiter & Company Details'),
        const SizedBox(height: 16),

        _buildLabel('You\'re posting this job as a:'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPostingAsChip('Company/Business', 'company'),
            const SizedBox(width: 12),
            _buildPostingAsChip('Consultancy', 'consultancy'),
          ],
        ),

        if (_postingAs == 'consultancy') ...[
          const SizedBox(height: 20),
          _buildLabel('Your consultancy name *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _consultancyNameController,
            decoration: InputDecoration(
              hintText: 'Consultancy name',
              suffixIcon: _buildFieldCheckmark(_consultancyNameController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          _buildLabel("Company you're hiring for *"),
          const SizedBox(height: 8),
          TextFormField(
            controller: _hiringForCompanyController,
            decoration: InputDecoration(
              hintText: 'Add company',
              suffixIcon: _buildFieldCheckmark(_hiringForCompanyController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _hideHiringCompany,
                onChanged: (v) => setState(() => _hideHiringCompany = v ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  "Don't show hiring company info to candidate",
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 20),
          _buildLabel('Name Of My Company *'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _consultancyNameController,
            decoration: InputDecoration(
              hintText: 'Enter company name',
              suffixIcon: _buildFieldCheckmark(_consultancyNameController.text.trim().isNotEmpty),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 20),
        _buildLabel('Contact Person / Recruiter Name *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactPersonController,
          decoration: InputDecoration(
            hintText: 'e.g. Ram / HR Manager',
            suffixIcon: _buildFieldCheckmark(_contactPersonController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),
        _buildLabel('Email Id *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'xyz@xx.xx',
            suffixIcon: _buildFieldCheckmark(_contactEmailController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 20),
        _buildLabel('HR Phone Number (optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contactPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'HR Phone number',
            suffixIcon: _buildFieldCheckmark(_contactPhoneController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        const Text(
          'Phone number can be changed later',
          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 20),
        _buildLabel('Job Seeker Contact Preference *'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildContactPreferenceChip('Phone Call', 'phone_call', Icons.phone_rounded),
            _buildContactPreferenceChip('WhatsApp', 'whatsapp', Icons.chat_bubble_rounded),
            _buildContactPreferenceChip('Email', 'email', Icons.email_rounded),
          ],
        ),

        const SizedBox(height: 20),
        _buildLabel('My Company Address *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _companyAddressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter company address...',
            suffixIcon: _buildFieldCheckmark(_companyAddressController.text.trim().isNotEmpty),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Asking job seeker for any kind of payment is strictly prohibited',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF795548)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0D47A1)),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildYesNoToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        _buildCustomChip(
          label: 'Yes',
          isSelected: value,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 12),
        _buildCustomChip(
          label: 'No',
          isSelected: !value,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }

  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasRelevantBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade400,
                width: 1,
              ),
            ),
            child: Text(
               label,
               style: TextStyle(
                 color: isSelected ? Colors.white : Colors.grey.shade700,
                 fontSize: 13,
                 fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
               ),
            ),
          ),
        ),
        if (hasRelevantBadge)
          Positioned(
            top: -8,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Text(
                'Relevant',
                style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQualificationSelectionChips() {
    final List<String> options = [
      '<10th pass',
      '10th pass or above',
      '12th pass or above',
      'Graduate / Post Graduate'
    ];
    
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: options.map((q) {
        final isSelected = _educationController.text.trim() == q;
        final hasBadge = q == '12th pass or above';
        return _buildCustomChip(
          label: q,
          isSelected: isSelected,
          hasRelevantBadge: hasBadge,
          onTap: () => setState(() => _educationController.text = q),
        );
      }).toList(),
    );
  }

  Widget _buildEnglishSpeakingChips() {
    final List<String> options = [
      'Does not speak english',
      'Speaks thoda english',
      'Speaks good english',
      'Speaks fluent english'
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: options.map((l) {
        final isSelected = _languagesController.text.trim() == l;
        final hasBadge = l == 'Speaks thoda english';
        return _buildCustomChip(
          label: l,
          isSelected: isSelected,
          hasRelevantBadge: hasBadge,
          onTap: () => setState(() => _languagesController.text = l),
        );
      }).toList(),
    );
  }

  Widget _buildContactPreferenceChip(String label, String value, IconData icon) {
    final isSelected = _contactPreference == value;
    return GestureDetector(
      onTap: () => setState(() => _contactPreference = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostingAsChip(String label, String value) {
    final isSelected = _postingAs == value;
    return GestureDetector(
      onTap: () => setState(() => _postingAs = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLastStep = _currentStep == 2;
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D47A1), size: 24),
                onPressed: () {
                  setState(() => _currentStep--);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0.0);
                    }
                  });
                },
              )
            else
              const SizedBox(width: 48),
              
            if (!isLastStep)
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF0D47A1),
                  minimumSize: const Size(0, 0),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEdit ? 'Save changes' : 'Submit to Create a Job Post',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionChips() {
    final roles = kAllRolesAndSkillsByIndustry[_industryType] ?? {};
    if (roles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Select a Job Role / Designation *'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...roles.keys.map((role) {
              final isSelected = _roleController.text.trim() == role;
              return ChoiceChip(
                label: Text(role),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _roleController.text = role;
                      if (_titleController.text.trim().isEmpty || _titleController.text.trim() == _lastAutoSetRole) {
                        _titleController.text = role;
                        _lastAutoSetRole = role;
                      }
                    } else {
                      _roleController.clear();
                      if (_titleController.text.trim() == _lastAutoSetRole) {
                        _titleController.clear();
                        _lastAutoSetRole = '';
                      }
                    }
                  });
                },
              );
            }),
            ChoiceChip(
              label: const Text('Other / Custom'),
              selected: _roleController.text.isNotEmpty && !roles.containsKey(_roleController.text),
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _roleController.clear();
                    if (_titleController.text.trim() == _lastAutoSetRole) {
                      _titleController.clear();
                      _lastAutoSetRole = '';
                    }
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestedSkillsSection() {
    final industryRoles = kAllRolesAndSkillsByIndustry[_industryType] ?? {};
    final selectedRoleName = _roleController.text.trim();
    
    // Fetch recommended skills, fallback to standard suggested list if empty
    List<String> recommendedSkills = industryRoles[selectedRoleName] ?? [];
    if (recommendedSkills.isEmpty) {
      recommendedSkills = ['SEO', 'SQL', 'Python', 'Java', 'Web', 'BackEnd', 'Javascript', 'PHP', 'HTML', 'MySQL', 'CSS', 'Django', 'Node.Js'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Suggested Skills (Tap to add)'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recommendedSkills.map((skill) {
            final isAdded = _addedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isAdded,
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primary,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_addedSkills.contains(skill)) {
                      _addedSkills.add(skill);
                    }
                  } else {
                    _addedSkills.remove(skill);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addSkill() {
    final t = _skillsController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      if (!_addedSkills.contains(t)) _addedSkills.add(t);
      _skillsController.clear();
    });
  }

  int? _parseSalary(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  Future<bool> _ensureCanCreateJob() async {
    if (_isEdit) return true;

    try {
      final profile = await _api.getProfile();
      final vStatus = profile['verification_status']?.toString();
      if (vStatus == null ||
          vStatus.trim().isEmpty ||
          vStatus.trim() != CompanyVerificationValue.verified) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Without company approval, you can’t post jobs.'),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }

      final jobsRes = await _api.listJobPosts(perPage: 5);
      final items = (jobsRes['items'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final hasAnyJob = items.isNotEmpty;
      if (!hasAnyJob) return true;

      final subApi = CompanySubscriptionApiService.instance;
      final offer = await subApi.getOffer();
      final verified = offer['verified'] == true;
      if (!verified) {
        if (!mounted) return false;
        final message = offer['message']?.toString().trim().isNotEmpty == true
            ? offer['message'].toString()
            : 'Subscription verification required.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }

      final first = offer['first_month'];
      final firstMap = first is Map ? first as Map : <dynamic, dynamic>{};
      final alreadyPurchased = firstMap['already_purchased'] == true;
      if (alreadyPurchased) return true;

      final eligibleFree = firstMap['is_free_eligible'] == true;
      final suggestedCode = firstMap['suggested_coupon_code']?.toString();

      final proceedData = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (ctx) {
          final couponController = TextEditingController(text: suggestedCode ?? '');
          return StatefulBuilder(
            builder: (ctx, setStateDialog) => AlertDialog(
              title: const Text('Job posting requires activation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eligibleFree && (suggestedCode?.isNotEmpty == true)
                        ? 'Activate your first month (coupon available) to post jobs.'
                        : 'Pay ₹399 to post jobs.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: couponController,
                    decoration: const InputDecoration(
                      labelText: 'Coupon code (optional)',
                      hintText: 'Enter coupon code',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop<Map<String, dynamic>>(
                    ctx,
                    {
                      'coupon': couponController.text.trim(),
                    },
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        },
      );
      if (proceedData == null || !mounted) return false;

      final manualCoupon = (proceedData['coupon'] as String?)?.trim();
      final couponToUse = (manualCoupon != null && manualCoupon.isNotEmpty) ? manualCoupon : suggestedCode;

      if (eligibleFree && (couponToUse?.isNotEmpty == true)) {
        await subApi.purchase(couponCode: couponToUse);
      } else {
        await subApi.purchase(
          couponCode: (couponToUse != null && couponToUse.isNotEmpty) ? couponToUse : null,
        );
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start activation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  Future<void> _submit() async {
    // Validate final form
    if (!_formKey.currentState!.validate() || 
        _consultancyNameController.text.trim().isEmpty || 
        _contactPersonController.text.trim().isEmpty ||
        _contactEmailController.text.trim().isEmpty || 
        _companyAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please make sure all required fields in Step 3 are filled.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final allowed = await _ensureCanCreateJob();
    if (!allowed) return;

    final maxRaw = _maxApplicationsController.text.trim();
    int? maxApplicants;
    if (maxRaw.isNotEmpty) {
      maxApplicants = int.tryParse(maxRaw);
      if (maxApplicants == null || maxApplicants < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Max applicants must be a positive number or left empty.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        'employment_type': _employmentTypeApi(_selectedJobType),
        'experience_level': _experienceApi(_selectedExperience),
        'industry_type': _industryType == 'none_of_above' ? _customIndustryController.text.trim() : _industryType,
        'role_category': _roleCategoryController.text.trim().isEmpty ? null : _roleCategoryController.text.trim(),
        'functional_area': _functionalAreaController.text.trim().isEmpty ? null : _functionalAreaController.text.trim(),
        'education': _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
        'mode_of_work': _workModeApi(_selectedWorkMode),
        'currency': 'INR',
        'requirements': _requirementsController.text.trim().isEmpty ? null : _requirementsController.text.trim(),
        'salary_min': _parseSalary(_salaryMinController.text),
        'salary_max': _parseSalary(_salaryMaxController.text),
        'benefits': _benefitsController.text.trim().isEmpty ? null : _benefitsController.text.trim(),
        'salary_insights': _salaryInsightsController.text.trim().isEmpty ? null : _salaryInsightsController.text.trim(),
        'about_company': _companyAboutController.text.trim().isEmpty ? null : _companyAboutController.text.trim(),
        'skills': _addedSkills.isEmpty ? null : List<String>.from(_addedSkills),
        'is_consultancy': _postingAs == 'consultancy',
        'consultancy_name': _consultancyNameController.text.trim(),
        'hiring_for_company': _postingAs == 'consultancy' ? _hiringForCompanyController.text.trim() : null,
        'hide_hiring_company': _postingAs == 'consultancy' ? _hideHiringCompany : false,
        'assets_required': _assetsRequiredController.text.trim().isEmpty ? null : _assetsRequiredController.text.trim(),
        'languages': _languagesController.text.trim().isEmpty ? null : _languagesController.text.trim(),
        'incentive_detail': _incentiveDetailController.text.trim().isEmpty ? null : _incentiveDetailController.text.trim(),
        'job_timings': _jobTimingsController.text.trim().isEmpty ? null : _jobTimingsController.text.trim(),
        'working_days': _workingDaysController.text.trim().isEmpty ? null : _workingDaysController.text.trim(),
        'age_min': int.tryParse(_ageMinController.text.trim()),
        'age_max': int.tryParse(_ageMaxController.text.trim()),
        'gender_preference': _genderPreference,
        'contact_preference': _contactPreference,
        'contact_person': _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        'contact_phone': _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
        'contact_email': _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'role': _roleController.text.trim().isEmpty ? _titleController.text.trim() : _roleController.text.trim(),
        'security_deposit': _securityDeposit,
        'security_deposit_amount': _securityDeposit ? (_securityDepositAmountController.text.trim().isEmpty ? null : _securityDepositAmountController.text.trim()) : null,
        'interview_timings': _interviewTimingsController.text.trim().isEmpty ? null : _interviewTimingsController.text.trim(),
      };

      if (_isEdit) {
        body['application_deadline_at'] = _deadline?.toUtc().toIso8601String();
        body['max_applications'] = maxApplicants;
        body.removeWhere((k, v) => v == null && k != 'application_deadline_at' && k != 'max_applications');
      } else {
        if (_deadline != null) {
          body['application_deadline_at'] = _deadline!.toUtc().toIso8601String();
        }
        if (maxApplicants != null) {
          body['max_applications'] = maxApplicants;
        }
        body.removeWhere((k, v) => v == null);
      }

      final id = _editJobId;
      Map<String, dynamic> result;
      if (id != null) {
        result = await _api.updateJobPost(id, body);
      } else {
        result = await _api.createJobPost(body);
      }
      if (!mounted) return;

      final status = result['status']?.toString() ?? '';
      final msg = id != null
          ? 'Job updated.'
          : (status == 'published'
              ? 'Job published.'
              : 'Job submitted. It may appear as pending until approved.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Could not update job: $e' : 'Could not post job: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _benefitsController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _skillsController.dispose();
    _companyAboutController.dispose();
    _maxApplicationsController.dispose();
    _consultancyNameController.dispose();
    _hiringForCompanyController.dispose();
    _companyAddressController.dispose();
    _roleCategoryController.dispose();
    _functionalAreaController.dispose();
    _educationController.dispose();
    _assetsRequiredController.dispose();
    _languagesController.dispose();
    _incentiveDetailController.dispose();
    _jobTimingsController.dispose();
    _interviewTimingsController.dispose();
    _workingDaysController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _departmentController.dispose();
    _roleController.dispose();
    _customIndustryController.dispose();
    _scrollController.dispose();
    _securityDepositAmountController.dispose();
    super.dispose();
  }
}
