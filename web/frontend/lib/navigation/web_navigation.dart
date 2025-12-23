import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../widgets/notifications/stream_notification_banner.dart';
import '../widgets/media/global_audio_player.dart';
import '../screens/live/live_stream_start_screen.dart';
import '../utils/responsive_utils.dart';
import '../widgets/shared/responsive_drawer.dart' as drawer;
import '../widgets/shared/responsive_app_bar.dart';

class WebNavigationLayout extends StatefulWidget {
  final Widget child;
  final int? initialIndex;
  
  const WebNavigationLayout({
    super.key,
    required this.child,
    this.initialIndex,
  });

  @override
  State<WebNavigationLayout> createState() => _WebNavigationLayoutState();
}

class _WebNavigationLayoutState extends State<WebNavigationLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _getSelectedIndexFromRoute(String? location, List<NavigationItem> navigationItems) {
    if (location == null) return 0;
    
    // Extract the route from the location (remove leading slash)
    String route = location.substring(1).split('/').first;
    if (route.isEmpty) route = 'home'; // Default to home for root path
    
    // Map related routes to their parent navigation item
    // Artist routes should highlight "My Profile" in sidebar
    if (route == 'artist') {
      route = 'profile';
    }
    
    // Find the index by matching the route in the navigation items
    for (int i = 0; i < navigationItems.length; i++) {
      if (navigationItems[i].route == route) {
        return i;
      }
    }
    
    // If no match found, return initial index or 0
    return widget.initialIndex ?? 0;
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final supportProvider = context.read<SupportProvider>();
      supportProvider.fetchStats();
      if (authProvider.isAdmin) {
        supportProvider.fetchAdminMessages();
      } else {
        supportProvider.fetchMyMessages();
      }
    });
  }

  List<NavigationItem> _getNavigationItems(bool isAdmin) {
    final items = [
      NavigationItem(icon: Icons.home, label: 'Home', route: 'home'),
      NavigationItem(icon: Icons.video_library, label: 'Create', route: 'create'),
      NavigationItem(icon: Icons.people, label: 'Community', route: 'community'),
      NavigationItem(icon: Icons.mic, label: 'Podcasts', route: 'podcasts'),
      NavigationItem(icon: Icons.movie, label: 'Movies', route: 'movies'),
      NavigationItem(icon: Icons.person, label: 'My Profile', route: 'profile'),
    ];
    
    // Add Admin Dashboard if user is admin (after My Profile)
    if (isAdmin) {
      items.add(NavigationItem(icon: Icons.admin_panel_settings, label: 'Admin Dashboard', route: 'admin'));
    }
    
    // Add About last (after Admin Dashboard for admins, after My Profile for others)
    items.add(NavigationItem(icon: Icons.info, label: 'About', route: 'about'));
    
    return items;
  }

  void _navigateToScreen(int index, List<NavigationItem> navigationItems) {
    if (index >= navigationItems.length) return;
    final route = navigationItems[index].route;
    final routePath = '/$route';
    context.go(routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final supportProvider = context.watch<SupportProvider>();
        final unreadAdmin = authProvider.isAdmin ? supportProvider.unreadAdminCount : 0;
        final navigationItems = _getNavigationItems(authProvider.isAdmin);
        
        // Get current route from GoRouter
        final router = GoRouter.of(context);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        final selectedIndex = _getSelectedIndexFromRoute(currentLocation, navigationItems);
        
        // Ensure selected index is valid
        if (selectedIndex >= navigationItems.length && navigationItems.isNotEmpty) {
          // Default to home if invalid index
          return const SizedBox.shrink(); // Will redirect via GoRouter
        }

        // Check if we should use mobile/tablet layout (drawer) or desktop layout (sidebar)
        final bool useMobileLayout = ResponsiveUtils.isTabletOrSmaller(context);
        
        if (useMobileLayout) {
          // Mobile/Tablet Layout: AppBar + Drawer
          return Scaffold(
            key: _scaffoldKey,
            appBar: ResponsiveAppBar(
              showMenuButton: true,
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            drawer: drawer.ResponsiveDrawer(
              selectedIndex: selectedIndex,
              onItemSelected: (index) {
                _navigateToScreen(index, navigationItems);
                // Close drawer after selection
                Navigator.of(context).pop();
              },
            ),
            body: Column(
              children: [
                // Notification banner at top
                const StreamNotificationBanner(),
                // Main content
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: widget.child,
                  ),
                ),
                // Global Audio Player at bottom
                const GlobalAudioPlayer(),
              ],
            ),
          );
        }
        
        // Desktop Layout: Fixed Sidebar (original behavior)
        return Scaffold(
          body: Column(
            children: [
              // Notification banner at top
              const StreamNotificationBanner(),
              // Rest of content
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                children: [
                  // Sidebar Navigation
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: AppColors.borderPrimary,
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/jesus-carrying-cross.png'),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        opacity: 0.65,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.85),
                            Colors.white.withOpacity(0.75),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                      children: [
                        // App Logo/Title
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
                              
                              return _NavItemWidget(
                                item: item,
                                isSelected: isSelected,
                                unreadCount: authProvider.isAdmin &&
                                        item.route == 'profile' &&
                                        unreadAdmin > 0
                                    ? unreadAdmin
                                    : null,
                                onTap: () => _navigateToScreen(index, navigationItems),
                              );
                            },
                          ),
                        ),
                        // Sidebar Action Buttons (shown on all pages)
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
                          child: Column(
                            children: [
                              // Logo Circle - About Link
                              GestureDetector(
                                onTap: () => context.go('/about'),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                                    decoration: BoxDecoration(
                                      color: AppColors.warmBrown,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.warmBrown.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
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
                                                color: Colors.white,
                                                size: 40,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Start Live Stream Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.videocam, size: 18),
                                  label: Text('Start Live Stream'),
                                  onPressed: () {
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
                                    final authProvider = context.read<AuthProvider>();
                                    final navigationItems = _getNavigationItems(authProvider.isAdmin);
                                    _navigateToScreen(2, navigationItems); // Navigate to Create screen (index 2)
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
                      ],
                      ),
                    ),
                  ),
                  // Main Content Area
                  Expanded(
                    child: widget.child,
                  ),
                ],
                  ),
                ),
              ),
              // Global Audio Player at bottom
              const GlobalAudioPlayer(),
            ],
          ),
        );
      },
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

class _NavItemWidget extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final int? unreadCount;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    this.unreadCount,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> {
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

