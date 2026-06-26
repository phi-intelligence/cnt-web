import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Consistent, tasteful "Back" button used across web flows.
///
/// Renders an arrow + label inside a soft brown pill so it reads as a proper
/// affordance instead of a bare icon. Defaults to `Navigator.maybePop` but a
/// custom [onPressed] (e.g. a GoRouter pop) can be supplied.
class StyledBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  /// Use white styling for placement on dark / image backgrounds.
  final bool light;

  const StyledBackButton({
    super.key,
    this.onPressed,
    this.label = 'Back',
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = light ? Colors.white : AppColors.warmBrown;
    final Color bg =
        light ? Colors.white.withOpacity(0.15) : AppColors.warmBrown.withOpacity(0.08);
    final Color border =
        light ? Colors.white.withOpacity(0.35) : AppColors.warmBrown.withOpacity(0.2);

    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: bg,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
