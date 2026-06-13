import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

/// “Find your dream job today” plus [AppStrings.brandTagline] — under logos and hero areas.
class BrandDreamJobTagline extends StatelessWidget {
  const BrandDreamJobTagline({
    super.key,
    this.headlineStyle,
    this.taglineStyle,
    this.textAlign = TextAlign.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8,
    this.showHeadline = true,
  });

  final TextStyle? headlineStyle;
  final TextStyle? taglineStyle;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool showHeadline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final defaultHeadline = theme.titleMedium?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );
    final defaultTagline = theme.titleSmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.25,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (showHeadline && AppStrings.dreamJobHeadline.isNotEmpty) ...[
          Text(
            AppStrings.dreamJobHeadline,
            textAlign: textAlign,
            style: headlineStyle ?? defaultHeadline,
          ),
          SizedBox(height: spacing),
        ],
        Text(
          AppStrings.brandTagline,
          textAlign: textAlign,
          style: taglineStyle ?? defaultTagline,
        ),
      ],
    );
  }
}
