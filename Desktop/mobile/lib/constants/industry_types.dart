/// Shared with Laravel [App\Support\IndustryType::KEYS] — keep keys in sync.
class IndustryTypeOption {
  const IndustryTypeOption(this.key, this.label);
  final String key;
  final String label;
}

const List<IndustryTypeOption> kIndustryTypes = [
  IndustryTypeOption(
    'software_engineering_it',
    'Software engineering & IT',
  ),
  IndustryTypeOption(
    'data_science_analytics',
    'Data science & analytics',
  ),
  IndustryTypeOption(
    'design_ux_creative',
    'Design, UX & creative',
  ),
  IndustryTypeOption(
    'product_management',
    'Product management',
  ),
  IndustryTypeOption(
    'sales_business_development',
    'Sales & business development',
  ),
  IndustryTypeOption(
    'marketing_digital_growth',
    'Marketing & digital growth',
  ),
  IndustryTypeOption(
    'finance_accounting',
    'Finance & accounting',
  ),
  IndustryTypeOption(
    'human_resources',
    'Human resources',
  ),
  IndustryTypeOption(
    'operations_logistics',
    'Operations & logistics',
  ),
  IndustryTypeOption(
    'healthcare_medical',
    'Healthcare & medical',
  ),
  IndustryTypeOption(
    'education_training',
    'Education & training',
  ),
  IndustryTypeOption(
    'legal_compliance',
    'Legal & compliance',
  ),
  IndustryTypeOption(
    'customer_success_support',
    'Customer success & support',
  ),
  IndustryTypeOption(
    'manufacturing_engineering',
    'Manufacturing & engineering',
  ),
  IndustryTypeOption(
    'other_general',
    'Other / general',
  ),
];

String industryTypeLabel(String? key) {
  if (key == null || key.isEmpty) return '—';
  for (final e in kIndustryTypes) {
    if (e.key == key) return e.label;
  }
  return key;
}
