import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import 'styled_back_button.dart';

/// Lightweight page header for screens that already have their own backdrop
/// (split image layouts, full-page background imagery).
///
/// A pill "Back" button with optional trailing actions, then a brown hero
/// title and subtitle — clean and unobtrusive, so it never fights the page
/// background the way a full-width gradient bar does.
class CompactPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const CompactPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveUtils.getResponsiveValue<double>(
      context: context,
      mobile: 26,
      tablet: 32,
      desktop: 38,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) StyledBackButton(onPressed: onBack),
            if (actions.isNotEmpty) ...[
              const Spacer(),
              ...actions,
            ],
          ],
        ),
        SizedBox(height: AppSpacing.large),
        Text(
          title,
          style: AppTypography.heading1.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
            height: 1.1,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppSpacing.small),
          Text(
            subtitle!,
            style: AppTypography.body.copyWith(
              color: AppColors.primaryDark.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
