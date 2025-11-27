import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/section_container.dart';
import 'landing_screen_web.dart';
import '../support/support_center_screen.dart';
import '../admin/admin_support_page.dart';
import '../../utils/media_utils.dart';

/// Web Profile Screen - Redesigned
class ProfileScreenWeb extends StatefulWidget {
  const ProfileScreenWeb({super.key});

  @override
  State<ProfileScreenWeb> createState() => _ProfileScreenWebState();
}

class _ProfileScreenWebState extends State<ProfileScreenWeb> {
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().fetchUser();
      context.read<SupportProvider>().fetchStats();
    });
  }

  String _formatMemberSince(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return FormatUtils.formatRelativeTime(date);
    } catch (e) {
      return 'Recently';
    }
  }

  void _showCustomAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBackground,
                AppColors.backgroundSecondary,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.1),
                      AppColors.accentMain.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLarge),
                    topRight: Radius.circular(AppSpacing.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.warmBrown, AppColors.accentMain],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        'About',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.warmBrown, AppColors.accentMain],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        child: Image.asset(
                          'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.church,
                              size: 40,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'CNT Media Platform',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'A Christian Media Platform for Faith, Community, and Worship',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(
                          color: AppColors.warmBrown.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '© 2024 Christ New Tabernacle. All rights reserved.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAvatarChange() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final fileName = image.name;
      String? filePath;
      List<int>? bytes;

      if (kIsWeb) {
        bytes = await image.readAsBytes();
      } else {
        filePath = image.path;
      }

      final userProvider = context.read<UserProvider>();
      final newUrl = await userProvider.uploadAvatar(
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );

      if (newUrl != null && mounted) {
        await context.read<AuthProvider>().updateCachedUser({'avatar': newUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update avatar: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        width: double.infinity,
        child: Consumer3<AuthProvider, UserProvider, SupportProvider>(
          builder: (context, authProvider, userProvider, supportProvider, child) {
            final profileUser = userProvider.user ?? authProvider.user;
            final stats = userProvider.stats;
            final isAdmin = authProvider.isAdmin;
            final avatarUrl = resolveMediaUrl(profileUser?['avatar'] as String?);
            final supportStats = supportProvider.stats;
            final openSupportCount = supportStats?.openCount ?? 0;
            final unreadSupportCount = isAdmin
                ? supportProvider.unreadAdminCount
                : supportProvider.unreadUserCount;
            final supportSubtitle = isAdmin
                ? 'Open tickets: $openSupportCount • New: $unreadSupportCount'
                : 'Open requests: $openSupportCount • Responses: $unreadSupportCount';
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Section
                  _buildProfileHeader(
                    context,
                    profileUser,
                    avatarUrl,
                    isAdmin,
                    isMobile,
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Stats Section
                  _buildStatsSection(stats, isMobile),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Settings Section
                  _buildSettingsSection(
                    context,
                    authProvider,
                    supportProvider,
                    isAdmin,
                    supportSubtitle,
                    unreadSupportCount,
                    isMobile,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic>? profileUser,
    String? avatarUrl,
    bool isAdmin,
    bool isMobile,
  ) {
    return SectionContainer(
      showShadow: true,
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warmBrown.withOpacity(0.05),
              AppColors.accentMain.withOpacity(0.02),
              AppColors.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildAvatarSection(avatarUrl, isAdmin),
                  const SizedBox(height: AppSpacing.large),
                  _buildProfileInfo(profileUser, isAdmin),
                ],
              )
            : Row(
                children: [
                  _buildAvatarSection(avatarUrl, isAdmin),
                  const SizedBox(width: AppSpacing.extraLarge),
                  Expanded(child: _buildProfileInfo(profileUser, isAdmin)),
                ],
              ),
      ),
    );
  }

  Widget _buildAvatarSection(String? avatarUrl, bool isAdmin) {
    return Stack(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.warmBrown,
                AppColors.accentMain,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundTertiary,
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.backgroundTertiary,
                    child: Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.backgroundSecondary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isUploadingAvatar
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.white),
              onPressed: _isUploadingAvatar ? null : _handleAvatarChange,
              padding: const EdgeInsets.all(AppSpacing.small),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.errorMain, AppColors.errorMain.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundSecondary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorMain.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic>? profileUser, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                profileUser?['name'] ?? 'Guest User',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: AppSpacing.medium),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.errorMain, AppColors.errorMain.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.errorMain.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                profileUser?['email'] ?? '',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (profileUser?['created_at'] != null) ...[
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Member since ${_formatMemberSince(profileUser!['created_at'])}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection(Map<String, dynamic>? stats, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBrown.withOpacity(0.2),
                    AppColors.accentMain.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.bar_chart,
                color: AppColors.warmBrown,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              'Your Statistics',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        isMobile
            ? Column(
                children: [
                  _StatCard(
                    label: 'Minutes',
                    value: stats?['total_minutes']?.toString() ?? '0',
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _StatCard(
                    label: 'Songs',
                    value: stats?['songs_played']?.toString() ?? '0',
                    icon: Icons.music_note,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _StatCard(
                    label: 'Streak',
                    value: '${stats?['streak_days'] ?? 0}',
                    icon: Icons.local_fire_department,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Minutes',
                      value: stats?['total_minutes']?.toString() ?? '0',
                      icon: Icons.timer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: _StatCard(
                      label: 'Songs',
                      value: stats?['songs_played']?.toString() ?? '0',
                      icon: Icons.music_note,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '${stats?['streak_days'] ?? 0}',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    AuthProvider authProvider,
    SupportProvider supportProvider,
    bool isAdmin,
    String supportSubtitle,
    int unreadSupportCount,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentMain.withOpacity(0.2),
                    AppColors.warmBrown.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.accentMain.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings,
                color: AppColors.accentMain,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              'Settings',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        SectionContainer(
          showShadow: true,
          child: Column(
            children: [
              _SettingListItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile coming soon')),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.borderPrimary),
              _SettingListItem(
                icon: isAdmin ? Icons.support_agent : Icons.help_outline,
                title: isAdmin ? 'Support Inbox' : 'Help & Support',
                subtitle: supportSubtitle,
                trailing: unreadSupportCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorMain,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadSupportCount.toString(),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isAdmin
                          ? const AdminSupportPage()
                          : const SupportCenterScreen(),
                    ),
                  ).then((_) {
                    supportProvider.fetchStats();
                    if (isAdmin) {
                      supportProvider.fetchAdminMessages();
                    } else {
                      supportProvider.fetchMyMessages();
                    }
                  });
                },
              ),
              const Divider(height: 1, color: AppColors.borderPrimary),
              _SettingListItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  _showCustomAboutDialog(context);
                },
              ),
              const Divider(height: 1, color: AppColors.borderPrimary),
              _SettingListItem(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: AppColors.errorMain,
                titleColor: AppColors.errorMain,
                onTap: () async {
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LandingScreenWeb()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      showShadow: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackground,
              AppColors.backgroundSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBrown.withOpacity(0.2),
                    AppColors.accentMain.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 32, color: AppColors.warmBrown),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              value,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingListItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingListItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
    required this.onTap,
  });

  @override
  State<_SettingListItem> createState() => _SettingListItemState();
}

class _SettingListItemState extends State<_SettingListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
          color: _isHovered
              ? AppColors.warmBrown.withOpacity(0.05)
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: (widget.iconColor ?? AppColors.warmBrown).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor ?? AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.body.copyWith(
                        color: widget.titleColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: AppSpacing.small),
                widget.trailing!,
              ],
              const SizedBox(width: AppSpacing.small),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
