import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import '../../screens/admin_dashboard.dart';

class AdminSidebarWeb extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> navItems;
  final Function(int) onNavigate;
  final VoidCallback onLogout;

  const AdminSidebarWeb({
    super.key,
    required this.currentIndex,
    required this.navItems,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Responsive width - only applies when used in Row (desktop)
    // When used in Drawer, Drawer width takes precedence
    final sidebarWidth = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 280.0,
      tablet: 300.0,
      desktop: 280.0,
    );
    
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          right: BorderSide(
            color: AppColors.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
              vertical: ResponsiveUtils.getResponsivePadding(context, AppSpacing.extraLarge),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getResponsivePadding(context, AppSpacing.small),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
                Flexible(
                  child: Text(
                    'Admin',
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontSize: isSmallMobile ? 18 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(
                ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium),
              ),
              itemCount: navItems.length,
              separatorBuilder: (_, __) => SizedBox(
                height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small),
              ),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive = currentIndex == index;
                
                return _SidebarItem(
                  icon: isActive ? item.activeIcon : item.icon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => onNavigate(index),
                );
              },
            ),
          ),
          
          const Divider(height: 1),

          // Logout Button
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium),
            ),
            child: _SidebarItem(
              icon: Icons.logout,
              label: 'Logout',
              isActive: false,
              isDestructive: true,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final color = isDestructive 
        ? AppColors.warmBrown 
        : isActive 
            ? Colors.white 
            : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium),
          vertical: ResponsiveUtils.getResponsiveValue(
            context: context,
            mobile: 14.0, // Larger touch target for mobile
            tablet: 12.0,
            desktop: 12.0,
          ),
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.warmBrown 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive 
              ? null
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
            Flexible(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isSmallMobile ? 13 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: ResponsiveUtils.getResponsiveIconSize(context, 16),
              )
            ],
          ],
        ),
      ),
    );
  }
}
