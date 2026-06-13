/// Parsed from `GET /job-seeker/profile` (`data` object).
///
/// Job and resume credits use **separate** expiry fields on the server so buying
/// one type does not remove the other.
class SeekerProfileSummary {
  SeekerProfileSummary({
    required this.packageKey,
    required this.jobPackageKey,
    required this.resumePackageKey,
    required this.applicationsRemaining,
    required this.resumeBuildsRemaining,
    required this.packageExpiresAt,
    required this.packageActivatedAt,
    required this.jobCreditsExpiresAt,
    required this.resumeCreditsExpiresAt,
  });

  final String? packageKey;
  final String? jobPackageKey;
  final String? resumePackageKey;
  final int? applicationsRemaining;
  final int? resumeBuildsRemaining;
  final DateTime? packageExpiresAt;
  final DateTime? packageActivatedAt;
  final DateTime? jobCreditsExpiresAt;
  final DateTime? resumeCreditsExpiresAt;

  static DateTime? _parse(String? key) {
    final s = key?.toString();
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  factory SeekerProfileSummary.fromJson(Map<String, dynamic> json) {
    final ar = json['applications_remaining'];
    int? remaining;
    if (ar is int) {
      remaining = ar;
    } else if (ar != null) {
      remaining = int.tryParse(ar.toString());
    }
    final rr = json['resume_builds_remaining'];
    int? resumeLeft;
    if (rr is int) {
      resumeLeft = rr;
    } else if (rr != null) {
      resumeLeft = int.tryParse(rr.toString());
    }

    final legacyExp = _parse(json['package_expires_at']?.toString());

    return SeekerProfileSummary(
      packageKey: json['package_key']?.toString(),
      jobPackageKey: json['job_package_key']?.toString(),
      resumePackageKey: json['resume_package_key']?.toString(),
      applicationsRemaining: remaining,
      resumeBuildsRemaining: resumeLeft,
      packageExpiresAt: legacyExp,
      packageActivatedAt: _parse(json['package_activated_at']?.toString()),
      jobCreditsExpiresAt:
          _parse(json['job_credits_expires_at']?.toString()) ?? legacyExp,
      resumeCreditsExpiresAt:
          _parse(json['resume_credits_expires_at']?.toString()) ?? legacyExp,
    );
  }

  /// Matches Laravel [JobSeekerProfile::canApply].
  bool get canApply {
    if (applicationsRemaining == null || applicationsRemaining! < 1) return false;
    if (jobCreditsExpiresAt == null) return false;
    return jobCreditsExpiresAt!.isAfter(DateTime.now());
  }

  /// Matches Laravel [JobSeekerProfile::canBuildResume].
  bool get canBuildResume {
    if (resumeBuildsRemaining == null || resumeBuildsRemaining! < 1) return false;
    if (resumeCreditsExpiresAt == null) return false;
    return resumeCreditsExpiresAt!.isAfter(DateTime.now());
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day}/${d.month}/${d.year}';

  /// Shown on Plans & packages. Job credits only — resume builder + AI are free; PDF is ₹20 on export.
  String get statusLine {
    final now = DateTime.now();
    final jobActive = applicationsRemaining != null &&
        applicationsRemaining! > 0 &&
        jobCreditsExpiresAt != null &&
        jobCreditsExpiresAt!.isAfter(now);

    if (!jobActive) {
      if (applicationsRemaining != null &&
          applicationsRemaining! > 0 &&
          jobCreditsExpiresAt != null) {
        return 'Job applications expired (${_fmt(jobCreditsExpiresAt)}). '
            'Resume builder and AI are free; pay ₹20 only when you download a resume PDF.';
      }
      return 'No active job credits — pick a plan below. '
          'Resume builder and AI are free; pay ₹20 only when you download a resume PDF.';
    }

    return 'You have ${applicationsRemaining!} job credit${applicationsRemaining == 1 ? '' : 's'} left';
  }
}
