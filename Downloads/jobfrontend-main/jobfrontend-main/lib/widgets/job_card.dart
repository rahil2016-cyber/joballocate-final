import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job.dart';
import '../../utils/app_colors.dart';
import '../../constants/industry_types.dart';

class JobCardWidget extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onApply;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  /// True when the current user has already submitted an application for this job.
  final bool hasApplied;
  /// Job closed, past deadline, or otherwise not accepting applications.
  final bool isNoLongerAccepting;

  const JobCardWidget({
    super.key,
    required this.job,
    required this.onTap,
    this.onApply,
    this.onBookmark,
    this.isBookmarked = false,
    this.hasApplied = false,
    this.isNoLongerAccepting = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Company icon + Title + Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: job.companyLogoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: job.companyLogoUrl!,
                              fit: BoxFit.contain,
                              width: 48,
                              height: 48,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  job.companyName.isNotEmpty
                                      ? job.companyName[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                job.companyName.isNotEmpty
                                    ? job.companyName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.companyName,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onBookmark != null)
                      IconButton(
                        onPressed: onBookmark,
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isBookmarked
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (isNoLongerAccepting) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.35)),
                    ),
                    child: const Text(
                      'Expired / no longer accepting applications',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Info Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.location_on_outlined,
                      label: job.location,
                    ),
                    if (job.industryType != null &&
                        job.industryType!.isNotEmpty)
                      _buildInfoChip(
                        icon: Icons.category_outlined,
                        label: industryTypeLabel(job.industryType),
                      ),
                    _buildInfoChip(
                      icon: Icons.access_time_rounded,
                      label: job.jobType.replaceAll('_', ' ').toUpperCase(),
                    ),
                    _buildInfoChip(
                      icon: Icons.currency_rupee_rounded,
                      label: job.salaryRange,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Skills
                if (job.skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.skills.take(4).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Bottom: Experience + stats + Apply (Wrap avoids horizontal overflow)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.experienceDisplay.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '${job.viewsCount}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '${job.applicationsCount} applied',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (hasApplied)
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: AppColors.success),
                            SizedBox(width: 6),
                            Text(
                              'Applied',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (onApply != null && !isNoLongerAccepting)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: onApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 0),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}