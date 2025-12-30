import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/platform_helper.dart';
import '../utils/responsive_utils.dart';
import 'user_login_screen.dart';
import 'web/landing_screen_web.dart';
import 'admin/admin_dashboard_page.dart';
import 'admin/admin_pending_page.dart';
import 'admin/admin_approved_page.dart';
import 'admin/admin_users_page.dart';
import '../widgets/admin/admin_web_layout.dart';

/// Main Admin Dashboard Screen with navigation
/// Navigation: Dashboard, Pending, Approved, Users
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  int _pendingTabIndex = 0;
  int _approvedTabIndex = 0;

  void _navigateToPage(int pageIndex, {int tabIndex = 0}) {
    setState(() {
      _currentIndex = pageIndex;
      if (pageIndex == 1) _pendingTabIndex = tabIndex;
      if (pageIndex == 2) _approvedTabIndex = tabIndex;
    });
  }

  List<Widget> get _pages => [
    AdminDashboardPage(
      onNavigateToPage: _navigateToPage,
    ),
    AdminPendingPage(initialTabIndex: _pendingTabIndex),
    AdminApprovedPage(initialTabIndex: _approvedTabIndex),
    const AdminUsersPage(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    NavigationItem(
      icon: Icons.pending_actions_outlined,
      activeIcon: Icons.pending_actions,
      label: 'Pending',
    ),
    NavigationItem(
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle,
      label: 'Approved',
    ),
    NavigationItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Users',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveUtils to determine layout instead of PlatformHelper
    // This enables the mobile layout on small screens even on web
    final isMobile = ResponsiveUtils.isMobile(context);

    if (!isMobile) {
      return _buildWebLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildWebLayout() {
    return AdminWebLayout(
      currentIndex: _currentIndex,
      navItems: _navItems,
      onNavigate: _navigateToPage,
      onLogout: () async {
        await _handleLogout();
      },
      child: _pages[_currentIndex],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _navItems[_currentIndex].label,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        backgroundColor: AppColors.warmBrown,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(
              color: AppColors.borderPrimary,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildNavItem(i, isWeb: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, {required bool isWeb}) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    if (isWeb) {
      return InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.tiny,
          ),
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryMain.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: isActive
                ? Border.all(
                    color: AppColors.primaryMain,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive
                    ? AppColors.primaryMain
                    : AppColors.textSecondary,
                size: AppSpacing.iconSizeMedium,
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: isActive
                      ? AppColors.primaryMain
                      : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive
                    ? AppColors.primaryMain
                    : AppColors.textSecondary,
                size: AppSpacing.iconSizeMedium,
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                item.label,
                style: AppTypography.caption.copyWith(
                  color: isActive
                      ? AppColors.primaryMain
                      : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTypography.heading3,
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorMain,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        final isWeb = PlatformHelper.isWebPlatform();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => isWeb 
                ? const LandingScreenWeb()
                : const UserLoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
