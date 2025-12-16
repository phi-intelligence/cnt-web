import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Styled Filter Chip Component for Web
/// Provides consistent filter chip styling matching the brown pill button design system
class StyledFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelected; // Alternative callback that receives selected state
  final int? count; // Optional count to display (e.g., "All (23)")

  const StyledFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.onSelected,
    this.count,
  }) : assert(onTap != null || onSelected != null, 'Either onTap or onSelected must be provided');

  @override
  Widget build(BuildContext context) {
    final displayLabel = count != null ? '$label ($count)' : label;
    
    return GestureDetector(
      onTap: () {
        if (onSelected != null) {
          onSelected!(!selected); // Toggle selection state
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.warmBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: selected ? AppColors.warmBrown : AppColors.borderPrimary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
