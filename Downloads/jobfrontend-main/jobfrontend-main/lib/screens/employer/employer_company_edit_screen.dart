import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/app_session.dart';
import '../../services/company_api_service.dart';
import '../../utils/app_colors.dart';
import '../../services/location_service.dart';
import '../../widgets/industry_type_dropdown.dart';

/// Full editor for company profile (location, bio, team, etc.).
class EmployerCompanyEditScreen extends StatefulWidget {
  const EmployerCompanyEditScreen({super.key, required this.initial});

  final Map<String, dynamic> initial;

  @override
  State<EmployerCompanyEditScreen> createState() =>
      _EmployerCompanyEditScreenState();
}

class _TeamRow {
  _TeamRow({String name = '', String role = '', String email = ''}) {
    nameCtrl = TextEditingController(text: name);
    roleCtrl = TextEditingController(text: role);
    emailCtrl = TextEditingController(text: email);
  }

  late final TextEditingController nameCtrl;
  late final TextEditingController roleCtrl;
  late final TextEditingController emailCtrl;

  void dispose() {
    nameCtrl.dispose();
    roleCtrl.dispose();
    emailCtrl.dispose();
  }
}

class _EmployerCompanyEditScreenState extends State<EmployerCompanyEditScreen> {
  final _api = CompanyApiService.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _establishedYearCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _whatWeDoCtrl;
  late final TextEditingController _benefitsCtrl;
  late final TextEditingController _salaryInsightsCtrl;
  late final TextEditingController _hiringForCtrl;

  bool _isConsultancy = false;

  final List<_TeamRow> _team = [];
  bool _saving = false;
  String? _industryTypeKey;
  bool _hideHiringCompany = false;

  static const int _maxLogoBytes = 2 * 1024 * 1024; // ~2MB
  final ImagePicker _imagePicker = ImagePicker();
  String? _companyLogoUrl;
  XFile? _pickedCompanyLogo;
  String? _companyLogoBase64;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    final itk = c['industry_type']?.toString();
    _industryTypeKey = (itk != null && itk.isNotEmpty) ? itk : null;
    _nameCtrl = TextEditingController(text: c['name']?.toString() ?? '');
    _industryCtrl = TextEditingController(text: c['industry']?.toString() ?? '');
    _websiteCtrl = TextEditingController(text: c['website']?.toString() ?? '');
    _gstCtrl = TextEditingController(text: c['gst_number']?.toString() ?? '');
    _locationCtrl = TextEditingController(text: c['location']?.toString() ?? '');
    final ey = c['established_year'];
    _establishedYearCtrl = TextEditingController(
      text: ey == null ? '' : ey.toString(),
    );
    _descCtrl = TextEditingController(text: c['description']?.toString() ?? '');
    _bioCtrl = TextEditingController(text: c['about_company']?.toString() ?? c['company_bio']?.toString() ?? '');
    _whatWeDoCtrl = TextEditingController(text: c['what_we_do']?.toString() ?? '');
    _benefitsCtrl = TextEditingController(text: c['benefits']?.toString() ?? '');
    _salaryInsightsCtrl = TextEditingController(text: c['salary_insights']?.toString() ?? '');
    _hiringForCtrl = TextEditingController(text: c['hiring_for_company']?.toString() ?? '');
    _isConsultancy = c['is_consultancy'] == true;
    _hideHiringCompany = c['hide_hiring_company'] == true || c['hide_hiring_company'] == 1;

    final rawLogo = c['company_logo_url']?.toString() ??
        c['company_logo']?.toString();
    final trimmed = rawLogo?.trim() ?? '';
    _companyLogoUrl = trimmed.isNotEmpty ? trimmed : null;

