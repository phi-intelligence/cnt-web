import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../screens/live/live_stream_start_screen.dart';

/// Responsive drawer for mobile and tablet navigation
class ResponsiveDrawer extends StatelessWidget {
  final int? selectedIndex;
  final Function(int) onItemSelected;

  const ResponsiveDrawer({
    super.key,
    this.selectedIndex,
    required this.onItemSelected,
  });

  List<NavigationItem> _getNavigationItems(bool isAdmin) {
    final items = [
      NavigationItem(icon: Icons.home, label: 'Home', route: 'home'),
      NavigationItem(icon: Icons.search, label: 'Search', route: 'search'),
      NavigationItem(icon: Icons.video_library, label: 'Create', route: 'create'),
      NavigationItem(icon: Icons.people, label: 'Community', route: 'community'),
      NavigationItem(icon: Icons.mic, label: 'Podcasts', route: 'podcasts'),
      NavigationItem(icon: Icons.movie, label: 'Movies', route: 'movies'),
      NavigationItem(icon: Icons.person, label: 'My Profile', route: 'profile'),
    ];
    
    if (isAdmin) {
      items.add(NavigationItem(icon: Icons.admin_panel_settings, label: 'Admin Dashboard', route: 'admin'));
    }
    
    items.add(NavigationItem(icon: Icons.info, label: 'About', route: 'about'));
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final supportProvider = context.watch<SupportProvider>();
    final unreadAdmin = authProvider.isAdmin ? supportProvider.unreadAdminCount : 0;
    final navigationItems = _getNavigationItems(authProvider.isAdmin);
    
    // Get responsive drawer width
    final drawerWidth = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.85, // 85% on mobile
      tablet: 280.0, // Fixed width on tablet
      desktop: 280.0,
    );

    return Drawer(
      width: drawerWidth,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header with logo and title
            Container(
              padding: EdgeInsets.all(AppSpacing.large * 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown.withOpacity(0.1),
                    AppColors.accentMain.withOpacity(0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Logo Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.warmBrown, AppColors.accentMain],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        child: Image.asset(
                          'assets/images/CNT-LOGO.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/cnt-dove-logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.church,
                                  size: 32,
                                  color: Colors.white,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Christ New Tabernacle',
                            style: AppTypography.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmBrown,
                            ),
                          ),
                          Text(
                            'Christian Media Platform',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                  vertical: AppSpacing.tiny,
                ),
                itemCount: navigationItems.length,
                itemBuilder: (context, index) {
                  final item = navigationItems[index];
                  final isSelected = selectedIndex == index;
                  
                  return _DrawerNavItem(
                    item: item,
                    isSelected: isSelected,
                    unreadCount: authProvider.isAdmin &&
                            item.route == 'profile' &&
                            unreadAdmin > 0
                        ? unreadAdmin
                        : null,
                      onTap: () {
                        onItemSelected(index);
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(); // Close drawer only if it can be popped
                        }
                      },
                  );
                },
              ),
            ),
            
            // Quick Action Buttons
            Container(
              padding: EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Start Live Stream Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.videocam, size: 18),
                        label: Text('Start Live Stream'),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Close drawer first
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiveStreamStartScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmBrown,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.small,
                            horizontal: AppSpacing.medium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    // Create Podcast Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.mic, size: 18),
                        label: Text('Create Podcast'),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Close drawer first
                          }
                          onItemSelected(2); // Navigate to Create screen (index 2)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmBrown,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.small,
                            horizontal: AppSpacing.medium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item data class
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Drawer navigation item widget
class _DrawerNavItem extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final int? unreadCount;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.item,
    required this.isSelected,
    this.unreadCount,
    required this.onTap,
  });

  @override
  State<_DrawerNavItem> createState() => _DrawerNavItemState();
}

class _DrawerNavItemState extends State<_DrawerNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.small,
            vertical: AppSpacing.small - 2,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.warmBrown
                : _isHovered
                    ? AppColors.warmBrown.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(999), // Pill shape
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.warmBrown,
                    width: 1,
                  )
                : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.2)
                      : _isHovered
                          ? AppColors.warmBrown.withOpacity(0.15)
                          : AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: widget.isSelected
                      ? Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Icon(
                  widget.item.icon,
                  size: 16,
                  color: widget.isSelected
                      ? Colors.white
                      : _isHovered
                          ? AppColors.warmBrown
                          : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.isSelected
                        ? Colors.white
                        : _isHovered
                            ? AppColors.warmBrown
                            : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (widget.unreadCount != null && widget.unreadCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.errorMain, AppColors.errorMain.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.errorMain.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.unreadCount! > 99 ? '99+' : '${widget.unreadCount}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
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



