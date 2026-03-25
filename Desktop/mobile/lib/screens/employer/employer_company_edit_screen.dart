import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/company_api_service.dart';
import '../../utils/app_colors.dart';
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

  final List<_TeamRow> _team = [];
  bool _saving = false;
  String? _industryTypeKey;

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
    _bioCtrl = TextEditingController(text: c['company_bio']?.toString() ?? '');
    _whatWeDoCtrl = TextEditingController(text: c['what_we_do']?.toString() ?? '');

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
    for (final t in _team) {
      t.dispose();
    }
    super.dispose();
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

      await _api.updateProfile({
        'name': _nameCtrl.text.trim(),
        'industry': _industryCtrl.text.trim().isEmpty ? null : _industryCtrl.text.trim(),
        'industry_type': _industryTypeKey,
        'website': web.isEmpty ? null : web,
        'gst_number': _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
        'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'established_year': establishedYear,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'company_bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'what_we_do': _whatWeDoCtrl.text.trim().isEmpty ? null : _whatWeDoCtrl.text.trim(),
        'team_members': teamPayload.isEmpty ? [] : teamPayload,
      });

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
        backgroundColor: AppColors.accent,
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
          _field('Company name *', _nameCtrl),
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
          _field('Head office / location', _locationCtrl,
              hint: 'City, state or full address'),
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
          Text('Company bio', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Culture, mission, size, awards…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('What we do', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _whatWeDoCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Products, services, who you help',
              border: OutlineInputBorder(),
            ),
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
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save company profile'),
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
        ),
      ),
    );
  }
}
