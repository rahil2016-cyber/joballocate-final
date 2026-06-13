class SubscriptionPlan {
  final String id;
  final String name;
  final String type; // 'resume', 'job_application', 'combo'
  final double price; // in INR
  final int resumeCredits;
  final int jobCredits;
  final int validityDays;
  final bool popular;
  final String description;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.resumeCredits,
    required this.jobCredits,
    required this.validityDays,
    this.popular = false,
    required this.description,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      resumeCredits: json['resumeCredits'] ?? 0,
      jobCredits: json['jobCredits'] ?? 0,
      validityDays: json['validityDays'] ?? 30,
      popular: json['popular'] ?? false,
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'price': price,
        'resumeCredits': resumeCredits,
        'jobCredits': jobCredits,
        'validityDays': validityDays,
        'popular': popular,
        'description': description,
        'features': features,
      };
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final String type;
  final int resumeCreditsTotal;
  final int resumeCreditsUsed;
  final int jobCreditsTotal;
  final int jobCreditsUsed;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String status; // 'active', 'expired', 'exhausted'
  final String? orderId;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    required this.type,
    required this.resumeCreditsTotal,
    required this.resumeCreditsUsed,
    required this.jobCreditsTotal,
    required this.jobCreditsUsed,
    required this.purchasedAt,
    required this.expiresAt,
    required this.status,
    this.orderId,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['userId'],
      planId: json['planId'],
      planName: json['planName'],
      type: json['type'],
      resumeCreditsTotal: json['resumeCreditsTotal'] ?? 0,
      resumeCreditsUsed: json['resumeCreditsUsed'] ?? 0,
      jobCreditsTotal: json['jobCreditsTotal'] ?? 0,
      jobCreditsUsed: json['jobCreditsUsed'] ?? 0,
      purchasedAt: DateTime.parse(json['purchasedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      status: json['status'] ?? 'active',
      orderId: json['orderId'],
    );
  }

  int get resumeCreditsRemaining =>
      (resumeCreditsTotal == 999) ? 999 : resumeCreditsTotal - resumeCreditsUsed;
  int get jobCreditsRemaining => jobCreditsTotal - jobCreditsUsed;

  bool get isUnlimitedResume => resumeCreditsTotal == 999;

  int get daysLeft {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

// Hardcoded fallback plans (for demo / offline mode)
final List<SubscriptionPlan> kHardcodedPlans = [
  SubscriptionPlan(
    id: 'resume_basic',
    name: 'Resume Basic',
    type: 'resume',
    price: 99,
    resumeCredits: 5,
    jobCredits: 0,
    validityDays: 30,
    description: 'Build up to 5 resumes in 30 days',
    features: [
      '5 Resume builds',
      '30-day validity',
      'Access to all 20 templates',
    ],
  ),
  SubscriptionPlan(
    id: 'resume_pro',
    name: 'Resume Pro',
    type: 'resume',
    price: 149,
    resumeCredits: 10,
    jobCredits: 0,
    validityDays: 60,
    popular: true,
    description: 'Build up to 10 resumes in 60 days',
    features: [
      '10 Resume builds',
      '60-day validity',
      'Access to all 20 templates',
      'Priority email support',
    ],
  ),
  SubscriptionPlan(
    id: 'resume_unlimited',
    name: 'Resume Unlimited',
    type: 'resume',
    price: 249,
    resumeCredits: 999,
    jobCredits: 0,
    validityDays: 90,
    description: 'Unlimited resume builds for 90 days',
    features: [
      'Unlimited Resume builds',
      '90-day validity',
      'Access to all 20 templates',
    ],
  ),
  SubscriptionPlan(
    id: 'jobs_starter',
    name: 'Job Starter',
    type: 'job_application',
    price: 249,
    resumeCredits: 0,
    jobCredits: 3,
    validityDays: 30,
    description: 'Apply to 3 jobs within 30 days',
    features: [
      '3 Job applications',
      '30-day validity',
      'Application status tracking',
    ],
  ),
  SubscriptionPlan(
    id: 'jobs_standard',
    name: 'Job Standard',
    type: 'job_application',
    price: 449,
    resumeCredits: 0,
    jobCredits: 6,
    validityDays: 30,
    popular: true,
    description: 'Apply to 6 jobs within 30 days',
    features: [
      '6 Job applications',
      '30-day validity',
      'Application status tracking',
      'Priority listing visibility',
    ],
  ),
  SubscriptionPlan(
    id: 'jobs_premium',
    name: 'Job Premium',
    type: 'job_application',
    price: 799,
    resumeCredits: 0,
    jobCredits: 15,
    validityDays: 60,
    description: 'Apply to 15 jobs within 60 days',
    features: [
      '15 Job applications',
      '60-day validity',
      'Application status tracking',
      'Priority listing visibility',
      'Dedicated job alerts',
    ],
  ),
  SubscriptionPlan(
    id: 'combo_starter',
    name: 'Combo Starter',
    type: 'combo',
    price: 299,
    resumeCredits: 3,
    jobCredits: 3,
    validityDays: 30,
    description: '3 resumes + 3 job applications in 30 days',
    features: [
      '3 Resume builds',
      '3 Job applications',
      '30-day validity',
    ],
  ),
  SubscriptionPlan(
    id: 'combo_pro',
    name: 'Combo Pro',
    type: 'combo',
    price: 549,
    resumeCredits: 8,
    jobCredits: 8,
    validityDays: 60,
    popular: true,
    description: '8 resumes + 8 job applications in 60 days',
    features: [
      '8 Resume builds',
      '8 Job applications',
      '60-day validity',
      'Priority support',
    ],
  ),
  SubscriptionPlan(
    id: 'combo_ultimate',
    name: 'Combo Ultimate',
    type: 'combo',
    price: 999,
    resumeCredits: 999,
    jobCredits: 25,
    validityDays: 90,
    description: 'Unlimited resumes + 25 job applications in 90 days',
    features: [
      'Unlimited Resume builds',
      '25 Job applications',
      '90-day validity',
      'Dedicated support',
    ],
  ),
];
