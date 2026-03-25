class SavedJob {
  final String id;
  final String jobId;
  final String title;
  final String companyName;
  final String location;
  final DateTime savedAt;

  SavedJob({
    required this.id,
    required this.jobId,
    required this.title,
    required this.companyName,
    required this.location,
    required this.savedAt,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      savedAt: json['saved_at'] != null
          ? DateTime.tryParse(json['saved_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'title': title,
      'company_name': companyName,
      'location': location,
      'saved_at': savedAt.toIso8601String(),
    };
  }
}
