import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_colors.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/location_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../models/job.dart';
import 'job_seeker_home.dart';
import '../../constants/industry_types.dart';

class JobSeekerOnboardingScreen extends StatefulWidget {
  const JobSeekerOnboardingScreen({super.key});

  @override
  State<JobSeekerOnboardingScreen> createState() => _JobSeekerOnboardingScreenState();
}

class _JobSeekerOnboardingScreenState extends State<JobSeekerOnboardingScreen> {
  int _currentStep = 1;
  static const int _totalSteps = 11;
  bool _isLoading = false;
  bool _fetchingJobs = false;

  // Active industries fetched from API or local fallback
  List<IndustryTypeOption> _industries = [];
  String? _selectedIndustry;

  // Active jobs data from platform database
  List<Job> _activeJobs = [];
  
  // Sorted roles grouped by industry (ranked by frequency)
  Map<String, List<String>> _rolesByIndustry = {};
  
  // Suggested skills mapped to roles (ranked by frequency)
  List<String> _suggestedSkillsRanked = [];

  static const Map<String, Map<String, List<String>>> _allRolesAndSkillsByIndustry = {
    'software_engineering_it': {
      'Software Developer': ['Java', 'Python', 'JavaScript', 'React', 'Node.js', 'SQL', 'Git', 'HTML', 'CSS'],
      'Frontend Developer': ['HTML', 'CSS', 'JavaScript', 'TypeScript', 'React', 'Vue', 'Angular', 'TailwindCSS', 'Figma'],
      'Backend Developer': ['Node.js', 'Express', 'Python', 'Django', 'Go', 'PHP', 'Laravel', 'PostgreSQL', 'Redis', 'Docker'],
      'Full Stack Developer': ['MongoDB', 'Express', 'React', 'Node.js', 'Git', 'AWS', 'JavaScript', 'SQL', 'Docker'],
      'UI/UX Designer': ['Figma', 'Adobe XD', 'Photoshop', 'Wireframing', 'Prototyping', 'User Research', 'Sketch'],
      'QA Tester': ['Selenium', 'Jest', 'Postman', 'Cypress', 'JIRA', 'Manual Testing', 'Automation Testing'],
      'DevOps Engineer': ['Docker', 'Kubernetes', 'CI/CD', 'AWS', 'Linux', 'Terraform', 'Ansible', 'Git'],
      'Mobile App Developer': ['Flutter', 'Dart', 'React Native', 'iOS Development', 'Swift', 'Android Development', 'Kotlin'],
      'System Administrator': ['Linux', 'Windows Server', 'Active Directory', 'Networking', 'Shell Scripting', 'Virtualization'],
      'IT Support Specialist': ['Troubleshooting', 'Customer Service', 'Hardware Support', 'Operating Systems', 'Help Desk'],
    },
    'data_science_analytics': {
      'Data Analyst': ['Python', 'SQL', 'Excel', 'Tableau', 'Power BI', 'Data Visualization', 'Statistics'],
      'Data Scientist': ['Python', 'R', 'Machine Learning', 'SQL', 'Statistics', 'Pandas', 'NumPy', 'Jupyter'],
      'Machine Learning Engineer': ['Python', 'TensorFlow', 'PyTorch', 'Scikit-Learn', 'Deep Learning', 'Computer Vision', 'NLP'],
      'Data Engineer': ['SQL', 'Python', 'ETL Pipelines', 'Spark', 'Hadoop', 'Airflow', 'AWS', 'Databricks'],
      'BI Analyst': ['Power BI', 'Tableau', 'SQL', 'Data Warehousing', 'Business Intelligence', 'Dashboards'],
    },
    'design_ux_creative': {
      'Graphic Designer': ['Photoshop', 'Illustrator', 'InDesign', 'Branding', 'Typography', 'Logo Design', 'Vector Art'],
      'Video Editor': ['Premiere Pro', 'After Effects', 'Final Cut Pro', 'Video Production', 'Color Grading', 'Sound Design'],
      'Art Director': ['Creative Strategy', 'Concept Development', 'Team Leadership', 'Brand Identity', 'Adobe Creative Suite'],
      'Animator': ['3D Animation', '2D Animation', 'Blender', 'Maya', 'After Effects', 'Storyboarding', 'Character Design'],
      'Motion Designer': ['After Effects', 'Cinema 4D', 'Motion Graphics', 'Video Editing', 'Keyframing', 'Illustrator'],
    },
    'product_management': {
      'Product Manager': ['Product Roadmap', 'Agile/Scrum', 'JIRA', 'User Stories', 'Product Analytics', 'Market Research', 'SQL'],
      'Associate Product Manager': ['Agile', 'JIRA', 'User Research', 'Wireframing', 'Data Analysis', 'Product Backlog'],
      'Product Owner': ['Scrum Master', 'Product Backlog', 'Sprint Planning', 'Agile Methodologies', 'User Stories'],
      'Technical Product Manager': ['System Architecture', 'APIs', 'Product Strategy', 'Software Development Life Cycle (SDLC)', 'SQL'],
    },
    'sales_business_development': {
      'Sales Executive': ['Lead Generation', 'Communication', 'Negotiation', 'CRM (Salesforce/HubSpot)', 'Cold Calling', 'Sales Pitching'],
      'Business Development Executive': ['B2B Sales', 'Market Expansion', 'Client Acquisition', 'Relationship Management', 'Proposal Writing'],
      'Sales Manager': ['Sales Strategy', 'Team Leadership', 'Revenue Growth', 'Key Account Management', 'Forecasting'],
      'Key Account Manager': ['Client Relationship', 'Retention', 'Up-selling', 'Account Management', 'Negotiation'],
      'Inside Sales Representative': ['Lead Qualification', 'Telesales', 'CRM', 'Email Outreach', 'Product Demos'],
    },
    'marketing_digital_growth': {
      'Digital Marketing Specialist': ['SEO', 'SEM', 'Google Ads', 'Social Media Marketing', 'Email Marketing', 'Google Analytics'],
      'SEO Specialist': ['Search Engine Optimization', 'Google Search Console', 'Ahrefs', 'Keyword Research', 'Link Building', 'On-page SEO'],
      'Content Writer': ['Copywriting', 'SEO Writing', 'Blog Writing', 'Editing', 'Content Strategy', 'Creative Writing'],
      'Social Media Manager': ['Content Creation', 'Instagram/Facebook Ads', 'Buffer/Hootsuite', 'Community Management', 'Analytics'],
      'Growth Hacker': ['A/B Testing', 'Funnel Optimization', 'Conversion Rate Optimization (CRO)', 'Viral Marketing', 'Data Analytics'],
      'Brand Manager': ['Brand Strategy', 'Market Positioning', 'Advertising', 'Public Relations', 'Consumer Insights'],
    },
    'banking_finance': {
      'Financial Analyst': ['Financial Modeling', 'Valuation', 'Excel', 'Corporate Finance', 'Investment Analysis', 'Data Analysis'],
      'Investment Banker': ['M&A', 'Financial Analysis', 'Pitch Books', 'Due Diligence', 'Capital Markets', 'Valuation'],
      'Credit Analyst': ['Risk Assessment', 'Financial Statements', 'Credit Underwriting', 'Lending Analysis', 'Debt Structure'],
      'Loan Officer': ['Mortgage Lending', 'Customer Relations', 'Credit Analysis', 'Loan Documentation', 'Sales'],
      'Wealth Manager': ['Portfolio Management', 'Financial Planning', 'Asset Allocation', 'Relationship Management', 'Tax Planning'],
    },
    'accountants': {
      'Accountant': ['Tally Prime', 'GST Filing', 'Excel', 'Bookkeeping', 'Accounts Payable/Receivable', 'Bank Reconciliation'],
      'Chartered Accountant (CA)': ['Auditing', 'Taxation (Direct/Indirect)', 'Statutory Compliance', 'Financial Audits', 'Corporate Law'],
      'Tax Consultant': ['Income Tax Filing', 'GST Compliance', 'Tax Planning', 'Tax Law', 'Auditing'],
      'Bookkeeper': ['QuickBooks', 'Data Entry', 'Bank Reconciliation', 'Ledger Maintenance', 'Invoicing'],
      'Audit Associate': ['Internal Audit', 'External Audit', 'Compliance Checking', 'Vouching', 'Working Papers'],
    },
    'human_resources': {
      'HR Recruiter': ['Sourcing', 'Interviewing', 'Job Portals (Naukri/LinkedIn)', 'Applicant Tracking Systems (ATS)', 'Candidate Screening'],
      'HR Generalist': ['Employee Engagement', 'HR Policy Implementation', 'Performance Management', 'Onboarding', 'Grievance Handling'],
      'HR Manager': ['HR Strategy', 'Organizational Development', 'Talent Management', 'Labor Law', 'Budgeting'],
      'Talent Acquisition Specialist': ['Employer Branding', 'Executive Search', 'Headhunting', 'Recruiting Metrics', 'Negotiation'],
      'HR Operations Coordinator': ['Payroll Administration', 'Attendance Tracking', 'HRMS Tools', 'Documentation', 'Employee Database'],
    },
    'operations_logistics': {
      'Operations Coordinator': ['Process Optimization', 'Daily Operations', 'Coordination', 'Reporting', 'Problem Solving'],
      'Operations Manager': ['Strategic Planning', 'Resource Allocation', 'Budget Management', 'Process Improvement', 'KPI Tracking'],
      'Supply Chain Planner': ['Inventory Management', 'Demand Forecasting', 'Procurement', 'ERP Systems (SAP)', 'Material Requirements Planning (MRP)'],
      'Logistics Coordinator': ['Dispatching', 'Freight Management', 'Route Optimization', 'Tracking', 'Customs Clearance'],
      'Warehouse Supervisor': ['Inventory Counting', 'Safety Standards', 'Team Management', 'Stock Auditing', 'Shipping & Receiving'],
    },
    'healthcare_medical': {
      'Medical Practitioner / Doctor': ['Patient Diagnosis', 'Treatment Planning', 'Emergency Care', 'Medical Knowledge', 'Prescription Writing'],
      'Registered Nurse': ['Patient Monitoring', 'Medication Administration', 'Wound Care', 'ECG Monitoring', 'Compassion'],
      'Pharmacist': ['Dispensing Medicines', 'Inventory Control', 'Pharmacology Knowledge', 'Drug Interactions', 'Patient Counselling'],
      'Lab Technician': ['Blood Sample Processing', 'Microscopy', 'Laboratory Safety', 'Equipment Calibration', 'Pathology'],
      'Physiotherapist': ['Rehabilitation', 'Exercise Therapy', 'Manual Therapy', 'Pain Management', 'Patient Assessment'],
    },
    'education_training': {
      'Teacher / Lecturer': ['Classroom Management', 'Lesson Planning', 'Subject Matter Expertise', 'Student Evaluation', 'Presentation Skills'],
      'Online Tutor': ['E-learning Platforms (Zoom/Meet)', 'Interactive Teaching', 'Digital Whiteboards', 'Student Engagement'],
      'Instructional Designer': ['Curriculum Development', 'E-learning Authoring Tools (Articulate)', 'LMS Administration', 'Pedagogical Design'],
      'School Counselor': ['Student Counseling', 'Career Guidance', 'Behavioral Therapy', 'Parent Communication', 'Mental Health Support'],
      'Training Specialist': ['Corporate Training', 'Needs Analysis', 'Presentation Skills', 'Module Creation', 'Feedback Assessment'],
    },
    'legal_compliance': {
      'Legal Advisor': ['Legal Drafting', 'Corporate Governance', 'Legal Research', 'Contract Review', 'Arbitration & Litigation'],
      'Compliance Officer': ['Regulatory Compliance', 'Risk Assessment', 'Audit & Inspection', 'Policy Enforcement', 'Code of Conduct'],
      'Corporate Counsel': ['Mergers & Acquisitions', 'Commercial Contracts', 'Intellectual Property', 'Board Advising', 'Corporate Law'],
      'Paralegal': ['Case File Organization', 'Legal Research', 'Drafting Affidavits', 'Court Filing', 'Client Communication'],
      'Contract Specialist': ['Contract Drafting', 'Negotiation', 'Service Level Agreements (SLAs)', 'Contract Lifecycle Management', 'Risk Management'],
    },
    'customer_success_support': {
      'Customer Support Executive': ['Communication Skills', 'Ticket Management', 'Zendesk/Freshdesk', 'Customer Satisfaction (CSAT)', 'Active Listening'],
      'Customer Success Manager': ['Client Retention', 'Account Growth', 'Product Adoption', 'Onboarding', 'Customer Feedback Loop'],
      'Technical Support Specialist': ['Troubleshooting', 'API Testing', 'Network Diagnostics', 'Hardware/Software Installation', 'Bug Escalation'],
      'Helpdesk Representative': ['Call Handling', 'Data Entry', 'First Contact Resolution', 'Service Desk Tools (JIRA Service Management)'],
    },
    'manufacturing_engineering': {
      'Mechanical Engineer': ['AutoCAD', 'SolidWorks', 'CAD/CAM', 'Thermodynamics', 'Machine Design', 'FEA Analysis'],
      'Electrical Engineer': ['MATLAB', 'Circuit Design', 'PLC Programming', 'Power Systems', 'Electrical Safety Standards'],
      'Civil Engineer': ['STAAD Pro', 'Site Supervision', 'Estimation & Costing', 'Structural Analysis', 'Project Management'],
      'Production Engineer': ['Lean Manufacturing', 'Six Sigma', 'Assembly Line Management', 'Process Engineering', 'Safety Compliance'],
      'Quality Control Inspector': ['Quality Assurance Tools', 'Root Cause Analysis', 'Statistical Process Control (SPC)', 'ISO Standards Audit'],
    },
    'bpo_telecaller': {
      'Telecaller': ['Cold Calling', 'Lead Generation', 'Customer Engagement', 'Communication', 'Active Listening', 'Sales pitch'],
      'Customer Service Representative': ['Inbound Support', 'Conflict Resolution', 'Data Entry', 'CRM Handling', 'Escalation Procedures'],
      'Inbound Agent': ['Call Handling', 'Inquiry Resolution', 'Order Processing', 'Soft Skills', 'Product Knowledge'],
      'Outbound Agent': ['Sales Outcalls', 'Lead Qualifying', 'Appointment Scheduling', 'Handling Rejections', 'Telemarketing'],
      'Telemarketing Executive': ['Tele-sales', 'Target Orientation', 'Lead Tracking', 'Product Demos', 'Communication'],
    },
    'other_general': {
      'Administrative Assistant': ['Data Entry', 'Calendar Management', 'Office Administration', 'Email Correspondence', 'MS Office (Word/Excel)'],
      'Office Administrator': ['Vendor Coordination', 'Facility Management', 'Billing & Invoicing', 'Documentation', 'Supervision'],
      'Data Entry Operator': ['Typing Speed (WPM)', 'Data Accuracy', 'Excel Spreadsheet', 'Scanning & Archiving', 'Data Verification'],
      'Receptionist': ['Front Desk Operations', 'Visitor Management', 'Call Routing', 'Multitasking', 'Professional Etiquette'],
      'General Executive': ['Ad-hoc Tasks', 'Basic Report Preparation', 'Documentation', 'Time Management', 'Coordination'],
    },
    'bpo': {
      'BPO Executive': ['Customer Interaction', 'Data Entry', 'Voice & Non-voice Operations', 'Communication Skills', 'CRM Software'],
    },
    'telecaller': {
      'Telecaller Executive': ['Cold Calling', 'Lead Conversions', 'Customer Follow-up', 'Product Pitching', 'Communication'],
    },
    'banking': {
      'Bank Clerk': ['Cash Handling', 'Customer Service', 'Data Entry', 'Account Management', 'Basic Math'],
      'Branch Manager': ['Branch Operations', 'Team Leadership', 'Business Development', 'Compliance', 'Audit Oversight'],
    },
    'finance': {
      'Financial Advisor': ['Investment Planning', 'Risk Assessment', 'Mutual Funds', 'Client Relationship', 'Financial Planning'],
      'Treasury Analyst': ['Cash Management', 'Foreign Exchange', 'Liquidity Planning', 'Risk Mitigation', 'Financial Modeling'],
    }
  };

