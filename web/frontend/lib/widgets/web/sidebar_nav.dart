import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Web Sidebar Navigation - Exact replica of React web sidebar
/// 320px width sidebar with logo and navigation menu
class WebSidebarNavigation extends StatefulWidget {
  final String currentRoute;
  final VoidCallback? onRouteChange;

  const WebSidebarNavigation({
    super.key,
    required this.currentRoute,
    this.onRouteChange,
  });

  @override
  State<WebSidebarNavigation> createState() => _WebSidebarNavigationState();
}

class _WebSidebarNavigationState extends State<WebSidebarNavigation> {
  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.home, label: 'Home', route: '/'),
    NavigationItem(icon: Icons.calendar_today, label: 'Meetings', route: '/meetings'),
    NavigationItem(icon: Icons.explore, label: 'Discover', route: '/discover'),
    NavigationItem(icon: Icons.book, label: 'Bible Stories', route: '/bible-stories'),
    NavigationItem(icon: Icons.headphones, label: 'Podcasts', route: '/podcasts'),
    NavigationItem(icon: Icons.music_note, label: 'Music', route: '/music'),
    NavigationItem(icon: Icons.radio, label: 'Live', route: '/live'),
    NavigationItem(icon: Icons.star, label: 'Favorites', route: '/favorites'),
    NavigationItem(icon: Icons.videocam, label: 'Create', route: '/create'),
    NavigationItem(icon: Icons.format_quote, label: 'Quote', route: '/quote'),
    NavigationItem(icon: Icons.broadcast_on_personal, label: 'Stream', route: '/stream'),
    NavigationItem(icon: Icons.download, label: 'Downloads', route: '/download-manager'),
    NavigationItem(icon: Icons.library_music, label: 'Library', route: '/library'),
    NavigationItem(icon: Icons.notifications, label: 'Notifications', route: '/notification-settings'),
    NavigationItem(icon: Icons.people, label: 'Community', route: '/community'),
    NavigationItem(icon: Icons.favorite, label: 'Prayer', route: '/prayer'),
    NavigationItem(icon: Icons.person, label: 'My Profile', route: '/profile'),
    NavigationItem(icon: Icons.shield, label: 'Admin Dashboard', route: '/admin'),
    NavigationItem(icon: Icons.info, label: 'About', route: '/about'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo section
          Padding(
            padding: EdgeInsets.all(AppSpacing.large * 1.5),
            child: GestureDetector(
              onTap: () {
                // Navigate to home
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Christ New Tabernacle',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primaryMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Christian Podcast Platform',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              children: _navigationItems.map((item) {
                final isActive = widget.currentRoute == item.route;
                return _buildNavItem(item, isActive);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, bool isActive) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color: isActive ? AppColors.warmBrown : Colors.transparent,
        borderRadius: BorderRadius.circular(999), // Pill shape
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isActive ? Colors.white : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (widget.onRouteChange != null) {
            widget.onRouteChange!();
          }
          // Navigate to route
        },
      ),
    );
  }
}

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

