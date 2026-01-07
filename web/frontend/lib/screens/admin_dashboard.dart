import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/platform_helper.dart';
import '../utils/responsive_utils.dart';
import '../widgets/web/styled_pill_button.dart';
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
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _navItems[_currentIndex].label,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textInverse,
            fontSize: isSmallMobile ? 18 : null,
          ),
        ),
        backgroundColor: AppColors.warmBrown,
        foregroundColor: AppColors.textInverse,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, size: isSmallMobile ? 20 : 24),
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
            height: isSmallMobile ? 60 : 70,
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
      final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
      final iconSize = isSmallMobile ? 18.0 : AppSpacing.iconSizeMedium;
      final fontSize = isSmallMobile ? 10.0 : null;
      
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          // Ensure minimum touch target size (44x44)
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isSmallMobile ? 8 : 10,
              horizontal: 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive
                      ? AppColors.primaryMain
                      : AppColors.textSecondary,
                  size: iconSize,
                ),
                SizedBox(height: isSmallMobile ? AppSpacing.tiny * 0.5 : AppSpacing.tiny),
                Text(
                  item.label,
                  style: AppTypography.caption.copyWith(
                    color: isActive
                        ? AppColors.primaryMain
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: fontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getPageHorizontalPadding(context),
          vertical: ResponsiveUtils.getPageVerticalPadding(context),
        ),
        contentPadding: EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
        ),
        titlePadding: EdgeInsets.fromLTRB(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.small),
        ),
        actionsPadding: EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(context, AppSpacing.large),
        ),
        title: Text(
          'Logout',
          style: AppTypography.heading3.copyWith(
            fontSize: isSmallMobile ? 18 : null,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.body.copyWith(
            fontSize: isSmallMobile ? 13 : null,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        actions: [
          if (isMobile)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: double.infinity,
                ),
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                StyledPillButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: double.infinity,
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StyledPillButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context, false),
                  variant: StyledPillButtonVariant.outlined,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 100.0,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                StyledPillButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  onPressed: () => Navigator.pop(context, true),
                  variant: StyledPillButtonVariant.filled,
                  width: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 100.0,
                    tablet: 120.0,
                    desktop: 100.0,
                  ),
                ),
              ],
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
