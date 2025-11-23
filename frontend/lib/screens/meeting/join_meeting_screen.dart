import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'meeting_room_screen.dart';
import '../../services/livekit_meeting_service.dart';
import 'prejoin_screen.dart';

/// Join Meeting Screen
/// Enter meeting ID or link to join
class JoinMeetingScreen extends StatefulWidget {
  const JoinMeetingScreen({super.key});

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  final TextEditingController _meetingIdController = TextEditingController();
  final TextEditingController _meetingLinkController = TextEditingController();
  bool _joining = false;
  String? _joinError;

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleJoinMeeting() async {
    if (_meetingIdController.text.trim().isEmpty && _meetingLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting ID or link')),
      );
      return;
    }
    String meetingId = _meetingIdController.text.trim();
    String meetingLink = _meetingLinkController.text.trim();
    String? roomNameFromLink;
    
    // Extract room name from link if link is provided (and ID is empty for clarity)
    if (meetingLink.isNotEmpty) {
      final uri = Uri.tryParse(meetingLink);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        roomNameFromLink = uri.pathSegments.last;
      } else {
        // Try simple split as fallback
      final urlParts = meetingLink.split('/');
        roomNameFromLink = urlParts.isNotEmpty && urlParts.last.isNotEmpty ? urlParts.last : null;
      }
    }
    
    setState(() { _joining = true; _joinError = null; });
    try {
      final identity = 'guest-user-${DateTime.now().millisecondsSinceEpoch}';
      final userName = 'Guest User';
      final meetingSvc = LiveKitMeetingService();
      
      // Determine join method:
      // 1. If link provided with valid room name, use room-based join
      // 2. If numeric ID provided (and no link), use ID-based join
      // 3. If non-numeric ID (room name), use room-based join
      final meetingIdInt = int.tryParse(meetingId);
      final bool useRoomJoin = (roomNameFromLink != null && roomNameFromLink.isNotEmpty) || 
                               (meetingId.isNotEmpty && meetingIdInt == null);
      
      if (!useRoomJoin && (meetingIdInt == null || meetingIdInt <= 0)) {
        throw Exception('Invalid meeting ID: $meetingId');
      }
      
      final joinResp = useRoomJoin
          ? await meetingSvc.fetchTokenForMeetingByRoom(
              roomName: roomNameFromLink ?? meetingId,
              userIdentity: identity,
              userName: userName,
              isHost: false,
            )
          : await meetingSvc.fetchTokenForMeeting(
              streamOrMeetingId: meetingIdInt!,
              userIdentity: identity,
              userName: userName,
              isHost: false,
            );
      setState(() { _joining = false; });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrejoinScreen(
            meetingId: meetingId,
            jitsiUrl: joinResp.url, // Contains LiveKit URL from backend
            jwtToken: joinResp.token,
            roomName: joinResp.roomName,
            userName: userName,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      setState(() { _joining = false; _joinError = e.toString(); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join meeting: $e')),
        );
      }
    }
  }

  void _handleScanQR() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code scanning will be implemented soon!')),
    );
  }

  @override
  void dispose() {
    _meetingIdController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canJoin = _meetingIdController.text.trim().isNotEmpty ||
        _meetingLinkController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _handleBack,
        ),
        title: Text(
          'Join Meeting',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          const SizedBox(width: 40),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              // Join Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.login,
                  size: 48,
                  color: AppColors.primaryMain,
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              Text(
                'Enter Meeting Details',
                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                'Enter the meeting ID or paste the meeting link to join',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Meeting ID Input
              _buildTextField(
                label: 'Meeting ID',
                controller: _meetingIdController,
                hint: 'Enter meeting ID',
              ),
              const SizedBox(height: AppSpacing.large),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderPrimary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                    child: Text(
                      'OR',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.borderPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.large),

              // Meeting Link Input
              _buildTextField(
                label: 'Meeting Link',
                controller: _meetingLinkController,
                hint: 'Paste meeting link here',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Scan QR Code Button
              InkWell(
                onTap: _handleScanQR,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.primaryMain),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.primaryMain),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'Scan QR Code',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primaryMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Join Meeting Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canJoin ? _handleJoinMeeting : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login, color: Colors.white),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'Join Meeting',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.tiny),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.medium),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