    final rawTeam = c['team_members'];
    if (rawTeam is List && rawTeam.isNotEmpty) {
      for (final m in rawTeam) {
        if (m is Map) {
          final mm = Map<String, dynamic>.from(m);
          _team.add(_TeamRow(
            name: mm['name']?.toString() ?? '',
            role: mm['role']?.toString() ?? '',
            email: mm['email']?.toString() ?? '',
          ));
        }
      }
    }
    if (_team.isEmpty) {
      _team.add(_TeamRow());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _websiteCtrl.dispose();
    _gstCtrl.dispose();
    _locationCtrl.dispose();
    _establishedYearCtrl.dispose();
    _descCtrl.dispose();
    _bioCtrl.dispose();
    _whatWeDoCtrl.dispose();
    _benefitsCtrl.dispose();
    _salaryInsightsCtrl.dispose();
    _hiringForCtrl.dispose();
    for (final t in _team) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCompanyLogo() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > _maxLogoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logo too large (max ~2MB). Please select a smaller one.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _pickedCompanyLogo = picked;
        _companyLogoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildCompanyLogoCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoSize =
            (constraints.maxWidth * 0.26).clamp(76.0, 128.0).toDouble();

        ImageProvider? provider;
        if (_pickedCompanyLogo != null) {
          provider = FileImage(File(_pickedCompanyLogo!.path));
        } else if (_companyLogoUrl != null &&
            _companyLogoUrl!.isNotEmpty &&
            (_companyLogoUrl!.startsWith('http://') ||
                _companyLogoUrl!.startsWith('https://'))) {
          provider = NetworkImage(_companyLogoUrl!);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: provider != null
                      ? Image(image: provider, fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            Icons.business_rounded,
                            size: logoSize * 0.45,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Company logo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add your logo for a more professional company profile.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _pickCompanyLogo,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _pickedCompanyLogo != null
                            ? 'Replace'
                            : (provider != null ? 'Replace' : 'Upload'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      var web = _websiteCtrl.text.trim();
      if (web.isNotEmpty && !web.startsWith('http')) {
        web = 'https://$web';
      }
      final yearRaw = _establishedYearCtrl.text.trim();
      int? establishedYear;
      if (yearRaw.isNotEmpty) {
        establishedYear = int.tryParse(yearRaw);
      }

      final teamPayload = <Map<String, dynamic>>[];
      for (final t in _team) {
        final n = t.nameCtrl.text.trim();
        if (n.isEmpty) continue;
        teamPayload.add({
          'name': n,
          'role': t.roleCtrl.text.trim().isEmpty ? null : t.roleCtrl.text.trim(),
          'email': t.emailCtrl.text.trim().isEmpty ? null : t.emailCtrl.text.trim(),
        });
      }

      final updated = await _api.updateProfile({
        'name': _nameCtrl.text.trim(),
        'industry': _industryCtrl.text.trim().isEmpty ? null : _industryCtrl.text.trim(),
        'industry_type': _industryTypeKey,
        'website': web.isEmpty ? null : web,
        'gst_number': _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'established_year': establishedYear,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'about_company': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'benefits': _benefitsCtrl.text.trim().isEmpty ? null : _benefitsCtrl.text.trim(),
        'salary_insights': _salaryInsightsCtrl.text.trim().isEmpty ? null : _salaryInsightsCtrl.text.trim(),
        'what_we_do': _whatWeDoCtrl.text.trim().isEmpty ? null : _whatWeDoCtrl.text.trim(),
        'is_consultancy': _isConsultancy,
        'hiring_for_company': _isConsultancy ? _hiringForCtrl.text.trim() : null,
        'hide_hiring_company': _isConsultancy && _hideHiringCompany ? 1 : 0,
        if (_companyLogoBase64 != null) 'company_logo': _companyLogoBase64,
        'team_members': teamPayload.isEmpty ? [] : teamPayload,
      });

      final newLogo = updated['company_logo_url']?.toString() ??
          updated['company_logo']?.toString();
      if (newLogo != null && newLogo.trim().isNotEmpty) {
        AppSession.companyLogoNotifier.value = newLogo.trim();
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addTeamMember() {
    setState(() => _team.add(_TeamRow()));
  }

  void _removeTeamMember(int i) {
    if (_team.length <= 1) return;
    setState(() {
      _team[i].dispose();
      _team.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit company profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            'Tell candidates about your company. Complete profiles get more trust.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildCompanyLogoCard(),
          const SizedBox(height: 20),
          _field('Company name *', _nameCtrl),
          Row(
            children: [
              Text("I am a Consultancy", style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: _isConsultancy,
                onChanged: (v) => setState(() => _isConsultancy = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_isConsultancy) ...[
            _field('Company you are hiring for', _hiringForCtrl,
                hint: 'e.g. Client Name'),
            Row(
              children: [
                Checkbox(
                  value: _hideHiringCompany,
                  onChanged: (v) =>
                      setState(() => _hideHiringCompany = v ?? false),
                  activeColor: AppColors.primary,
                ),
                Text(
                  "Don't show this information to candidate",
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: IndustryTypeDropdown(
              value: _industryTypeKey,
              labelText: 'Industry / sector (standard list)',
              onChanged: (v) => setState(() => _industryTypeKey = v),
            ),
          ),
          _field('Industry notes (optional)', _industryCtrl,
              hint: 'Extra detail beyond the list above'),
          _field('Website URL', _websiteCtrl, keyboard: TextInputType.url),
          _field('GST number', _gstCtrl),
          _field(
            'Head office / location',
            _locationCtrl,
            hint: 'City, state or full address',
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              onPressed: () async {
                final loc = await LocationService.instance.getCurrentLocation();
                if (loc != null) setState(() => _locationCtrl.text = loc);
              },
            ),
          ),
          _field(
            'Year established',
            _establishedYearCtrl,
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            hint: 'e.g. 2015',
          ),
          const SizedBox(height: 8),
          Text('Short description', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'One paragraph — what your company is',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          _buildSectionHeader('About company', Icons.business_outlined),
          const SizedBox(height: 12),
          _buildTextArea(
            _bioCtrl,
            'Describe your company culture, mission, and focus...',
          ),

          const SizedBox(height: 28),
          _buildSectionHeader('Company Benefits', Icons.card_giftcard_rounded),
          const SizedBox(height: 12),
          _buildTextArea(
            _benefitsCtrl,
            'Health insurance, free snacks, remote options...',
          ),

          const SizedBox(height: 28),
          _buildSectionHeader(
            'Salary Insights & Perks',
            Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextArea(
            _salaryInsightsCtrl,
            'Performance bonus, stock options, travel allowance...',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Team members',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addTeamMember,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: const Text('Add'),
              ),
            ],
          ),
          Text(
            'Optional — show faces & roles to build trust.',
            style: tt.bodySmall?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _team.length; i++) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Member ${i + 1}',
                          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (_team.length > 1)
                          IconButton(
                            onPressed: () => _removeTeamMember(i),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _team[i].nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _team[i].roleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role / title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _team[i].emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }

  Widget _buildTextArea(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
