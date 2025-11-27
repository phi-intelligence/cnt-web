import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Styled Filter Chip Component for Web
/// Provides consistent filter chip styling matching the homepage design
class StyledFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const StyledFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? AppColors.warmBrown,
      backgroundColor: unselectedColor ?? AppColors.backgroundSecondary,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: selected
            ? Colors.white
            : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(
          color: selected
              ? (selectedColor ?? AppColors.warmBrown)
              : AppColors.borderPrimary,
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
    );
  }
}

