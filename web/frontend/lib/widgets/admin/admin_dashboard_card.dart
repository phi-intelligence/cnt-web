import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';

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
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Responsive sizing
    final iconSize = isSmallMobile ? 18.0 : (isMobile ? 20.0 : 24.0);
    final padding = isSmallMobile 
        ? AppSpacing.small 
        : (isMobile ? AppSpacing.medium * 0.75 : AppSpacing.medium);
    final iconPadding = isSmallMobile ? AppSpacing.tiny * 0.5 : AppSpacing.tiny;
    
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textInverse, size: iconSize),
              ),
              SizedBox(height: isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      fontSize: isSmallMobile ? 20 : (isMobile ? 24 : null),
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(height: isSmallMobile ? AppSpacing.tiny * 0.5 : AppSpacing.tiny),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textInverse.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      fontSize: isSmallMobile ? 11 : (isMobile ? 12 : null),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

