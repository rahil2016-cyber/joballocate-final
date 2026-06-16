import 'package:flutter/material.dart';

import '../constants/industry_types.dart';
import '../services/job_seeker_api_service.dart';

/// Nullable [value] = no selection. Options load from `GET /industry-types` when possible
/// so admin-added industries appear for employers and seekers without an app update.
class IndustryTypeDropdown extends StatefulWidget {
  const IndustryTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText = 'Industry / job field',
    this.dense = false,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String labelText;
  final bool dense;

  @override
  State<IndustryTypeDropdown> createState() => _IndustryTypeDropdownState();
}

class _IndustryTypeDropdownState extends State<IndustryTypeDropdown> {
  List<IndustryTypeOption> _options = List<IndustryTypeOption>.from(kIndustryTypes);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IndustryTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    try {
      final next = await JobSeekerApiService.instance.listActiveIndustryTypesFromApi();
      if (!mounted) return;
      setState(() {
        _options = next;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = List<IndustryTypeOption>.from(kIndustryTypes);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _options.map((e) => e.key).toSet()..add('none_of_above');
    final safeValue = widget.value != null && allowed.contains(widget.value) ? widget.value : null;

    return DropdownButtonFormField<String?>(
      value: safeValue,
      isDense: widget.dense,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: const Text('Select…'),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Not set'),
        ),
        ..._options.map(
          (e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(e.label, overflow: TextOverflow.ellipsis),
          ),
        ),
        const DropdownMenuItem<String?>(
          value: 'none_of_above',
          child: Text(
            'None of the above (Write custom)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
      onChanged: widget.onChanged,
    );
  }
}
