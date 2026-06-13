import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/company_api_service.dart';
import '../../services/company_subscription_api_service.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';
import '../../constants/employer_status_labels.dart';
import '../../widgets/industry_type_dropdown.dart';

/// Maps UI dropdown values to API strings (Laravel accepts any string ≤64 chars).
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

  /// When set, saves with PUT instead of POST (edit existing job).
  final Map<String, dynamic>? existingJob;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
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
  final _educationController = TextEditingController();

  String _postingAs = 'company'; // 'company' or 'consultancy'
  final _consultancyNameController = TextEditingController();
  final _hiringForCompanyController = TextEditingController();
  bool _hideHiringCompany = false;

  String _selectedJobType = 'full_time';
  String _selectedExperience = 'mid';
  String _selectedWorkMode = 'office';
  String? _industryType;

  final List<String> _addedSkills = [];
  bool _submitting = false;
  bool _isVerified = false;
  final _companyAboutController = TextEditingController();

  /// Local date/time for application deadline (optional).
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

  bool get _isEdit => _editJobId != null;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    final j = widget.existingJob;
    if (j == null) return;
    _titleController.text = j['title']?.toString() ?? '';
    _descController.text = j['description']?.toString() ?? '';
    _requirementsController.text = j['requirements']?.toString() ?? '';
    _locationController.text = j['location']?.toString() ?? '';
    final sm = j['salary_min'];
    final sx = j['salary_max'];
    if (sm != null) _salaryMinController.text = sm.toString();
    if (sx != null) _salaryMaxController.text = sx.toString();
    _selectedJobType = _employmentFromApi(j['employment_type']?.toString());
    _selectedExperience = _experienceFromApi(j['experience_level']?.toString());
    final rawWorkMode =
        j['mode_of_work']?.toString() ?? j['work_mode']?.toString();
    final wm = rawWorkMode?.trim().toLowerCase();
    if (wm == null || wm.isEmpty) {
      _selectedWorkMode = 'office';
    } else if (wm == 'both') {
      _selectedWorkMode = 'hybrid';
    } else if (wm == 'office' || wm == 'home' || wm == 'hybrid') {
      _selectedWorkMode = wm;
    } else {
      _selectedWorkMode = 'office';
    }
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
    _industryType = (itk != null && itk.isNotEmpty) ? itk : null;
    _benefitsController.text = j['benefits']?.toString() ?? '';
    _salaryInsightsController.text = j['salary_insights']?.toString() ?? '';
    _companyAboutController.text = j['about_company']?.toString() ?? '';

    _postingAs = j['is_consultancy'] == true ? 'consultancy' : 'company';
    _consultancyNameController.text = j['consultancy_name']?.toString() ?? '';
    _hiringForCompanyController.text = j['hiring_for_company']?.toString() ?? '';
    _hideHiringCompany = j['hide_hiring_company'] == true;
    _roleCategoryController.text = j['role_category']?.toString() ?? '';
    _functionalAreaController.text = j['functional_area']?.toString() ?? '';
    _educationController.text = j['education']?.toString() ?? '';
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
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Job' : 'Post a New Job',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unverified companies may need admin approval before the job is published.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              _buildLabel("You're posting this job as a:"),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildPostingAsChip('Company/Business', 'company'),
                  const SizedBox(width: 12),
                  _buildPostingAsChip('Consultancy', 'consultancy'),
                ],
              ),

              if (_postingAs == 'consultancy') ...[
                const SizedBox(height: 24),
                _buildLabel('Your consultancy name'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _consultancyNameController,
                  decoration: const InputDecoration(
                    hintText: 'Consultancy name',
                  ),
                  validator: (v) => _postingAs == 'consultancy' &&
                          (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 24),
                _buildLabel("Company you're hiring for"),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _hiringForCompanyController,
                  decoration: const InputDecoration(
                    hintText: 'Add company',
                  ),
                  validator: (v) => _postingAs == 'consultancy' &&
                          (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _hideHiringCompany,
                        onChanged: (v) =>
                            setState(() => _hideHiringCompany = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Don't show this information to candidate",
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              _buildLabel('Job Title *'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Senior Flutter Developer',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              IndustryTypeDropdown(
                value: _industryType,
                labelText: 'Industry / job field this role belongs to',
                onChanged: (v) => setState(() => _industryType = v),
              ),

              const SizedBox(height: 24),

              _buildLabel('Role category'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _roleCategoryController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Software Development',
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Functional area'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _functionalAreaController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Engineering - Software & QA',
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Education required'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. B.Tech/B.E. in Computer Science',
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Location'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bangalore, Karnataka',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location_rounded,
                        color: AppColors.primary),
                    onPressed: () async {
                      final loc =
                          await LocationService.instance.getCurrentLocation();
                      if (loc != null) {
                        setState(() => _locationController.text = loc);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Job Type'),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          value: _selectedJobType,
                          items: const {
                            'full_time': 'Full Time',
                            'part_time': 'Part Time',
                            'contract': 'Contract',
                            'internship': 'Internship',
                            'freelance': 'Freelance',
                          },
                          onChanged: (v) =>
                              setState(() => _selectedJobType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Experience'),
                        const SizedBox(height: 10),
                        _buildDropdown(
                          value: _selectedExperience,
                          items: const {
                            'fresher': 'Fresher',
                            'junior': 'Junior',
                            'mid': 'Mid Level',
                            'senior': 'Senior',
                            'lead': 'Lead',
                          },
                          onChanged: (v) =>
                              setState(() => _selectedExperience = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildLabel('Mode of work'),
              const SizedBox(height: 10),
              _buildDropdown(
                value: _selectedWorkMode,
                items: const {
                  'office': 'Work from office',
                  'home': 'Work from home',
                  'hybrid': 'Both (hybrid)',
                },
                onChanged: (v) => setState(() => _selectedWorkMode = v!),
              ),

              const SizedBox(height: 24),

              _buildLabel('Salary range (₹ / year)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Min',
                        prefixIcon: Icon(Icons.currency_rupee_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 18)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Max',
                        prefixIcon: Icon(Icons.currency_rupee_rounded,
                            color: AppColors.primary, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildLabel('Application deadline (optional)'),
              const SizedBox(height: 6),
              Text(
                'After this date/time, the job closes automatically for new applicants.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _deadline == null
                                    ? 'Tap to choose date & time'
                                    : DateFormat('MMM d, y • HH:mm')
                                        .format(_deadline!),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _deadline == null
                                      ? AppColors.textHint
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_deadline != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _deadline = null),
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textHint),
                      tooltip: 'Clear deadline',
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              _buildLabel('Max applicants (optional)'),
              const SizedBox(height: 6),
              Text(
                'When this many people have applied, the posting closes automatically. Leave empty for no limit.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _maxApplicationsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 50',
                  prefixIcon: Icon(Icons.groups_outlined,
                      color: AppColors.primary, size: 20),
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Required skills'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        hintText: 'Add a skill',
                      ),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addSkill,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (_addedSkills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _addedSkills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() => _addedSkills.remove(skill));
                            },
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              _buildLabel('Job description *'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Describe the role, responsibilities, and what makes this job exciting...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),

              _buildLabel('Requirements'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _requirementsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Qualifications, experience, and skills required...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Company Benefits'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Health insurance, free snacks, remote options...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.card_giftcard_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Salary Insights & Perks'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _salaryInsightsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Performance bonus, stock options, travel allowance...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.insights_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('About Company'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _companyAboutController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your company culture, mission, and focus...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.business_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save changes' : 'Post Job',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 14));
    final safeInitial = initial.isBefore(now) ? now : initial;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(
        safeInitial.year,
        safeInitial.month,
        safeInitial.day,
      ),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
            content: Text(
              'Without company approval, you can’t post jobs.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }

      final jobsRes = await _api.listJobPosts(perPage: 5);
      final items = (jobsRes['items'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final hasAnyJob = items.isNotEmpty;
      if (!hasAnyJob) return true; // first job is free

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
          final couponController = TextEditingController(
            text: suggestedCode ?? '',
          );
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
      final couponToUse = (manualCoupon != null && manualCoupon.isNotEmpty)
          ? manualCoupon
          : suggestedCode;

      if (eligibleFree && (couponToUse?.isNotEmpty == true)) {
        await subApi.purchase(couponCode: couponToUse);
      } else {
        await subApi.purchase(
          couponCode:
              (couponToUse != null && couponToUse.isNotEmpty) ? couponToUse : null,
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
        'location': _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        'employment_type': _employmentTypeApi(_selectedJobType),
        'experience_level': _experienceApi(_selectedExperience),
        'industry_type': _industryType,
        'role_category': _roleCategoryController.text.trim().isEmpty
            ? null
            : _roleCategoryController.text.trim(),
        'functional_area': _functionalAreaController.text.trim().isEmpty
            ? null
            : _functionalAreaController.text.trim(),
        'education': _educationController.text.trim().isEmpty
            ? null
            : _educationController.text.trim(),
        'mode_of_work': _workModeApi(_selectedWorkMode),
        'currency': 'INR',
        'requirements': _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
        'salary_min': _parseSalary(_salaryMinController.text),
        'salary_max': _parseSalary(_salaryMaxController.text),
        'benefits': _benefitsController.text.trim().isEmpty
            ? null
            : _benefitsController.text.trim(),
        'salary_insights': _salaryInsightsController.text.trim().isEmpty
            ? null
            : _salaryInsightsController.text.trim(),
        'about_company': _companyAboutController.text.trim().isEmpty
            ? null
            : _companyAboutController.text.trim(),
        'skills': _addedSkills.isEmpty ? null : List<String>.from(_addedSkills),
        'is_consultancy': _postingAs == 'consultancy',
        'consultancy_name': _postingAs == 'consultancy'
            ? _consultancyNameController.text.trim()
            : null,
        'hiring_for_company': _postingAs == 'consultancy'
            ? _hiringForCompanyController.text.trim()
            : null,
        'hide_hiring_company':
            _postingAs == 'consultancy' ? _hideHiringCompany : false,
      };

      if (_isEdit) {
        body['application_deadline_at'] =
            _deadline?.toUtc().toIso8601String();
        body['max_applications'] = maxApplicants;
        body.removeWhere(
          (k, v) =>
              v == null &&
              k != 'application_deadline_at' &&
              k != 'max_applications',
        );
      } else {
        if (_deadline != null) {
          body['application_deadline_at'] =
              _deadline!.toUtc().toIso8601String();
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
          content: Text(
              _isEdit ? 'Could not update job: $e' : 'Could not post job: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint),
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

  @override
  void dispose() {
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
    _roleCategoryController.dispose();
    _functionalAreaController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Widget _buildPostingAsChip(String label, String value) {
    final isSelected = _postingAs == value;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => setState(() => _postingAs = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
