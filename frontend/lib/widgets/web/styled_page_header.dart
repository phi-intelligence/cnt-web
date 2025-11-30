import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'styled_pill_button.dart';

/// Styled Page Header Component for Web
/// Provides consistent header styling matching the homepage design
enum StyledPageHeaderSize {
  h1,
  h2,
}

class StyledPageHeader extends StatelessWidget {
  final String title;
  final StyledPageHeaderSize size;
  final Widget? action;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool showContainer;
  final Color? backgroundColor;

  const StyledPageHeader({
    super.key,
    required this.title,
    this.size = StyledPageHeaderSize.h1,
    this.action,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.showContainer = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = Text(
      title,
      style: (size == StyledPageHeaderSize.h1
              ? AppTypography.heading1
              : AppTypography.heading2)
          .copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );

    Widget headerContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: headerText),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.medium),
          action!,
        ] else if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: AppSpacing.medium),
          StyledPillButton(
            label: actionLabel!,
            icon: actionIcon,
            onPressed: onAction,
          ),
        ],
      ],
    );

    if (showContainer) {
      headerContent = Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.extraLarge,
          vertical: AppSpacing.large,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: headerContent,
      );
    } else {
      headerContent = Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
        child: headerContent,
      );
    }

    return headerContent;
  }
}