  // Form Controllers / States
  // Step 2: Basic Info
  final TextEditingController _nameController = TextEditingController();

  // Step 3: Job Interests
  final List<String> _selectedRoles = [];

  // Step 4: Skills
  final List<String> _selectedSkills = [];
  final TextEditingController _customSkillController = TextEditingController();

  // Step 5: Current Status
  String? _currentStatus; // Student, Fresher, Experienced Professional, Freelancer, Career Break
  final TextEditingController _expYearsController = TextEditingController();
  final TextEditingController _currentCompanyController = TextEditingController();
  final TextEditingController _currentRoleController = TextEditingController();

  // Step 6: Education (Optional)
  String _qualification = 'Bachelor\'s Degree';
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _gradYearController = TextEditingController();
  final TextEditingController _gradMarksController = TextEditingController();

  final TextEditingController _s12BoardController = TextEditingController();
  final TextEditingController _s12SchoolController = TextEditingController();
  final TextEditingController _s12YearController = TextEditingController();
  final TextEditingController _s12MarksController = TextEditingController();

  final TextEditingController _s10BoardController = TextEditingController();
  final TextEditingController _s10SchoolController = TextEditingController();
  final TextEditingController _s10YearController = TextEditingController();
  final TextEditingController _s10MarksController = TextEditingController();


