import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Styled Pill Button Component for Web
/// Provides consistent button styling matching the homepage design
enum StyledPillButtonVariant {
  filled,
  outlined,
}

class StyledPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final StyledPillButtonVariant variant;
  final IconData? icon;
  final bool iconLeading;
  final bool isLoading;
  final double? width;

  const StyledPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = StyledPillButtonVariant.filled,
    this.icon,
    this.iconLeading = true,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == StyledPillButtonVariant.outlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warmBrown,
            side: BorderSide(
              color: AppColors.warmBrown,
              width: 2,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.extraLarge,
              vertical: AppSpacing.medium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            disabledForegroundColor: AppColors.textSecondary,
          ),
          child: _buildButtonContent(),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          foregroundColor: AppColors.textInverse,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.extraLarge,
            vertical: AppSpacing.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          elevation: 2,
          disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.5),
          disabledForegroundColor: AppColors.textInverse.withOpacity(0.7),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == StyledPillButtonVariant.filled
                ? AppColors.textInverse
                : AppColors.warmBrown,
          ),
        ),
      );
    }

    final textWidget = Text(
      label,
      style: AppTypography.button.copyWith(
        color: variant == StyledPillButtonVariant.filled
            ? AppColors.textInverse
            : AppColors.warmBrown,
      ),
    );

    if (icon == null) {
      return textWidget;
    }

    if (iconLeading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: variant == StyledPillButtonVariant.filled
                ? AppColors.textInverse
                : AppColors.warmBrown,
          ),
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        textWidget,
        const SizedBox(width: 8),
        Icon(
          icon,
          size: 20,
          color: variant == StyledPillButtonVariant.filled
              ? AppColors.textInverse
              : AppColors.warmBrown,
        ),
      ],
    );
  }
}

