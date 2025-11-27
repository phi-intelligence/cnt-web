import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Dashboard card widget matching create page design style
/// Displays an icon, value, and label with colorful background and hover effects
class AdminDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const AdminDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textInverse, size: 36),
              ),
              SizedBox(height: AppSpacing.medium),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.tiny),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

