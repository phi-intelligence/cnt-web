import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
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
      String errorMessage;
      bool isAuthError = false;
      
      // Check if it's an authentication error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('session has expired') || 
          errorString.contains('authentication failed') ||
          errorString.contains('please log in again') ||
          errorString.contains('unauthorized')) {
        errorMessage = 'Your session has expired. Please log in again to join the meeting.';
        isAuthError = true;
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      setState(() { 
        _joining = false; 
        _joinError = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: isAuthError ? Colors.red : null,
            duration: Duration(seconds: isAuthError ? 5 : 3),
            action: isAuthError ? SnackBarAction(
              label: 'Go to Login',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ) : null,
          ),
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

    if (kIsWeb) {
      // Web version with web design system
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            // Background decoration with theme colors
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warmBrown.withOpacity(0.03),
                      AppColors.accentMain.withOpacity(0.02),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 600, // Reduced width for centered content
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                              onPressed: _handleBack,
                            ),
                            Expanded(
                              child: StyledPageHeader(
                                title: 'Join Meeting',
                                size: StyledPageHeaderSize.h2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Join Form Section with landing page styling
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            children: [
                              // Join Icon with gradient
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.warmBrown,
                                      AppColors.accentMain,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.warmBrown.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.login,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              Text(
                                'Enter Meeting Details',
                                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.small),
                              Text(
                                'Enter the meeting ID or paste the meeting link to join',
                                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.extraLarge),

                              // Meeting ID Input - centered and reduced width
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildTextField(
                                    label: 'Meeting ID',
                                    controller: _meetingIdController,
                                    hint: 'Enter meeting ID',
                                  ),
                                ),
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

                              // Meeting Link Input - centered and reduced width
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildTextField(
                                    label: 'Meeting Link',
                                    controller: _meetingLinkController,
                                    hint: 'Paste meeting link here',
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Scan QR Code Button - outlined pill design
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.warmBrown,
                                      width: 2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _handleScanQR,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_scanner, color: AppColors.warmBrown, size: 20),
                                          const SizedBox(width: AppSpacing.small),
                                          Text(
                                            'Scan QR Code',
                                            style: AppTypography.button.copyWith(
                                              color: AppColors.warmBrown,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Join Meeting Button
                        StyledPillButton(
                          label: 'Join Meeting',
                          icon: Icons.login,
                          onPressed: canJoin && !_joining ? _handleJoinMeeting : null,
                          isLoading: _joining,
                          width: double.infinity,
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                    borderRadius: BorderRadius.circular(30),
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
                    onPressed: canJoin && !_joining ? _handleJoinMeeting : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _joining
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
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
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

