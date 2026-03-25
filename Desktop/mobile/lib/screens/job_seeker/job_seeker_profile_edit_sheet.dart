import 'package:flutter/material.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/industry_type_dropdown.dart';

class _EduRow {
  _EduRow({
    String title = '',
    String institution = '',
    String board = '',
    String marks = '',
    String year = '',
  })  : title = TextEditingController(text: title),
        institution = TextEditingController(text: institution),
        boardOrStream = TextEditingController(text: board),
        marksOrGrade = TextEditingController(text: marks),
        yearCompleted = TextEditingController(text: year);

  final TextEditingController title;
  final TextEditingController institution;
  final TextEditingController boardOrStream;
  final TextEditingController marksOrGrade;
  final TextEditingController yearCompleted;

  void dispose() {
    title.dispose();
    institution.dispose();
    boardOrStream.dispose();
    marksOrGrade.dispose();
    yearCompleted.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title.text.trim(),
      'institution': institution.text.trim(),
      'board_or_stream': boardOrStream.text.trim(),
      'marks_or_grade': marksOrGrade.text.trim(),
      'year_completed': yearCompleted.text.trim(),
    };
  }
}

/// Scrollable edit form for job seeker profile (education + industry type).
class JobSeekerProfileEditSheet extends StatefulWidget {
  const JobSeekerProfileEditSheet({
    super.key,
    required this.initial,
    required this.onSaved,
  });

  final Map<String, dynamic> initial;
  final VoidCallback onSaved;

  @override
  State<JobSeekerProfileEditSheet> createState() =>
      _JobSeekerProfileEditSheetState();
}

class _JobSeekerProfileEditSheetState extends State<JobSeekerProfileEditSheet> {
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _minSalCtrl;
  late final TextEditingController _maxSalCtrl;
  late final TextEditingController _skillsCtrl;

  String? _industryType;
  final List<_EduRow> _education = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _headlineCtrl = TextEditingController(text: p['headline']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: p['bio']?.toString() ?? '');
    _cityCtrl = TextEditingController(text: p['city']?.toString() ?? '');
    _countryCtrl = TextEditingController(text: p['country']?.toString() ?? '');
    _expCtrl = TextEditingController(text: p['experience_years']?.toString() ?? '');
    _minSalCtrl = TextEditingController(text: p['expected_salary_min']?.toString() ?? '');
    _maxSalCtrl = TextEditingController(text: p['expected_salary_max']?.toString() ?? '');
    _skillsCtrl = TextEditingController(
      text: p['skills'] is List
          ? (p['skills'] as List).map((e) => e.toString()).join(', ')
          : '',
    );
    _industryType = p['industry_type']?.toString();
    if (_industryType != null && _industryType!.isEmpty) {
      _industryType = null;
    }

    final edu = p['education'];
    if (edu is List) {
      for (final e in edu) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          _education.add(
            _EduRow(
              title: m['title']?.toString() ?? '',
              institution: m['institution']?.toString() ?? '',
              board: m['board_or_stream']?.toString() ?? '',
              marks: m['marks_or_grade']?.toString() ?? '',
              year: m['year_completed']?.toString() ?? '',
            ),
          );
        }
      }
    }
    if (_education.isEmpty) {
      _education.add(_EduRow());
    }
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _expCtrl.dispose();
    _minSalCtrl.dispose();
    _maxSalCtrl.dispose();
    _skillsCtrl.dispose();
    for (final r in _education) {
      r.dispose();
    }
    super.dispose();
  }

  void _addEducation() {
    setState(() => _education.add(_EduRow()));
  }

  void _removeEducation(int i) {
    if (_education.length <= 1) return;
    setState(() {
      final r = _education.removeAt(i);
      r.dispose();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final eduPayload = _education
          .map((r) => r.toJson())
          .where((m) => m.values.any((v) => v.toString().trim().isNotEmpty))
          .toList();

      final body = <String, dynamic>{
        'headline':
            _headlineCtrl.text.trim().isEmpty ? null : _headlineCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'country':
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        'experience_years': _expCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_expCtrl.text.trim()),
        'expected_salary_min': _minSalCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_minSalCtrl.text.trim()),
        'expected_salary_max': _maxSalCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_maxSalCtrl.text.trim()),
        'currency': 'INR',
        'skills': skills.isEmpty ? null : skills,
        'industry_type': _industryType,
        'education': eduPayload.isEmpty ? null : eduPayload,
      };
      body.removeWhere((k, v) => v == null);

      await JobSeekerApiService.instance.updateSeekerProfile(body);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: maxH,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    'Edit profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IndustryTypeDropdown(
                    value: _industryType,
                    labelText: 'Industry / role type',
                    onChanged: (v) => setState(() => _industryType = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _headlineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Headline',
                      hintText: 'e.g. Senior Flutter Developer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Education',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  Text(
                    'Add Class 10, 12, diploma, degree — title, school/college, board, marks, year.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_education.length, (i) {
                    final r = _education[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Entry ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                if (_education.length > 1)
                                  IconButton(
                                    onPressed: () => _removeEducation(i),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.title,
                              decoration: const InputDecoration(
                                labelText: 'Title (e.g. Class 12, B.Tech)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.institution,
                              decoration: const InputDecoration(
                                labelText: 'School / college name',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: r.boardOrStream,
                              decoration: const InputDecoration(
                                labelText: 'Board / stream (optional)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: r.marksOrGrade,
                                    decoration: const InputDecoration(
                                      labelText: 'Marks / CGPA',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: r.yearCompleted,
                                    decoration: const InputDecoration(
                                      labelText: 'Year',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _countryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years of experience',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minSalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected salary min (₹/yr)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxSalCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Expected salary max (₹/yr)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _skillsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
