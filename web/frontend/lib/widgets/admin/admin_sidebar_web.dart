import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
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
    return Container(
      width: 280,
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large, 
              vertical: AppSpacing.extraLarge
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
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
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Text(
                  'Admin',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.small),
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
            padding: const EdgeInsets.all(AppSpacing.medium),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 12, // Comfortable hit area
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
              size: 20,
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 16,
              )
            ],
          ],
        ),
      ),
    );
  }
}
