import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
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
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
    // For mobile and tablet, use drawer
    if (isMobile || isTablet) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            navItems[currentIndex].label,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textInverse,
              fontSize: isSmallMobile ? 18 : null,
            ),
          ),
          backgroundColor: AppColors.warmBrown,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, size: isSmallMobile ? 20 : 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        drawer: Drawer(
          width: ResponsiveUtils.getResponsiveValue(
            context: context,
            mobile: 280.0,
            tablet: 300.0,
            desktop: 280.0,
          ),
          child: AdminSidebarWeb(
            currentIndex: currentIndex,
            navItems: navItems,
            onNavigate: (index) {
              Navigator.pop(context); // Close drawer
              onNavigate(index);
            },
            onLogout: () {
              Navigator.pop(context); // Close drawer
              onLogout();
            },
          ),
        ),
        body: Container(
          color: AppColors.backgroundPrimary,
          child: ClipRect(
            child: child,
          ),
        ),
      );
    }
    
    // For desktop, use fixed sidebar
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
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
