import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/company_api_service.dart';
import '../../utils/app_colors.dart';
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

  String _selectedJobType = 'full_time';
  String _selectedExperience = 'mid';
  String? _industryType;

  final List<String> _addedSkills = [];
  bool _submitting = false;

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unverified companies may need admin approval before the job is published.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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

              _buildLabel('Location'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Bangalore, Karnataka',
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
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
                        color: AppColors.accentLight,
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
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() => _addedSkills.remove(skill));
                            },
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.accent),
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

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
        'currency': 'INR',
        'requirements': _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
        'salary_min': _parseSalary(_salaryMinController.text),
        'salary_max': _parseSalary(_salaryMaxController.text),
        'skills': _addedSkills.isEmpty ? null : List<String>.from(_addedSkills),
      };

      if (_isEdit) {
        body['application_deadline_at'] =
            _deadline != null ? _deadline!.toUtc().toIso8601String() : null;
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
    _maxApplicationsController.dispose();
    super.dispose();
  }
}
