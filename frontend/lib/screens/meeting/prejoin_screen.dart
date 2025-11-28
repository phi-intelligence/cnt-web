import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/livekit_meeting_service.dart';
import 'meeting_room_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/media_utils.dart';

/// Prejoin Screen - Device check before joining meeting
/// Allows user to toggle camera/mic before joining
class PrejoinScreen extends StatefulWidget {
  final String meetingId;
  final String jitsiUrl; // Keep name for compatibility, but will contain LiveKit URL
  final String jwtToken;
  final String roomName;
  final String userName;
  final bool isHost;
  final bool initialCameraEnabled;
  final bool initialMicEnabled;
  final bool isLiveStream;

  const PrejoinScreen({
    super.key,
    required this.meetingId,
    required this.jitsiUrl,
    required this.jwtToken,
    required this.roomName,
    required this.userName,
    this.isHost = false,
    this.initialCameraEnabled = true,
    this.initialMicEnabled = true,
    this.isLiveStream = false,
  });

  @override
  State<PrejoinScreen> createState() => _PrejoinScreenState();
}

class _PrejoinScreenState extends State<PrejoinScreen> {
  late bool cameraEnabled;
  late bool micEnabled;

  @override
  void initState() {
    super.initState();
    cameraEnabled = widget.initialCameraEnabled;
    micEnabled = widget.initialMicEnabled;
  }

  void _onJoin() {
    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();
    final profileUser = userProvider.user ?? authProvider.user;
    final avatarUrl = resolveMediaUrl(profileUser?['avatar'] as String?);

    // Navigate to LiveKit meeting room screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MeetingRoomScreen(
            meetingId: widget.meetingId,
            roomName: widget.roomName,
            jwtToken: widget.jwtToken,
            userName: widget.userName,
            isHost: widget.isHost,
            wsUrl: widget.jitsiUrl, // Use jitsiUrl as wsUrl (it will be LiveKit URL from backend)
            initialCameraEnabled: cameraEnabled,
            initialMicEnabled: micEnabled,
            avatarUrl: avatarUrl,
            isLiveStream: widget.isLiveStream,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with web design system
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: StyledPageHeader(
                          title: 'Check Your Setup',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Preview Section
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      children: [
                        // Preview placeholder
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          alignment: Alignment.center,
                          child: cameraEnabled
                              ? Icon(Icons.videocam, size: 80, color: AppColors.primaryMain)
                              : Icon(Icons.videocam_off, size: 80, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        Text(
                          'Room: ${widget.roomName}',
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // Device Settings Section
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Settings',
                          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        // Device Controls Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isMobile = screenWidth < 768;
                            
                            if (isMobile) {
                              // Mobile: Stack vertically
                              return Column(
                                children: [
                                  _buildDeviceControlCard(
                                    icon: cameraEnabled ? Icons.videocam : Icons.videocam_off,
                                    title: 'Camera',
                                    subtitle: cameraEnabled ? 'On' : 'Off',
                                    enabled: cameraEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        cameraEnabled = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  _buildDeviceControlCard(
                                    icon: micEnabled ? Icons.mic : Icons.mic_off,
                                    title: 'Microphone',
                                    subtitle: micEnabled ? 'On' : 'Off',
                                    enabled: micEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        micEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              );
                            } else {
                              // Desktop: Side by side
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildDeviceControlCard(
                                      icon: cameraEnabled ? Icons.videocam : Icons.videocam_off,
                                      title: 'Camera',
                                      subtitle: cameraEnabled ? 'On' : 'Off',
                                      enabled: cameraEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          cameraEnabled = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.large),
                                  Expanded(
                                    child: _buildDeviceControlCard(
                                      icon: micEnabled ? Icons.mic : Icons.mic_off,
                                      title: 'Microphone',
                                      subtitle: micEnabled ? 'On' : 'Off',
                                      enabled: micEnabled,
                                      onChanged: (value) {
                                        setState(() {
                                          micEnabled = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Join button
                  StyledPillButton(
                    label: 'Join Meeting',
                    icon: Icons.meeting_room,
                    onPressed: _onJoin,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Check Your Setup',
            style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.extraLarge),
              // Preview placeholder
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                alignment: Alignment.center,
                child: cameraEnabled
                    ? Icon(Icons.videocam, size: 80, color: AppColors.primaryMain)
                    : Icon(Icons.videocam_off, size: 80, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              Text(
                'Room: ${widget.roomName}',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Camera toggle
              ListTile(
                leading: Icon(
                  cameraEnabled ? Icons.videocam : Icons.videocam_off,
                  color: cameraEnabled ? AppColors.primaryMain : AppColors.textSecondary,
                ),
                title: Text(
                  cameraEnabled ? 'Camera On' : 'Camera Off',
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                trailing: Switch(
                  value: cameraEnabled,
                  onChanged: (value) {
                    setState(() {
                      cameraEnabled = value;
                    });
                  },
                ),
              ),
              // Microphone toggle
              ListTile(
                leading: Icon(
                  micEnabled ? Icons.mic : Icons.mic_off,
                  color: micEnabled ? AppColors.primaryMain : AppColors.textSecondary,
                ),
                title: Text(
                  micEnabled ? 'Microphone On' : 'Microphone Off',
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                trailing: Switch(
                  value: micEnabled,
                  onChanged: (value) {
                    setState(() {
                      micEnabled = value;
                    });
                  },
                ),
              ),
              const Spacer(),
              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.meeting_room, color: Colors.white),
                  label: const Text(
                    'Join Meeting',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onPressed: _onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDeviceControlCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warmBrown.withOpacity(0.1),
                  AppColors.accentMain.withOpacity(0.05),
                ],
              )
            : null,
        color: enabled ? null : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: enabled
              ? AppColors.warmBrown.withOpacity(0.3)
              : AppColors.borderPrimary,
          width: enabled ? 2 : 1,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.warmBrown.withOpacity(0.15)
                  : AppColors.backgroundSecondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? AppColors.warmBrown
                    : AppColors.borderPrimary,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? AppColors.warmBrown
                  : AppColors.textSecondary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            title,
            style: AppTypography.heading4.copyWith(
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: enabled
                  ? AppColors.warmBrown
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: AppColors.warmBrown,
          ),
        ],
      ),
    );
  }
}
