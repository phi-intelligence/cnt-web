import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import 'hamburger_menu_button.dart';

/// Responsive app bar for mobile and tablet devices
/// Shows hamburger menu, page title, and action icons
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.showMenuButton = true,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final supportProvider = context.watch<SupportProvider>();
    final unreadAdmin = authProvider.isAdmin ? supportProvider.unreadAdminCount : 0;
    
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showMenuButton && onMenuPressed != null
          ? HamburgerMenuButton(onPressed: onMenuPressed!)
          : null,
      title: title != null
          ? Text(
              title!,
              style: AppTypography.heading3.copyWith(
                color: AppColors.warmBrown,
                fontWeight: FontWeight.bold,
              ),
            )
          : Row(
              children: [
                // Logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.warmBrown, AppColors.accentMain],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: Image.asset(
                      'assets/images/cnt-dove-logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.church,
                          size: 20,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'CNT',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.warmBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      actions: actions ?? [
        // Notifications icon
        if (unreadAdmin > 0)
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: AppColors.warmBrown),
                onPressed: () {
                  // Navigate to notifications or support
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.errorMain,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadAdmin > 99 ? '99+' : '$unreadAdmin',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        // Profile icon
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.small),
          child: IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.warmBrown.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 20,
                color: AppColors.warmBrown,
              ),
            ),
            onPressed: () {
              // Navigate to profile
            },
          ),
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }
}