  // Step 7: Location Preferences
  final TextEditingController _cityController = TextEditingController();
  final List<String> _preferredLocations = [];
  final TextEditingController _preferredLocationInputController = TextEditingController();
  bool _willingToRelocate = false;

  // Step 8: Employment Preferences
  final List<String> _selectedEmploymentPrefs = [];
  final List<String> _employmentPrefOptions = [
    'Full Time',
    'Part Time',
    'Internship',
    'Contract',
    'Remote',
    'Hybrid',
    'Work From Office'
  ];

  // Step 9: Salary Expectations (Optional)
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

  // Step 10: Resume
  String? _resumeUrl;
  bool _uploadingResume = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AppSession.user?['name'] ?? '';
    _loadProfileDataAndResumeStep();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _degreeController.dispose();
    _collegeController.dispose();
    _gradYearController.dispose();
    _gradMarksController.dispose();
    _s12BoardController.dispose();
    _s12SchoolController.dispose();
    _s12YearController.dispose();
    _s12MarksController.dispose();
    _s10BoardController.dispose();
    _s10SchoolController.dispose();
    _s10YearController.dispose();
    _s10MarksController.dispose();
    _expYearsController.dispose();
    _currentCompanyController.dispose();
    _currentRoleController.dispose();
    _cityController.dispose();
    _preferredLocationInputController.dispose();
    _customSkillController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  // Fetch industries list
  Future<void> _loadIndustries() async {
    try {
      final list = await JobSeekerApiService.instance.listActiveIndustryTypesFromApi();
      if (!mounted) return;
      setState(() {
        _industries = list;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _industries = List<IndustryTypeOption>.from(kIndustryTypes);
      });
    }
  }

