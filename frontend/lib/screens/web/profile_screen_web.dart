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
import '../../utils/dimension_utils.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_page_header.dart';
import 'user_login_screen_web.dart';
import 'landing_screen_web.dart';
import '../support/support_center_screen.dart';
import '../admin/admin_support_page.dart';
import '../../utils/media_utils.dart';

/// Web Profile Screen - Adapted from mobile
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
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
                      // Profile Header (matching homepage theme)
                      SectionContainer(
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.warmBrown.withOpacity(0.3),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
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
                                                  size: 60,
                                                  color: AppColors.warmBrown,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: AppColors.backgroundTertiary,
                                            child: Icon(
                                              Icons.person,
                                              size: 60,
                                              color: AppColors.warmBrown,
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.warmBrown,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.backgroundSecondary,
                                        width: 3,
                                      ),
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
                                      padding: EdgeInsets.all(AppSpacing.small),
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
                                        color: AppColors.errorMain,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.backgroundSecondary,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.extraLarge),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
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
                                            color: AppColors.errorMain,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    profileUser?['email'] ?? '',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Stats Cards (matching homepage theme)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Minutes',
                              stats?['total_minutes']?.toString() ?? '0',
                              Icons.timer,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: _buildStatCard(
                              'Songs',
                              stats?['songs_played']?.toString() ?? '0',
                              Icons.music_note,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: _buildStatCard(
                              'Streak',
                              '${stats?['streak_days'] ?? 0}',
                              Icons.local_fire_department,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Settings Header (matching homepage theme)
                      StyledPageHeader(
                        title: 'Settings',
                        size: StyledPageHeaderSize.h2,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: ResponsiveGridDelegate.getGridColumns(
                          context,
                          desktop: 3,
                          tablet: 2,
                          mobile: 1,
                        ),
                        crossAxisSpacing: AppSpacing.medium,
                        mainAxisSpacing: AppSpacing.medium,
                        childAspectRatio: 2.5,
                        children: [
                          _buildSettingTile(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit profile coming soon')),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: isAdmin ? Icons.support_agent : Icons.help_outline,
                            title: isAdmin ? 'Support Inbox' : 'Help & Support',
                            subtitle: supportSubtitle,
                            trailing: _buildSupportTrailingBadge(unreadSupportCount),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      isAdmin ? const AdminSupportPage() : const SupportCenterScreen(),
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
                          _buildSettingTile(
                            icon: Icons.info_outline,
                            title: 'About',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: 'CNT Media Platform',
                                applicationVersion: '1.0.0',
                                applicationLegalese: '© 2024 Christ New Tabernacle',
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.logout,
                            title: 'Logout',
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
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return SectionContainer(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    String? subtitle,
    Widget? trailing,
  }) {
    return SectionContainer(
      padding: EdgeInsets.all(AppSpacing.medium),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.warmBrown).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.warmBrown,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      color: titleColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTrailingBadge(int unreadCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.errorMain,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              unreadCount.toString(),
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (unreadCount > 0) const SizedBox(width: 8),
        Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
      ],
    );
  }
}
