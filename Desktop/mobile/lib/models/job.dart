import 'package:flutter/material.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

class Job {
  final String id;
  final String title;
  final String companyName;
  final String location;
  final String jobType;
  final String experienceLevel;
  /// API `industry_type` key (e.g. `software_engineering_it`).
  final String? industryType;
  final double? salaryMin;
  final double? salaryMax;
  final List<String> skills;
  final String description;
  final String requirements;
  final int applicationsCount;
  final int viewsCount;
  final DateTime createdAt;
  /// From API: when applications close automatically.
  final DateTime? applicationDeadlineAt;
  final int? maxApplications;

  Job({
    required this.id,
    required this.title,
    required this.companyName,
    required this.location,
    required this.jobType,
    required this.experienceLevel,
    this.industryType,
    this.salaryMin,
    this.salaryMax,
    required this.skills,
    required this.description,
    required this.requirements,
    required this.applicationsCount,
    required this.viewsCount,
    required this.createdAt,
    this.applicationDeadlineAt,
    this.maxApplications,
  });

  /// Laravel public job payload (`GET /jobs`, `GET /jobs/{id}`).
  factory Job.fromApi(Map<String, dynamic> json) {
    String companyName = 'Company';
    final company = json['company'];
    if (company is Map) {
      companyName = company['name']?.toString() ?? companyName;
    }

    final skillsRaw = json['skills'];
    final skills = <String>[];
    if (skillsRaw is List) {
      for (final e in skillsRaw) {
        if (e != null) skills.add(e.toString());
      }
    }

    DateTime createdAt = DateTime.now();
    final pub = json['published_at']?.toString();
    if (pub != null && pub.isNotEmpty) {
      createdAt = DateTime.tryParse(pub)?.toLocal() ?? createdAt;
    } else {
      final c = json['created_at']?.toString();
      if (c != null && c.isNotEmpty) {
        createdAt = DateTime.tryParse(c)?.toLocal() ?? createdAt;
      }
    }

    DateTime? deadline;
    final dl = json['application_deadline_at']?.toString();
    if (dl != null && dl.isNotEmpty) {
      deadline = DateTime.tryParse(dl)?.toLocal();
    }

    int? maxApp;
    final mx = json['max_applications'];
    if (mx is int) {
      maxApp = mx;
    } else if (mx != null) {
      maxApp = int.tryParse(mx.toString());
    }

    int appCount = 0;
    final ac = json['applications_count'];
    if (ac is int) {
      appCount = ac;
    } else if (ac != null) {
      appCount = int.tryParse(ac.toString()) ?? 0;
    }

    final itk = json['industry_type']?.toString();
    return Job(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? 'Job',
      companyName: companyName,
      location: json['location']?.toString() ?? '',
      jobType: json['employment_type']?.toString() ?? 'full_time',
      experienceLevel: json['experience_level']?.toString() ?? 'mid_level',
      industryType: (itk != null && itk.isNotEmpty) ? itk : null,
      salaryMin: _toDouble(json['salary_min']),
      salaryMax: _toDouble(json['salary_max']),
      skills: skills,
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString() ?? '',
      applicationsCount: appCount,
      viewsCount: json['views_count'] is int
          ? json['views_count'] as int
          : int.tryParse(json['views_count']?.toString() ?? '') ?? 0,
      createdAt: createdAt,
      applicationDeadlineAt: deadline,
      maxApplications: maxApp,
    );
  }

