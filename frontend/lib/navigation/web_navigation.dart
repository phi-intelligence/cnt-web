import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../providers/auth_provider.dart';
import '../providers/support_provider.dart';
import '../widgets/notifications/stream_notification_banner.dart';
import '../screens/web/home_screen_web.dart';
import '../screens/web/podcasts_screen_web.dart';
import '../screens/web/movies_screen_web.dart';
import '../screens/web/create_screen_web.dart';
import '../screens/web/community_screen_web.dart';
import '../screens/web/profile_screen_web.dart';
import '../screens/admin_dashboard.dart';
import '../screens/web/about_screen_web.dart';
import '../screens/web/search_screen_web.dart';
import '../widgets/media/global_audio_player.dart';
import '../widgets/web/sidebar_action_box.dart';
import '../screens/live/live_stream_start_screen.dart';

class WebNavigationLayout extends StatefulWidget {
  final int? initialIndex;
  
  const WebNavigationLayout({super.key, this.initialIndex});

  @override
  State<WebNavigationLayout> createState() => _WebNavigationLayoutState();
}

class _WebNavigationLayoutState extends State<WebNavigationLayout> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
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
      NavigationItem(icon: Icons.search, label: 'Search', route: 'search'),
      NavigationItem(icon: Icons.video_library, label: 'Create', route: 'create'),
      NavigationItem(icon: Icons.people, label: 'Community', route: 'community'),
      NavigationItem(icon: Icons.mic, label: 'Podcasts', route: 'podcasts'),
      NavigationItem(icon: Icons.movie, label: 'Movies', route: 'movies'),
      NavigationItem(icon: Icons.info, label: 'About', route: 'about'),
    ];
    
    // Add My Profile at the end, before Admin Dashboard
    items.add(NavigationItem(icon: Icons.person, label: 'My Profile', route: 'profile'));
    
    // Only add Admin Dashboard if user is admin (after My Profile)
    if (isAdmin) {
      items.add(NavigationItem(icon: Icons.admin_panel_settings, label: 'Admin Dashboard', route: 'admin'));
    }
    
    return items;
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen(List<NavigationItem> navigationItems) {
    if (_selectedIndex >= navigationItems.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }
    
    final route = navigationItems[_selectedIndex].route;
    
    switch (route) {
      case 'home':
        return const HomeScreenWeb();
      case 'search':
        return const SearchScreenWeb();
      case 'create':
        return const CreateScreenWeb();
      case 'community':
        return const CommunityScreenWeb();
      case 'profile':
        return const ProfileScreenWeb();
      case 'podcasts':
        return const PodcastsScreenWeb();
      case 'movies':
        return const MoviesScreenWeb();
      case 'admin':
        return const AdminDashboardScreen();
      case 'about':
        return const AboutScreenWeb();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Page: ${navigationItems[_selectedIndex].label}',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon...',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final supportProvider = context.watch<SupportProvider>();
        final unreadAdmin = authProvider.isAdmin ? supportProvider.unreadAdminCount : 0;
        final navigationItems = _getNavigationItems(authProvider.isAdmin);
        
        // Ensure selected index is valid
        if (_selectedIndex >= navigationItems.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          });
        }
        
        return Scaffold(
          body: Column(
            children: [
              // Notification banner at top
              const StreamNotificationBanner(),
              // Rest of content
              Expanded(
                child: Row(
                children: [
                  // Sidebar Navigation
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardBackground,
                          AppColors.backgroundSecondary,
                        ],
                      ),
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
                          child: Row(
                            children: [
                              // Logo Image (same as login screen)
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
                                    'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.church,
                                        size: 32,
                                        color: Colors.white,
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
                              final isSelected = _selectedIndex == index;
                              
                              return _NavItemWidget(
                                item: item,
                                isSelected: isSelected,
                                unreadCount: authProvider.isAdmin &&
                                        item.route == 'profile' &&
                                        unreadAdmin > 0
                                    ? unreadAdmin
                                    : null,
                                onTap: () => _navigateToScreen(index),
                              );
                            },
                          ),
                        ),
                        // Sidebar Action Boxes (shown on all pages)
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
                              // Start Live Stream Box
                              SidebarActionBox(
                                title: 'Start Live Stream',
                                description: 'Broadcast to your community',
                                buttonText: 'Go Live',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LiveStreamStartScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              // Create Podcast Box
                              SidebarActionBox(
                                title: 'Create Podcast',
                                description: 'Share your message',
                                buttonText: 'Create Now',
                                onTap: () {
                                  _navigateToScreen(2); // Navigate to Create screen (index 2)
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Content Area
                  Expanded(
                    child: _buildCurrentScreen(navigationItems),
                  ),
                ],
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
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.15),
                      AppColors.accentMain.withOpacity(0.1),
                    ],
                  )
                : _isHovered
                    ? LinearGradient(
                        colors: [
                          AppColors.warmBrown.withOpacity(0.08),
                          AppColors.accentMain.withOpacity(0.05),
                        ],
                      )
                    : null,
            color: widget.isSelected || _isHovered
                ? null
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.1),
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
                  gradient: widget.isSelected
                      ? LinearGradient(
                          colors: [AppColors.warmBrown, AppColors.accentMain],
                        )
                      : _isHovered
                          ? LinearGradient(
                              colors: [
                                AppColors.warmBrown.withOpacity(0.2),
                                AppColors.accentMain.withOpacity(0.1),
                              ],
                            )
                          : null,
                  color: widget.isSelected || _isHovered
                      ? null
                      : AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: widget.isSelected
                      ? Border.all(
                          color: AppColors.warmBrown.withOpacity(0.3),
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
                        ? AppColors.warmBrown
                        : _isHovered
                            ? AppColors.textPrimary
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

