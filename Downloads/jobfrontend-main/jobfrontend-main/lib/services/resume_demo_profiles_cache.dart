import '../models/resume_demo_view_profile.dart';
import 'job_seeker_api_service.dart';

/// Loads Laravel `ResumeHtmlDemoData` once for dashboard / template thumbnails.
class ResumeDemoProfilesCache {
  ResumeDemoProfilesCache._();
  static final ResumeDemoProfilesCache instance = ResumeDemoProfilesCache._();

  List<ResumeDemoViewProfile>? _profiles;
  Future<List<ResumeDemoViewProfile>>? _loading;

  int get variantCount => _profiles?.length ?? _fallbackProfiles.length;

  ResumeDemoViewProfile profileForVariant(int demoVariant) {
    final list = _profiles ?? _fallbackProfiles;
    if (list.isEmpty) return _fallbackProfiles.first;
    return list[demoVariant % list.length];
  }

  Future<List<ResumeDemoViewProfile>> ensureLoaded() {
    final cached = _profiles;
    if (cached != null && cached.isNotEmpty) {
      return Future.value(cached);
    }
    return _loading ??= _fetch();
  }

  Future<List<ResumeDemoViewProfile>> _fetch() async {
    try {
      final list = await JobSeekerApiService.instance.fetchResumeDemoProfiles();
      if (list.isNotEmpty) {
        _profiles = list;
        return list;
      }
    } catch (_) {
      // Offline / server not deployed — use embedded fallback.
    }
    _profiles = _fallbackProfiles;
    return _fallbackProfiles;
  }

