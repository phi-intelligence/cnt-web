import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/admin_dashboard.dart'; // For NavigationItem and AdminDashboardScreen types if needed
import 'admin_sidebar_web.dart';

class AdminWebLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final List<NavigationItem> navItems;
  final Function(int) onNavigate;
  final VoidCallback onLogout;

  const AdminWebLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.navItems,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary, // Slightly darker background for the main area to make cards pop
      body: Row(
        children: [
          // Sidebar
          AdminSidebarWeb(
            currentIndex: currentIndex,
            navItems: navItems,
            onNavigate: onNavigate,
            onLogout: onLogout,
          ),
          
          // Main Content
          Expanded(
            child: Container(
              color: AppColors.backgroundPrimary,
              child: ClipRect(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
