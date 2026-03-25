import 'package:flutter/material.dart';
import '../constants/industry_types.dart';

/// Nullable [value] = no selection.
class IndustryTypeDropdown extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isDense: dense,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      hint: const Text('Select…'),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Not set'),
        ),
        ...kIndustryTypes.map(
          (e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(e.label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
