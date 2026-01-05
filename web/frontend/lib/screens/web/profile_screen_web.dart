import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_provider.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_grid_delegate.dart';

import '../../providers/artist_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/notification_provider.dart';
import 'landing_screen_web.dart';
import 'library_screen_web.dart';
import '../support/support_center_screen.dart';
import '../admin/admin_support_page.dart';
import '../edit_profile_screen.dart';
import '../../utils/media_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/bank_details_helper.dart';

/// Web Profile Screen - Complete Redesign
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
      context.read<ArtistProvider>().fetchMyArtist();
      context.read<PlaylistProvider>().fetchPlaylists();
      context.read<NotificationProvider>().fetchUnreadCount();
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
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.extraLarge,
                  0,
                  AppSpacing.extraLarge,
                  AppSpacing.extraLarge,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/CNT-LOGO.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/cnt-dove-logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.church,
                                  size: 40,
                                  color: Colors.white,
                                );
                              },
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
                    Text(
                      '© 2024 Christ New Tabernacle',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
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
    if (_isUploadingAvatar) return;
    
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentAvatar = authProvider.user?['avatar'] ?? userProvider.user?['avatar'];
    final hasAvatar = currentAvatar != null && currentAvatar.toString().isNotEmpty;
    
    // Show options dialog if user has an avatar
    if (hasAvatar) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Upload New Photo'),
                onTap: () => Navigator.pop(context, 'upload'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (action == 'remove') {
        await _handleRemoveAvatar();
        return;
      } else if (action != 'upload') {
        return; // User cancelled
      }
    }
    
    // Continue with upload logic
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

      final newUrl = await userProvider.uploadAvatar(
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );

      if (newUrl != null && mounted) {
        await authProvider.updateCachedUser({'avatar': newUrl});
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

  Future<void> _handleRemoveAvatar() async {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    
    setState(() {
      _isUploadingAvatar = true;
    });
    
    try {
      final success = await userProvider.removeAvatar();
      if (success && mounted) {
        await authProvider.updateCachedUser({'avatar': null});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove avatar: ${userProvider.error ?? 'Unknown error'}'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove avatar: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
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
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        width: double.infinity,
        child: Consumer3<AuthProvider, UserProvider, SupportProvider>(
          builder: (context, authProvider, userProvider, supportProvider, child) {
            final profileUser = userProvider.user ?? authProvider.user;
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use two-column layout on desktop, stacked on mobile
                  if (isMobile || constraints.maxWidth < 900) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Profile Card
                        _buildProfileCard(
                          context,
                          profileUser,
                          avatarUrl,
                          isAdmin,
                          isMobile,
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Donate Button
                        _buildDonateButton(isMobile),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Support Button
                        _buildSupportButton(
                          context,
                          isAdmin,
                          supportSubtitle,
                          unreadSupportCount,
                          isMobile,
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // User Details Box
                        _buildUserDetailsBox(profileUser, isAdmin),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Settings Section
                        _buildSettingsSection(
                          context,
                          authProvider,
                          supportProvider,
                          isAdmin,
                          isMobile,
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Artist Section
                        _buildArtistSection(context, isMobile),
                        const SizedBox(height: AppSpacing.extraLarge),
                        // Playlists Section
                        _buildPlaylistsSection(context, isMobile),
                        const SizedBox(height: AppSpacing.extraLarge),
                      ],
                    );
                  } else {
                    // Two-column layout for desktop
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - User Profile
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                          // User Profile Box - shifted to left
                                _buildProfileCard(
                                  context,
                                  profileUser,
                                  avatarUrl,
                                  isAdmin,
                                  isMobile,
                                ),
                                const SizedBox(height: AppSpacing.extraLarge),
                                // Donate Button
                                _buildDonateButton(isMobile),
                                const SizedBox(height: AppSpacing.extraLarge),
                                // Support Button
                                _buildSupportButton(
                                  context, 
                                  isAdmin, 
                                  supportSubtitle, 
                                  unreadSupportCount,
                                  isMobile,
                                ),
                                const SizedBox(height: AppSpacing.extraLarge),
                                // User Details Box
                                _buildUserDetailsBox(profileUser, isAdmin),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.extraLarge),
                          // Right Column - Artist Profile and Settings
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Artist Profile Section
                                _buildArtistSection(context, isMobile),
                                const SizedBox(height: AppSpacing.extraLarge),
                                // Playlists Section
                                _buildPlaylistsSection(context, isMobile),
                                const SizedBox(height: AppSpacing.extraLarge),
                                // Settings Section - below Artist Profile
                                _buildSettingsSection(
                                  context,
                                  authProvider,
                                  supportProvider,
                                  isAdmin,
                                  isMobile,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    Map<String, dynamic>? profileUser,
    String? avatarUrl,
    bool isAdmin,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : (isMobile ? AppSpacing.large : AppSpacing.extraLarge)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with camera button - centered in its own row
          Center(
            child: Stack(
              children: [
              Container(
                width: ResponsiveUtils.isSmallMobile(context) ? 90 : 120,
                height: ResponsiveUtils.isSmallMobile(context) ? 90 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.warmBrown, AppColors.warmBrown.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: ResponsiveUtils.isSmallMobile(context) ? 45 : 60,
                              color: Colors.white,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _handleAvatarChange,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _isUploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.errorMain,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          
          // Name with admin badge - left aligned
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  profileUser?['name'] ?? 'Guest User',
                  style: AppTypography.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: AppSpacing.small),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorMain,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Email - left aligned
          Text(
            profileUser?['email'] ?? '',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.start,
          ),
          
          // Member since - left aligned
          if (profileUser?['created_at'] != null) ...[
            const SizedBox(height: AppSpacing.tiny),
            Text(
              'Member since ${_formatMemberSince(profileUser!['created_at'])}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserDetailsBox(Map<String, dynamic>? profileUser, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                'User Details',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.extraLarge),
          
          // Username/Name
          _buildDetailRow(
            icon: Icons.person,
            label: 'Name',
            value: profileUser?['name'] ?? 'Guest User',
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildDivider(),
          const SizedBox(height: AppSpacing.medium),
          
          // Email
          _buildDetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profileUser?['email'] ?? 'Not provided',
          ),
          const SizedBox(height: AppSpacing.medium),
          _buildDivider(),
          const SizedBox(height: AppSpacing.medium),
          
          // Username (if available)
          if (profileUser?['username'] != null) ...[
            _buildDetailRow(
              icon: Icons.alternate_email,
              label: 'Username',
              value: profileUser!['username'],
            ),
            const SizedBox(height: AppSpacing.medium),
            _buildDivider(),
            const SizedBox(height: AppSpacing.medium),
          ],
          
          // Member since
          if (profileUser?['created_at'] != null) ...[
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: _formatMemberSince(profileUser!['created_at']),
            ),
            const SizedBox(height: AppSpacing.medium),
            _buildDivider(),
            const SizedBox(height: AppSpacing.medium),
          ],
          
          // Admin badge (if admin)
          if (isAdmin)
            Container(
              padding: EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.errorMain.withOpacity(0.1),
                    AppColors.errorMain.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.errorMain.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: AppColors.errorMain,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    'Administrator Account',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.errorMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warmBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.warmBrown,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtistSection(BuildContext context, bool isMobile) {
    return Consumer<ArtistProvider>(
      builder: (context, artistProvider, child) {
        final artist = artistProvider.myArtist;
        final isLoading = artistProvider.myArtistLoading;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : (isMobile ? AppSpacing.large : AppSpacing.extraLarge)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Artist Profile',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          artist != null ? 'Manage your content and followers' : 'Share your creativity',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                    ),
                  ),
                )
              else if (artist != null)
                Column(
                  children: [
                    // Stats row - Round brown buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatButton(
                            'Followers',
                            artist.followersCount.toString(),
                            Icons.people,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: _buildStatButton(
                            'Total Plays',
                            artist.totalPlays.toString(),
                            Icons.play_circle_filled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Action buttons
                    // Action buttons
                    if (ResponsiveUtils.isSmallMobile(context))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildActionButton(
                            'Manage Profile',
                            Icons.edit,
                            true,
                            () => context.go('/artist/manage'),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          _buildActionButton(
                            'View Public',
                            Icons.visibility,
                            false,
                            () => context.go('/artist/${artist.id}'),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Manage Profile',
                              Icons.edit,
                              true,
                              () => context.go('/artist/manage'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: _buildActionButton(
                              'View Public',
                              Icons.visibility,
                              false,
                              () => context.go('/artist/${artist.id}'),
                            ),
                          ),
                        ],
                      ),
                  ],
                )
              else
                // Become a Creator card
                GestureDetector(
                  onTap: () => context.go('/artist/manage'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warmBrown.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.star,
                            color: AppColors.warmBrown,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Become a Creator',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Create your artist profile and showcase your work',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.warmBrown,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatButton(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.large, horizontal: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: AppSpacing.small),
          Text(
            value,
            style: AppTypography.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium, horizontal: AppSpacing.medium),
        decoration: BoxDecoration(
          color: filled ? AppColors.warmBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.warmBrown,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : AppColors.warmBrown,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                label,
                style: AppTypography.button.copyWith(
                  color: filled ? Colors.white : AppColors.warmBrown,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    AuthProvider authProvider,
    SupportProvider supportProvider,
    bool isAdmin,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Text(
                  'Settings',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings items
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((_) {
                context.read<UserProvider>().fetchUser();
              });
            },
          ),
          _buildDivider(),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return _buildSettingItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'View your notifications',
                badge: notificationProvider.unreadCount > 0
                    ? '${notificationProvider.unreadCount > 99 ? '99+' : notificationProvider.unreadCount}'
                    : null,
                onTap: () {
                  context.push('/notifications');
                },
              );
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.account_balance_outlined,
            title: 'Bank Details',
            subtitle: 'Manage payment information',
            onTap: () {
              context.push('/profile/bank-details');
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => _showCustomAboutDialog(context),
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Logout',
            isDestructive: true,
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
          SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.medium),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? AppColors.errorMain : AppColors.warmBrown;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.extraLarge,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: isDestructive ? AppColors.errorMain : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorMain,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.small),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.extraLarge),
      child: Divider(height: 1, color: AppColors.borderPrimary),
    );
  }

  Widget _buildDonateButton(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: AppColors.primaryMain,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showOrganizationDonationModal(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.medium),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Support Christ New Tabernacle',
                        style: AppTypography.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.tiny),
                      Text(
                        'Help us continue our mission',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportButton(
    BuildContext context,
    bool isAdmin,
    String supportSubtitle,
    int unreadSupportCount,
    bool isMobile,
  ) {
    return Consumer<SupportProvider>(
      builder: (context, supportProvider, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.warmBrown, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
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
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isAdmin ? Icons.support_agent : Icons.help_outline,
                          color: AppColors.warmBrown,
                          size: 28,
                        ),
                        if (unreadSupportCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.errorMain,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                unreadSupportCount > 99 ? '99+' : unreadSupportCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAdmin ? 'Support Inbox' : 'Help & Support',
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.tiny),
                          Text(
                            supportSubtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warmBrown.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsSection(BuildContext context, bool isMobile) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlists = playlistProvider.playlists;
        final playlistCount = playlists.length;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.warmBrown, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibraryScreenWeb(),
                  ),
                ).then((_) {
                  playlistProvider.fetchPlaylists();
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.playlist_play,
                          color: AppColors.warmBrown,
                          size: 28,
                        ),
                        if (playlistCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMain,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                playlistCount > 99 ? '99+' : playlistCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My Playlists',
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.tiny),
                          Text(
                            'Manage your saved playlists',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warmBrown.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