  /// Subset aligned with backend `ResumeHtmlDemoData` (used when API unavailable).
  static final List<ResumeDemoViewProfile> _fallbackProfiles = [
    ResumeDemoViewProfile(
      variant: 0,
      fullName: 'Amit Jain',
      professionalTitle: 'Senior Software Engineer',
      summary:
          'Full-stack engineer with 5+ years building scalable web platforms, microservices, and cloud-native systems. Passionate about clean architecture, mentoring interns, and shipping products used by millions.',
      mobile: '+91 98765 43210',
      email: 'amit.jain.demo@email.com',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&auto=format',
      location: 'Bengaluru, Karnataka, India',
      skills: ['Java', 'Spring Boot', 'React', 'TypeScript', 'AWS', 'Docker', 'Kubernetes', 'PostgreSQL'],
      languages: ['English — Fluent', 'Hindi — Native'],
      workExperience: [
        ResumeDemoExperienceBlock(
          heading: 'JobAllocate — Senior Software Engineer',
          dates: 'Bengaluru · 2022 – Present',
          body: 'Led migration of monolith to microservices; cut p95 latency by 38%.',
        ),
      ],
      internships: const [],
      projects: [
        ResumeDemoExperienceBlock(
          heading: 'Distributed rate limiter (open source)',
          dates: '2023',
          body: 'Token-bucket service in Go with Redis; 1.2k GitHub stars.',
        ),
      ],
      educationEntries: [
        ResumeDemoEducationEntry(
          title: 'B.Tech Computer Science',
          institution: 'NIT Trichy',
          year: '2019',
          marks: '8.4 CGPA',
        ),
      ],
      certifications: ['AWS Solutions Architect — 2024', 'Oracle Java SE Professional'],
    ),
    ResumeDemoViewProfile(
      variant: 1,
      fullName: 'Varsha Nair',
      professionalTitle: 'Product Designer · UX',
      summary:
          'Product designer focused on design systems, accessibility, and research-driven iteration. 4+ years shipping B2B SaaS flows, design QA, and handoff pipelines with engineering.',
      mobile: '+91 91234 55678',
      email: 'varsha.nair.demo@email.com',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&auto=format',
      location: 'Hyderabad, Telangana, India',
      skills: ['Figma', 'Design systems', 'User research', 'Prototyping', 'WCAG 2.1', 'Design ops'],
      languages: ['English — Fluent', 'Malayalam — Native'],
      workExperience: [
        ResumeDemoExperienceBlock(
          heading: 'Orbit Health — Lead Product Designer',
          dates: 'Hyderabad · 2021 – Present',
          body: 'Owned clinician EHR workflows; reduced task time by 22% via usability tests.',
        ),
      ],
      internships: [
        ResumeDemoExperienceBlock(
          heading: 'BrightApps Studio — UX Intern',
          dates: 'Pune · 2019',
          body: 'Redesigned onboarding; improved activation by 18%.',
        ),
      ],
      projects: [
        ResumeDemoExperienceBlock(
          heading: 'Inclusive form pattern library',
          dates: '2022',
          body: 'Open Figma kit adopted by 2 product lines.',
        ),
      ],
      educationEntries: [
        ResumeDemoEducationEntry(
          title: 'M.Des Interaction Design',
          institution: 'NID Ahmedabad',
          year: '2020',
          marks: 'Distinction',
        ),
      ],
      certifications: ['Google UX Design Certificate', 'NN/g UX Certification'],
    ),
    ResumeDemoViewProfile(
      variant: 2,
      fullName: 'Rohan Kapoor',
      professionalTitle: 'Data Scientist',
      summary:
          'Applied ML engineer with strong Python and SQL. Experience in forecasting, experimentation, and MLOps on GCP.',
      mobile: '+91 99887 76655',
      email: 'rohan.kapoor.demo@email.com',
      photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop&auto=format',
      location: 'Gurugram, Haryana, India',
      skills: ['Python', 'PyTorch', 'scikit-learn', 'SQL', 'BigQuery', 'Airflow', 'Statistics'],
      languages: ['English — Fluent', 'Hindi — Native'],
      workExperience: [
        ResumeDemoExperienceBlock(
          heading: 'RetailNext AI — Data Scientist',
          dates: 'Gurugram · 2021 – Present',
          body: 'Demand forecasting models for 400+ stores; MAPE reduced by 11%.',
        ),
      ],
      internships: [
        ResumeDemoExperienceBlock(
          heading: 'IISc summer research — NLP',
          dates: '2018',
          body: 'Low-resource POS tagging; workshop paper.',
        ),
      ],
      projects: [
        ResumeDemoExperienceBlock(
          heading: 'Kaggle competition — top 5%',
          dates: '2020',
          body: 'Ensemble models for tabular churn.',
        ),
      ],
      educationEntries: [
        ResumeDemoEducationEntry(
          title: 'M.Sc Data Science',
          institution: 'IIT Madras',
          year: '2021',
          marks: '9.1 CGPA',
        ),
      ],
      certifications: ['TensorFlow Developer Certificate', 'DeepLearning.AI MLOps'],
    ),
    ResumeDemoViewProfile(
      variant: 3,
      fullName: 'Sneha Iyer',
      professionalTitle: 'Mobile Engineer (Flutter)',
      summary:
          'Mobile engineer shipping consumer apps with Flutter and native bridges. Cares about performance budgets, offline-first UX, and crash-free sessions above 99.5%.',
      mobile: '+91 98123 44556',
      email: 'sneha.iyer.demo@email.com',
      photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop&auto=format',
      location: 'Chennai, Tamil Nadu, India',
      skills: ['Flutter', 'Dart', 'Kotlin', 'Swift', 'Firebase', 'REST APIs', 'Bloc'],
      languages: ['English — Fluent', 'Tamil — Native'],
      workExperience: [
        ResumeDemoExperienceBlock(
          heading: 'QuickMart Consumer App — Flutter Lead',
          dates: 'Chennai · 2022 – Present',
          body: 'Shipped grocery app with 2M+ MAU; crash rate 0.4%.',
        ),
      ],
      internships: [
        ResumeDemoExperienceBlock(
          heading: 'RideShare Co — Mobile Intern',
          dates: '2020',
          body: 'Kotlin MVVM; maps & location.',
        ),
      ],
      projects: [
        ResumeDemoExperienceBlock(
          heading: 'Offline-first field sales CRM',
          dates: '2021',
          body: 'Flutter + Isar sync engine.',
        ),
      ],
      educationEntries: [
        ResumeDemoEducationEntry(
          title: 'B.E Computer Science',
          institution: 'Anna University CEG',
          year: '2020',
          marks: '8.6 CGPA',
        ),
      ],
      certifications: ['Associate Android Developer', 'Flutter & Dart certificate'],
    ),
  ];
}