  IconData _getIndustryIcon(String key) {
    switch (key) {
      case 'software_engineering_it':
        return Icons.computer_rounded;
      case 'data_science_analytics':
        return Icons.analytics_rounded;
      case 'design_ux_creative':
        return Icons.brush_rounded;
      case 'product_management':
        return Icons.assignment_rounded;
      case 'sales_business_development':
        return Icons.trending_up_rounded;
      case 'marketing_digital_growth':
        return Icons.campaign_rounded;
      case 'banking_finance':
      case 'banking':
      case 'finance':
        return Icons.account_balance_rounded;
      case 'accountants':
        return Icons.calculate_rounded;
      case 'human_resources':
        return Icons.people_alt_rounded;
      case 'operations_logistics':
        return Icons.local_shipping_rounded;
      case 'healthcare_medical':
        return Icons.medical_services_rounded;
      case 'education_training':
        return Icons.school_rounded;
      case 'legal_compliance':
        return Icons.gavel_rounded;
      case 'customer_success_support':
        return Icons.support_agent_rounded;
      case 'manufacturing_engineering':
        return Icons.engineering_rounded;
      case 'bpo_telecaller':
      case 'bpo':
      case 'telecaller':
        return Icons.phone_in_talk_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }

  // Load existing profile, including onboarding_step to resume progress
  Future<void> _loadProfileDataAndResumeStep() async {
    setState(() => _isLoading = true);
    try {
      final profile = await JobSeekerApiService.instance.getSeekerProfile();
      if (!mounted) return;

      setState(() {
        if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
          _nameController.text = profile['name'];
        }

        // Resume from last saved step
        final savedStep = profile['onboarding_step'];
        if (savedStep is int && savedStep >= 1 && savedStep <= _totalSteps) {
          _currentStep = savedStep;
        }

        _resumeUrl = profile['resume_url'];
        _currentStatus = profile['current_status'];

        if (profile['experience_years'] != null) {
          _expYearsController.text = profile['experience_years'].toString();
          if (profile['experience_years'] > 0) {
            _currentStatus ??= 'Experienced Professional';
          }
        }
        
        if (profile['current_company'] != null) {
          _currentCompanyController.text = profile['current_company'].toString();
        }
        if (profile['current_role'] != null) {
          _currentRoleController.text = profile['current_role'].toString();
        }
        if (profile['city'] != null) {
          _cityController.text = profile['city'].toString();
        }

        if (profile['industry_type'] != null) {
          _selectedIndustry = profile['industry_type'].toString();
        }

        if (profile['job_roles'] is List) {
          _selectedRoles.clear();
          _selectedRoles.addAll((profile['job_roles'] as List).map((e) => e.toString()));
        }

        if (profile['skills'] is List) {
          _selectedSkills.clear();
          _selectedSkills.addAll((profile['skills'] as List).map((e) => e.toString()));
        }

        if (profile['preferred_locations'] is List) {
          _preferredLocations.clear();
          _preferredLocations.addAll((profile['preferred_locations'] as List).map((e) => e.toString()));
        }

        if (profile['willing_to_relocate'] != null) {
          _willingToRelocate = profile['willing_to_relocate'] == true;
        }

        if (profile['employment_preferences'] is List) {
          _selectedEmploymentPrefs.clear();
          _selectedEmploymentPrefs.addAll((profile['employment_preferences'] as List).map((e) => e.toString()));
        }

        if (profile['expected_salary_min'] != null) {
          _minSalaryController.text = profile['expected_salary_min'].toString();
        }

        if (profile['expected_salary_max'] != null) {
          _maxSalaryController.text = profile['expected_salary_max'].toString();
        }

        final edu = profile['education'];
        if (edu is List && edu.isNotEmpty) {
          for (final item in edu) {
            if (item is Map) {
              final title = item['title']?.toString();
              if (title == 'Class 10th') {
                _s10BoardController.text = item['board_or_stream']?.toString() ?? '';
                _s10SchoolController.text = item['institution']?.toString() ?? '';
                _s10YearController.text = item['year_completed']?.toString() ?? '';
                _s10MarksController.text = item['marks_or_grade']?.toString() ?? '';
              } else if (title == 'Class 12th') {
                _s12BoardController.text = item['board_or_stream']?.toString() ?? '';
                _s12SchoolController.text = item['institution']?.toString() ?? '';
                _s12YearController.text = item['year_completed']?.toString() ?? '';
                _s12MarksController.text = item['marks_or_grade']?.toString() ?? '';
              } else {
                _qualification = title ?? _qualification;
                _degreeController.text = item['board_or_stream']?.toString() ?? '';
                _collegeController.text = item['institution']?.toString() ?? '';
                _gradYearController.text = item['year_completed']?.toString() ?? '';
                _gradMarksController.text = item['marks_or_grade']?.toString() ?? '';
              }
            }
          }
        }

        _isLoading = false;
      });

      // Fetch industries and active jobs
      await _loadIndustries();
      await _fetchActiveJobsAndRoles();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _applyFallbackRolesAndSkills();
      }
    }
  }

  // Fetch active job roles and skills from the database
  Future<void> _fetchActiveJobsAndRoles() async {
    setState(() => _fetchingJobs = true);
    try {
      final jobs = await JobSeekerApiService.instance.listJobs(perPage: 150);
      if (!mounted) return;

      final Map<String, Map<String, int>> rolesMapWithCount = {};
      
      for (final job in jobs) {
        final industry = job.industryType ?? 'other_general';
        final title = job.title;

        rolesMapWithCount.putIfAbsent(industry, () => {});
        rolesMapWithCount[industry]![title] = (rolesMapWithCount[industry]![title] ?? 0) + 1;
      }

      final Map<String, List<String>> sortedRolesMap = {};
      for (final entry in rolesMapWithCount.entries) {
        final industry = entry.key;
        final rolesWithCounts = entry.value.entries.toList();
        
        // Sort roles by frequency (descending)
        rolesWithCounts.sort((a, b) => b.value.compareTo(a.value));
        
        sortedRolesMap[industry] = rolesWithCounts.map((e) => e.key).toList();
      }

      setState(() {
        _activeJobs = jobs;
        _rolesByIndustry = sortedRolesMap;
        _fetchingJobs = false;

        _mergeFallbackRoles();
        _updateRankedSkills();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchingJobs = false;
          _applyFallbackRolesAndSkills();
        });
      }
    }
  }

  // Fallback data if no active jobs exist in database yet
  void _applyFallbackRolesAndSkills() {
    _rolesByIndustry = {};
    _allRolesAndSkillsByIndustry.forEach((industryKey, rolesMap) {
      _rolesByIndustry[industryKey] = rolesMap.keys.toList();
    });
    _updateRankedSkills();
  }

  // Merge static fallback roles with the fetched roles
  void _mergeFallbackRoles() {
    _allRolesAndSkillsByIndustry.forEach((industryKey, rolesMap) {
      final currentRoles = _rolesByIndustry[industryKey] ?? [];
      final Set<String> uniqueRoles = Set.from(currentRoles);
      for (final staticRole in rolesMap.keys) {
        uniqueRoles.add(staticRole);
      }
      _rolesByIndustry[industryKey] = uniqueRoles.toList();
    });
  }

  // Update and rank suggested skills by frequency
  void _updateRankedSkills() {
    if (_selectedRoles.isEmpty) {
      setState(() {
        _suggestedSkillsRanked = [];
      });
      return;
    }

    final Map<String, int> skillCounts = {};
    
    // Count frequencies of skills from active jobs that match selected roles
    for (final job in _activeJobs) {
      if (_selectedRoles.contains(job.title)) {
        for (final skill in job.skills) {
          skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
        }
      }
    }

    // Merge static skills from our map for all selected roles
    _allRolesAndSkillsByIndustry.forEach((industryKey, rolesMap) {
      for (final role in _selectedRoles) {
        if (rolesMap.containsKey(role)) {
          final staticSkills = rolesMap[role] ?? [];
          for (final skill in staticSkills) {
            skillCounts[skill] = (skillCounts[skill] ?? 0) + 1;
          }
        }
      }
    });

    final sortedSkills = skillCounts.entries.toList();
    sortedSkills.sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _suggestedSkillsRanked = sortedSkills.map((e) => e.key).toList();
    });
  }

  // Profile completion calculation based on weights
  int _calculateProfileCompletion() {
    int percent = 0;
    if (_nameController.text.trim().isNotEmpty && _nameController.text.trim() != 'User') {
      percent += 15;
    }
    if (_selectedIndustry != null) {
      percent += 5;
    }
    if (_selectedRoles.isNotEmpty) {
      percent += 15;
    }
    if (_selectedSkills.isNotEmpty) {
      percent += 20;
    }
    if (_degreeController.text.trim().isNotEmpty || _collegeController.text.trim().isNotEmpty) {
      percent += 10;
    }
    if (_currentStatus != null) {
      percent += 15;
    }
    if (_cityController.text.trim().isNotEmpty || _preferredLocations.isNotEmpty) {
      percent += 10;
    }
    if (_resumeUrl != null) {
      percent += 10;
    }
    return percent;
  }

  // Handle Step Progress & Auto-Save
  Future<void> _nextStep({bool skip = false}) async {
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> body = {};

      if (!skip) {
        switch (_currentStep) {
          case 2:
            if (_nameController.text.trim().isEmpty) {
              _showSnackBar('Please enter your full name');
              setState(() => _isLoading = false);
              return;
            }
            body['name'] = _nameController.text.trim();
            break;
          case 3:
            if (_selectedIndustry == null) {
              _showSnackBar('Please select an industry');
              setState(() => _isLoading = false);
              return;
            }
            body['industry_type'] = _selectedIndustry;
            break;
          case 4:
            if (_selectedRoles.isEmpty) {
              _showSnackBar('Please select at least one job role');
              setState(() => _isLoading = false);
              return;
            }
            body['job_roles'] = _selectedRoles;
            break;
          case 5:
            if (_selectedSkills.isEmpty) {
              _showSnackBar('Please add or select at least one skill');
              setState(() => _isLoading = false);
              return;
            }
            body['skills'] = _selectedSkills;
            break;
          case 6:
            if (_currentStatus == null) {
              _showSnackBar('Please select your current status');
              setState(() => _isLoading = false);
              return;
            }
            body['current_status'] = _currentStatus;
            final isExperienced = _currentStatus == 'Experienced Professional' || _currentStatus == 'Freelancer';
            body['is_experienced'] = isExperienced;
            if (isExperienced) {
              body['experience_years'] = int.tryParse(_expYearsController.text.trim()) ?? 0;
              body['current_company'] = _currentCompanyController.text.trim();
              body['current_role'] = _currentRoleController.text.trim();
              body['headline'] = '${_currentRoleController.text.trim()} at ${_currentCompanyController.text.trim()}';
            } else {
              body['experience_years'] = 0;
              body['headline'] = 'Seeking entry-level opportunities as $_currentStatus';
            }
            break;
          case 7:
            final list = <Map<String, dynamic>>[];
            if (_qualification != 'Class 10th' && _qualification != 'Class 12th') {
              final degree = _degreeController.text.trim();
              final college = _collegeController.text.trim();
              final year = _gradYearController.text.trim();
              final marks = _gradMarksController.text.trim();
              if (degree.isNotEmpty || college.isNotEmpty || year.isNotEmpty) {
                list.add({
                  'title': _qualification,
                  'board_or_stream': degree,
                  'institution': college,
                  'year_completed': year,
                  'marks_or_grade': marks,
                });
              }
            }
            if (_qualification != 'Class 10th') {
              final board12 = _s12BoardController.text.trim();
              final school12 = _s12SchoolController.text.trim();
              final year12 = _s12YearController.text.trim();
              final marks12 = _s12MarksController.text.trim();
              if (board12.isNotEmpty || school12.isNotEmpty || year12.isNotEmpty) {
                list.add({
                  'title': 'Class 12th',
                  'board_or_stream': board12,
                  'institution': school12,
                  'year_completed': year12,
                  'marks_or_grade': marks12,
                });
              }
            }
            final board10 = _s10BoardController.text.trim();
            final school10 = _s10SchoolController.text.trim();
            final year10 = _s10YearController.text.trim();
            final marks10 = _s10MarksController.text.trim();
            if (board10.isNotEmpty || school10.isNotEmpty || year10.isNotEmpty) {
              list.add({
                'title': 'Class 10th',
                'board_or_stream': board10,
                'institution': school10,
                'year_completed': year10,
                'marks_or_grade': marks10,
              });
            }
            if (list.isNotEmpty) {
              body['education'] = list;
            }
            break;
          case 8:
            body['city'] = _cityController.text.trim();
            body['preferred_locations'] = _preferredLocations;
            body['willing_to_relocate'] = _willingToRelocate;
            break;
          case 9:
            body['employment_preferences'] = _selectedEmploymentPrefs;
            break;
          case 10:
            body['expected_salary_min'] = int.tryParse(_minSalaryController.text.trim());
            body['expected_salary_max'] = int.tryParse(_maxSalaryController.text.trim());
            break;
          case 11:
            body['onboarded'] = true;
            break;
        }
      }

      // Track next step in database
      final nextStepNum = _currentStep + 1;
      body['onboarding_step'] = nextStepNum > _totalSteps ? _totalSteps : nextStepNum;

      if (_currentStep == _totalSteps) {
        body['onboarded'] = true;
      }

      // Save to database automatically
      await JobSeekerApiService.instance.updateSeekerProfile(body);

      setState(() {
        _isLoading = false;
        if (_currentStep < _totalSteps) {
          _currentStep++;
          if (_currentStep == 5) {
            // Regenerate skill suggestions for step 5
            _updateRankedSkills();
          }
        } else {
          _finishOnboarding();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _skipRemainingOnboarding() async {
    setState(() => _isLoading = true);
    try {
      await JobSeekerApiService.instance.updateSeekerProfile({
        'onboarded': true,
        'onboarding_step': _totalSteps,
      });
      if (!mounted) return;
      _finishOnboarding();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _finishOnboarding() {
    final finalPercent = _calculateProfileCompletion();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile $finalPercent% Complete. Welcome to JobAllocate! 🚀'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: JobSeekerHomeScreen.routeName),
        builder: (_) => JobSeekerHomeScreen(
          userId: AppSession.userId,
          token: AppSession.token,
        ),
      ),
      (_) => false,
    );
  }

  Future<void> _pickAndUploadResume() async {
    setState(() => _uploadingResume = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _uploadingResume = false);
        return;
      }

      final path = result.files.single.path;
      if (path == null || path.isEmpty) {
        throw Exception('Could not read selected file');
      }

      final data = await JobSeekerApiService.instance.uploadResumePdf(
        File(path),
      );
      final url = data['resume_url']?.toString();
      if (url != null && url.trim().isNotEmpty) {
        setState(() => _resumeUrl = url.trim());
      }

      _showSnackBar('Resume uploaded successfully!', isError: false);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _uploadingResume = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: _previousStep,
              )
            : null,
        title: Row(
          children: [
            const Spacer(),
            TextButton(
              onPressed: _isLoading ? null : _skipRemainingOnboarding,
              child: const Text(
                'Skip Onboarding',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(textTheme),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _currentStep / _totalSteps;
    final completionPct = _calculateProfileCompletion();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $_currentStep of $_totalSteps',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              Text(
                'Profile $completionPct% Complete',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryLight.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool isOptional = _currentStep == 1 || _currentStep == 7 || _currentStep == 10 || _currentStep == 11;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isOptional) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _nextStep(skip: true),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.textHint),
                ),
                child: const Text('Skip Step', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: CustomButton(
              text: _currentStep == 1 
                  ? 'Let\'s Start' 
                  : (_currentStep == _totalSteps ? 'Finish Profile' : 'Next Step'),
              onPressed: () => _nextStep(skip: false),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(TextTheme textTheme) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(textTheme);
      case 2:
        return _buildStep2(textTheme);
      case 3:
        return _buildStep3(textTheme);
      case 4:
        return _buildStep4(textTheme);
      case 5:
        return _buildStep5(textTheme);
      case 6:
        return _buildStep6(textTheme);
      case 7:
        return _buildStep7(textTheme);
      case 8:
        return _buildStep8(textTheme);
      case 9:
        return _buildStep9(textTheme);
      case 10:
        return _buildStep10(textTheme);
      case 11:
        return _buildStep11(textTheme);
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Welcome
  Widget _buildStep1(TextTheme textTheme) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 64, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'Welcome! Let\'s help you find the right jobs. 🚀',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Completing your onboarding profile helps us curate relevant job categories, direct matches, and improve your daily recommendations.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Takes less than a minute! You can start applying right away.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Basic Information (Required)
  Widget _buildStep2(TextTheme textTheme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your name? 👋',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Please enter your full name as you would like it to appear on your profile and applications.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // STEP 3: Select Industry (Required)
  Widget _buildStep3(TextTheme textTheme) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which industry do you work in? 🏢',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your primary industry. We will customize your job roles and skills recommendations based on this selection.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: _industries.isEmpty ? kIndustryTypes.length : _industries.length,
          itemBuilder: (context, index) {
            final industry = _industries.isEmpty ? kIndustryTypes[index] : _industries[index];
            final isSelected = _selectedIndustry == industry.key;
            final icon = _getIndustryIcon(industry.key);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndustry = industry.key;
                  // Clear roles and skills since industry changed
                  _selectedRoles.clear();
                  _selectedSkills.clear();
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.textHint.withOpacity(0.3),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      industry.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 4: Select Job Roles (Required)
  Widget _buildStep4(TextTheme textTheme) {
    if (_selectedIndustry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'Please go back and select an industry first.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    if (_fetchingJobs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final roles = _rolesByIndustry[_selectedIndustry] ?? [];

    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What job roles interest you? 🎯',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Select the job roles you are looking for in the ${industryTypeLabel(_selectedIndustry)} industry. (Select multiple)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (roles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                'No roles found for this industry. You can proceed to add custom skills next.',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: roles.map((role) {
              final isSelected = _selectedRoles.contains(role);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedRoles.remove(role);
                    } else {
                      _selectedRoles.add(role);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textHint.withOpacity(0.3),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        role,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // STEP 5: Skills (Required, dynamically suggested & ranked)
  Widget _buildStep5(TextTheme textTheme) {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your professional skills 💻',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve analyzed active job requirements matching your interests. Here are the most demanded skills (ranked by frequency).',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (_suggestedSkillsRanked.isNotEmpty) ...[
          const Text(
            'Recommended Skills',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedSkillsRanked.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.12),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Add Custom Skills',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSkillController,
                decoration: const InputDecoration(
                  labelText: 'Skill Name',
                  hintText: 'e.g. Flutter, SEO, Photoshop',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustomSkill(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _addCustomSkill,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_selectedSkills.isNotEmpty) ...[
          const Text(
            'Your Selected Skills',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSkills.map((skill) {
              return InputChip(
                label: Text(skill),
                onDeleted: () {
                  setState(() {
                    _selectedSkills.remove(skill);
                  });
                },
                deleteIconColor: AppColors.error,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // STEP 6: Current Status (Required)
  Widget _buildStep6(TextTheme textTheme) {
    final List<String> statusOptions = [
      'Student',
      'Fresher',
      'Experienced Professional',
      'Freelancer',
      'Career Break'
    ];

    final bool isExp = _currentStatus == 'Experienced Professional' || _currentStatus == 'Freelancer';

    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your current status? 💼',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your current employment profile status.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ...statusOptions.map((status) {
          final isSelected = _currentStatus == status;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ListTile(
              title: Text(
                status,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              trailing: isSelected 
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : const Icon(Icons.circle_outlined, color: AppColors.textHint),
              onTap: () {
                setState(() {
                  _currentStatus = status;
                });
              },
            ),
          );
        }),
        if (isExp) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Experience Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expYearsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Experience (Years) *',
              hintText: 'e.g. 3',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentCompanyController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Current / Previous Company Name *',
              hintText: 'e.g. Google',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentRoleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Current / Previous Job Role *',
              hintText: 'e.g. Software Engineer',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEducationSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 7: Education (Optional)
  Widget _buildStep7(TextTheme textTheme) {
    final showHighest = _qualification != 'Class 10th' && _qualification != 'Class 12th';
    final showClass12 = _qualification != 'Class 10th';

    return Column(
      key: const ValueKey(7),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your education 🎓',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Provide details of your academic qualifications. (Optional, can be skipped)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        DropdownButtonFormField<String>(
          value: _qualification,
          decoration: const InputDecoration(labelText: 'Highest Qualification', border: OutlineInputBorder()),
          items: [
            'Class 10th',
            'Class 12th',
            'Diploma / Certificate',
            'Bachelor\'s Degree',
            'Master\'s Degree',
            'Ph.D. / Doctorate'
          ].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
          onChanged: (v) => setState(() => _qualification = v ?? 'Bachelor\'s Degree'),
        ),
        
        if (showHighest)
          _buildEducationSectionCard(
            title: 'Highest Qualification Details ($_qualification)',
            icon: Icons.school_rounded,
            children: [
              TextField(
                controller: _degreeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Course / Degree Name',
                  hintText: 'e.g. B.Tech Computer Science, BBA',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _collegeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'College / University Name',
                  hintText: 'e.g. Delhi University',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gradYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Graduation Year',
                        hintText: 'e.g. 2024',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _gradMarksController,
                      decoration: const InputDecoration(
                        labelText: 'Marks / CGPA',
                        hintText: 'e.g. 8.5 CGPA, 85%',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        if (showClass12)
          _buildEducationSectionCard(
            title: 'Class 12th Details',
            icon: Icons.menu_book_rounded,
            children: [
              TextField(
                controller: _s12BoardController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Board / Stream Name',
                  hintText: 'e.g. CBSE Science, State Board Commerce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _s12SchoolController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'School Name',
                  hintText: 'e.g. St. Xavier\'s High School',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _s12YearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passing Year',
                        hintText: 'e.g. 2020',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _s12MarksController,
                      decoration: const InputDecoration(
                        labelText: 'Marks / Percentage',
                        hintText: 'e.g. 92%',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

        _buildEducationSectionCard(
          title: 'Class 10th Details',
          icon: Icons.book_rounded,
          children: [
            TextField(
              controller: _s10BoardController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Board Name',
                hintText: 'e.g. CBSE, ICSE, State Board',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _s10SchoolController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'School Name',
                hintText: 'e.g. Central School',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _s10YearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Passing Year',
                      hintText: 'e.g. 2018',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _s10MarksController,
                    decoration: const InputDecoration(
                      labelText: 'Marks / Percentage',
                      hintText: 'e.g. 95%',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // STEP 8: Location Preferences (Required)
  Widget _buildStep8(TextTheme textTheme) {
    return Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you located? 📍',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Let us know your current city and multiple preferred locations for matching job listings.',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _cityController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Current City *',
            hintText: 'e.g. Pune',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              onPressed: () async {
                final loc = await LocationService.instance.getCurrentLocation();
                if (loc != null) {
                  setState(() => _cityController.text = loc);
                }
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Preferred Job Locations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _preferredLocationInputController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Add Preferred City',
                  hintText: 'e.g. Mumbai, Bengaluru',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addPreferredLocation(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: _addPreferredLocation,
            ),
          ],
        ),
        if (_preferredLocations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _preferredLocations.map((loc) {
              return Chip(
                label: Text(loc),
                onDeleted: () {
                  setState(() {
                    _preferredLocations.remove(loc);
                  });
                },
                deleteIconColor: AppColors.error,
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _willingToRelocate,
              onChanged: (v) => setState(() => _willingToRelocate = v ?? false),
              activeColor: AppColors.primary,
            ),
            const Expanded(
              child: Text(
                'Are you willing to relocate for the right job?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 9: Employment Preferences (Required)
  Widget _buildStep9(TextTheme textTheme) {
    return Column(
      key: const ValueKey(9),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred employment settings ⚙️',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Select your preferred workspace formats and work types. (Select multiple)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _employmentPrefOptions.map((option) {
            final isSelected = _selectedEmploymentPrefs.contains(option);
            return ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(option),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedEmploymentPrefs.add(option);
                  } else {
                    _selectedEmploymentPrefs.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 10: Salary Expectations (Optional)
  Widget _buildStep10(TextTheme textTheme) {
    return Column(
      key: const ValueKey(10),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your expected salary? 💸',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Provide your minimum and maximum expected monthly salary (INR). (Optional, can be skipped)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minSalaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum Salary (₹)',
                  hintText: 'e.g. 30000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxSalaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Salary (₹)',
                  hintText: 'e.g. 60000',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 11: Resume Upload (Optional)
  Widget _buildStep11(TextTheme textTheme) {
    return Column(
      key: const ValueKey(11),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload your resume 📄',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          'Supported file formats: PDF, DOC, or DOCX. (Optional, can be skipped)',
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 36),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: (_uploadingResume || _isLoading) ? null : _pickAndUploadResume,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid, width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        _resumeUrl == null ? 'Select Resume File' : 'Replace Resume File',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text('Format: PDF, DOC, DOCX up to 5MB', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.blue.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blue.withOpacity(0.25)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Future Ready: Resume parsing can automatically extract skills, education, and experience.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.deepPurple.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.deepPurple.withOpacity(0.25)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, color: Colors.deepPurple),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No Resume? Build one inside the app! Use our premium, professional resume templates to generate a stunning ATS-friendly resume in seconds after completing registration.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_uploadingResume) ...[
                const SizedBox(height: 20),
                const Text('Uploading resume...', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 5, color: AppColors.primary),
              ],
              if (_resumeUrl != null && !_uploadingResume) ...[
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 28),
                    title: const Text('Resume uploaded', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      Uri.parse(_resumeUrl!).pathSegments.last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _addCustomSkill() {
    final skill = _customSkillController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _customSkillController.clear();
      });
    }
  }

  void _addPreferredLocation() {
    final loc = _preferredLocationInputController.text.trim();
    if (loc.isNotEmpty && !_preferredLocations.contains(loc)) {
      setState(() {
        _preferredLocations.add(loc);
        _preferredLocationInputController.clear();
      });
    }
  }
}