  /// Legacy / demo JSON shape.
  factory Job.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills_required'] ?? json['skills'];
    List<String> skills = [];
    if (skillsRaw is List) {
      skills = skillsRaw.map((e) => e.toString()).toList();
    }
    final itk2 = json['industry_type']?.toString();
    return Job(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? 'Unknown Company',
      location: json['location']?.toString() ?? '',
      jobType: json['job_type']?.toString() ?? 'full_time',
      experienceLevel: json['experience_level']?.toString() ?? 'mid',
      industryType: (itk2 != null && itk2.isNotEmpty) ? itk2 : null,
      salaryMin: _toDouble(json['salary_min']),
      salaryMax: _toDouble(json['salary_max']),
      skills: skills,
      description: json['description']?.toString() ?? '',
      requirements: json['requirements']?.toString() ?? '',
      applicationsCount: json['applications_count'] is int
          ? json['applications_count'] as int
          : int.tryParse(json['applications_count']?.toString() ?? '') ?? 0,
      viewsCount: json['views_count'] is int
          ? json['views_count'] as int
          : int.tryParse(json['views_count']?.toString() ?? '') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      applicationDeadlineAt: json['application_deadline_at'] != null
          ? DateTime.tryParse(json['application_deadline_at'].toString())
          : null,
      maxApplications: json['max_applications'] is int
          ? json['max_applications'] as int
          : int.tryParse(json['max_applications']?.toString() ?? ''),
    );
  }

  String get salaryRange {
    if (salaryMin == null && salaryMax == null) {
      return 'Not specified';
    }
    if (salaryMin != null && salaryMax != null) {
      return '₹${salaryMin!.toStringAsFixed(0)} – ₹${salaryMax!.toStringAsFixed(0)}';
    }
    if (salaryMin != null) {
      return '₹${salaryMin!.toStringAsFixed(0)}+';
    }
    return 'Up to ₹${salaryMax!.toStringAsFixed(0)}';
  }

  /// Human-readable experience (API may use `mid_level`).
  String get experienceDisplay => experienceLevel.replaceAll('_', ' ');

  String get postedAgoLabel {
    final d = DateTime.now().difference(createdAt).inDays;
    if (d <= 0) return 'Today';
    if (d == 1) return '1d ago';
    return '${d}d ago';
  }
}

class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String status;
  final DateTime appliedAt;
  final DateTime updatedAt;
  /// From API `employer_note` — message visible to the job seeker.
  final String? notes;
  /// Cover letter submitted with the application.
  final String? coverLetter;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.appliedAt,
    required this.updatedAt,
    this.notes,
    this.coverLetter,
  });

  factory JobApplication.fromApi(Map<String, dynamic> json) {
    Map<String, dynamic>? jobPost;
    final jp = json['job_post'];
    if (jp is Map<String, dynamic>) {
      jobPost = Map<String, dynamic>.from(jp);
    }
    String companyName = 'Company';
    final co = jobPost?['company'];
    if (co is Map) {
      companyName = co['name']?.toString() ?? companyName;
    }
    final title = jobPost?['title']?.toString() ?? 'Job';
    final jid = (json['job_post_id'] ?? jobPost?['id'])?.toString() ?? '';

    DateTime appliedAt = DateTime.now();
    final a = json['applied_at']?.toString();
    if (a != null && a.isNotEmpty) {
      appliedAt = DateTime.tryParse(a)?.toLocal() ?? appliedAt;
    }
    DateTime updatedAt = appliedAt;
    final u = json['updated_at']?.toString();
    if (u != null && u.isNotEmpty) {
      updatedAt = DateTime.tryParse(u)?.toLocal() ?? updatedAt;
    }

    final st = json['status'];
    final statusStr = st == null ? 'applied' : st.toString();

    return JobApplication(
      id: json['id'].toString(),
      jobId: jid,
      jobTitle: title,
      companyName: companyName,
      status: statusStr,
      appliedAt: appliedAt,
      updatedAt: updatedAt,
      notes: json['employer_note']?.toString(),
      coverLetter: json['cover_letter']?.toString(),
    );
  }

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'].toString(),
      jobId: json['job_id']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? 'Job Title',
      companyName: json['company_name']?.toString() ?? 'Company',
      status: json['status']?.toString() ?? 'applied',
      appliedAt: DateTime.parse(json['applied_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      notes: json['notes']?.toString(),
      coverLetter: json['cover_letter']?.toString(),
    );
  }

  Color getStatusColor() {
    switch (status) {
      case 'applied':
        return Colors.blue;
      case 'shortlisted':
        return Colors.orange;
      case 'interview':
      case 'interviewed':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'hired':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'applied':
        return 'Awaiting employer';
      case 'shortlisted':
        return 'Shortlisted';
      case 'interview':
      case 'interviewed':
        return 'Interview';
      case 'rejected':
        return 'Rejected';
      case 'hired':
        return 'Hired';
      default:
        return status;
    }
  }
}
