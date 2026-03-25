/// Canonical API values for [Company.verification_status] — use only these in DB / API.
abstract class CompanyVerificationValue {
  static const unverified = 'unverified';
  static const pending = 'pending';
  static const verified = 'verified';
  static const rejected = 'rejected';

  /// Human-readable label (app UI). Keys must match API enum strings exactly.
  static const Map<String, String> labels = {
    unverified: 'Not verified',
    pending: 'Pending review',
    verified: 'Verified',
    rejected: 'Rejected',
  };

  static String label(String? raw) {
    if (raw == null || raw.trim().isEmpty) return labels[unverified]!;
    final k = raw.trim().toLowerCase();
    return labels[k] ?? raw;
  }
}

/// Canonical API values for [JobPost.status] — use only these in DB / API.
abstract class JobPostStatusValue {
  static const draft = 'draft';
  static const pendingReview = 'pending_review';
  static const published = 'published';
  static const closed = 'closed';
  static const rejected = 'rejected';

  static const Map<String, String> labels = {
    draft: 'Draft',
    pendingReview: 'Pending approval',
    published: 'Approved & live',
    closed: 'Closed',
    rejected: 'Rejected',
  };

  static String label(String? raw) {
    if (raw == null || raw.trim().isEmpty) return labels[draft]!;
    final k = raw.trim().toLowerCase();
    return labels[k] ?? raw;
  }
}
