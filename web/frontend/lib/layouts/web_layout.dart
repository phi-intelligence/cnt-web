import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/web/sidebar_nav.dart';

/// Web Layout - Sidebar + Content Area
/// Responsive:
/// - Desktop (> 1024px): Persistent 320px Sidebar
/// - Mobile/Tablet (< 1024px): Hamburger menu + Drawer
class WebLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const WebLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktopOrLarger(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      // Only show AppBar on Mobile/Tablet to access Drawer
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.backgroundPrimary,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: const Text(
                'Christ New Tabernacle',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
      // Drawer for Mobile/Tablet
      drawer: isDesktop
          ? null
          : Drawer(
              width: 320,
              child: WebSidebarNavigation(
                currentRoute: currentRoute,
                onRouteChange: () {
                  // Close drawer when a route is selected
                  Navigator.of(context).pop();
                },
              ),
            ),
      body: Row(
        children: [
          // Sidebar Navigation (320px width, only visible on desktop)
          if (isDesktop)
            WebSidebarNavigation(
              currentRoute: currentRoute,
            ),
          
          // Content Area (rest of screen)
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Wrapper for web pages with layout
class WebPageWrapper extends StatelessWidget {
  final Widget page;
  final String route;

  const WebPageWrapper({
    super.key,
    required this.page,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      currentRoute: route,
      child: page,
    );
  }
}

