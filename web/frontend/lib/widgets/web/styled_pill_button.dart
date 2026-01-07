import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';

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
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    // Reduce padding when width is constrained to ensure text fits
    final horizontalPadding = width != null 
        ? (isSmallMobile ? AppSpacing.medium : AppSpacing.large)
        : (isSmallMobile ? AppSpacing.large : AppSpacing.extraLarge);
    final verticalPadding = isSmallMobile ? AppSpacing.medium : AppSpacing.medium + 4;

    if (variant == StyledPillButtonVariant.outlined || variant == StyledPillButtonVariant.outlinedLight) {
      Widget button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: _foregroundColor,
            side: BorderSide(
              color: _borderColor,
              width: 2,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            minimumSize: Size.zero, // Remove default minimum size
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target to content size
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            disabledForegroundColor: variant == StyledPillButtonVariant.outlinedLight 
                ? Colors.white.withOpacity(0.5) 
                : AppColors.textSecondary,
          ),
          child: _buildButtonContent(context),
        );
      
      if (width != null) {
        return SizedBox(
          width: width,
          child: button,
        );
      }
      return IntrinsicWidth(child: button);
    }

    Widget button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          foregroundColor: AppColors.textInverse,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          minimumSize: Size.zero, // Remove default minimum size
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce tap target to content size
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          elevation: 2,
          disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.5),
          disabledForegroundColor: AppColors.textInverse.withOpacity(0.7),
        ),
        child: _buildButtonContent(context),
      );
    
    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }
    return IntrinsicWidth(child: button);
  }

  Widget _buildButtonContent(BuildContext context) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
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
        fontSize: isSmallMobile ? 14 : 16, // Slightly larger for better visibility
      ),
      overflow: TextOverflow.visible, // Allow text to be fully visible
      softWrap: false,
    );

    if (icon == null) {
      return textWidget;
    }

    if (iconLeading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: isSmallMobile ? 18 : 20,
            color: _foregroundColor,
          ),
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        textWidget,
        const SizedBox(width: 8),
        Icon(
          icon,
          size: isSmallMobile ? 18 : 20,
          color: _foregroundColor,
        ),
      ],
    );
  }
}

