import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Styled Pill Button Component for Web
/// Provides consistent button styling matching the homepage design
enum StyledPillButtonVariant {
  filled,
  outlined,
  outlinedLight, // For use on dark/brown backgrounds
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

  Color get _foregroundColor {
    switch (variant) {
      case StyledPillButtonVariant.filled:
        return AppColors.textInverse;
      case StyledPillButtonVariant.outlined:
        return AppColors.warmBrown;
      case StyledPillButtonVariant.outlinedLight:
        return Colors.white;
    }
  }

  Color get _borderColor {
    switch (variant) {
      case StyledPillButtonVariant.filled:
        return AppColors.warmBrown;
      case StyledPillButtonVariant.outlined:
        return AppColors.warmBrown;
      case StyledPillButtonVariant.outlinedLight:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (variant == StyledPillButtonVariant.outlined || variant == StyledPillButtonVariant.outlinedLight) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _foregroundColor,
            side: BorderSide(
              color: _borderColor,
              width: 2,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.extraLarge,
              vertical: AppSpacing.medium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            disabledForegroundColor: variant == StyledPillButtonVariant.outlinedLight 
                ? Colors.white.withOpacity(0.5) 
                : AppColors.textSecondary,
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
          valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
        ),
      );
    }

    final textWidget = Text(
      label,
      style: AppTypography.button.copyWith(
        color: _foregroundColor,
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
            color: _foregroundColor,
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
          color: _foregroundColor,
        ),
      ],
    );
  }
}

