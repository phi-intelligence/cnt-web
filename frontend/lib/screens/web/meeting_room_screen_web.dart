import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../meeting/meeting_room_screen.dart';

/// Web Meeting Room Screen
/// Wrapper for MeetingRoomScreen with web design system
class MeetingRoomScreenWeb extends StatelessWidget {
  final String meetingId;
  final String roomName;
  final String jwtToken;
  final String userName;
  final bool isHost;
  final String? wsUrl;
  final bool initialCameraEnabled;
  final bool initialMicEnabled;
  final String? avatarUrl;
  final bool isLiveStream;

  const MeetingRoomScreenWeb({
    super.key,
    required this.meetingId,
    required this.roomName,
    required this.jwtToken,
    required this.userName,
    this.isHost = false,
    this.wsUrl,
    this.initialCameraEnabled = true,
    this.initialMicEnabled = true,
    this.avatarUrl,
    this.isLiveStream = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use the actual MeetingRoomScreen which handles LiveKit integration
    // The MeetingRoomScreen already has proper UI, we just ensure it's wrapped
    // in the web design system if needed
    return MeetingRoomScreen(
      meetingId: meetingId,
      roomName: roomName,
      jwtToken: jwtToken,
      userName: userName,
      isHost: isHost,
      wsUrl: wsUrl,
      initialCameraEnabled: initialCameraEnabled,
      initialMicEnabled: initialMicEnabled,
      avatarUrl: avatarUrl,
      isLiveStream: isLiveStream,
    );
  }
}
