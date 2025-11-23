import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/web/sidebar_nav.dart';

/// Web Layout - Sidebar + Content Area
/// Matches React web app layout with 320px sidebar
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Row(
        children: [
          // Sidebar Navigation (320px width, always visible on desktop)
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

