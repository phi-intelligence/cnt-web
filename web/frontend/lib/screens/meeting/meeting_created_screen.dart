import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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

/// Meeting Created Screen
/// Shows meeting details with share options and join button
class MeetingCreatedScreen extends StatefulWidget {
  final String meetingId;
  final String meetingLink;
  final bool isInstant;

  const MeetingCreatedScreen({
    super.key,
    required this.meetingId,
    required this.meetingLink,
    this.isInstant = true,
  });

  @override
  State<MeetingCreatedScreen> createState() => _MeetingCreatedScreenState();
}

class _MeetingCreatedScreenState extends State<MeetingCreatedScreen> {
  bool _isCopied = false;
  bool _joining = false;
  String? _joinError;

  void _handleBack() {
    Navigator.pop(context);
  }

  Future<void> _handleJoinMeeting() async {
    setState(() { _joining = true; _joinError = null; });
    try {
      // Validate meetingId is a valid numeric ID from backend
      final meetingIdInt = int.tryParse(widget.meetingId);
      if (meetingIdInt == null || meetingIdInt <= 0) {
        throw Exception('Invalid meeting ID: ${widget.meetingId}');
      }
      
      final identity = 'host-user-${DateTime.now().millisecondsSinceEpoch}';
      final userName = 'Host';
      final meetingSvc = LiveKitMeetingService();
      final joinResp = await meetingSvc.fetchTokenForMeeting(
        streamOrMeetingId: meetingIdInt,
        userIdentity: identity,
        userName: userName,
        isHost: true,
      );
      setState(() { _joining = false; });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrejoinScreen(
            meetingId: widget.meetingId,
            jitsiUrl: joinResp.url, // Contains LiveKit URL from backend
            jwtToken: joinResp.token,
            roomName: joinResp.roomName,
            userName: userName,
            isHost: true,
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

  void _handleCopyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.meetingLink));
    setState(() {
      _isCopied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard!')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing meeting link...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;
      final isTablet = screenWidth >= 600 && screenWidth < 1024;
      
      // Web version with background image pattern
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: SizedBox(
          width: double.infinity,
          height: screenHeight,
          child: Stack(
            children: [
              // Background image positioned to the right
              Positioned(
                top: isMobile ? -30 : 0,
                bottom: isMobile ? null : 0,
                right: isMobile ? -screenWidth * 0.4 : -50,
                height: isMobile ? screenHeight * 0.6 : null,
                width: isMobile ? screenWidth * 1.3 : screenWidth * 0.65,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/images/thumbnail1.jpg'),
                      fit: isMobile ? BoxFit.contain : BoxFit.cover,
                      alignment: isMobile ? Alignment.topRight : Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Gradient overlay from left
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isMobile
                          ? [
                              const Color(0xFFF5F0E8),
                              const Color(0xFFF5F0E8).withOpacity(0.98),
                              const Color(0xFFF5F0E8).withOpacity(0.85),
                              const Color(0xFFF5F0E8).withOpacity(0.4),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFF5F0E8),
                              const Color(0xFFF5F0E8).withOpacity(0.99),
                              const Color(0xFFF5F0E8).withOpacity(0.95),
                              const Color(0xFFF5F0E8).withOpacity(0.7),
                              const Color(0xFFF5F0E8).withOpacity(0.3),
                              Colors.transparent,
                            ],
                      stops: isMobile
                          ? const [0.0, 0.2, 0.4, 0.6, 0.8]
                          : const [0.0, 0.25, 0.4, 0.5, 0.6, 0.75],
                    ),
                  ),
                ),
              ),
              // Content positioned centered/right-aligned
              Positioned(
                left: isMobile ? 0 : (screenWidth * 0.15),
                top: 0,
                bottom: 0,
                right: 0,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                      right: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                      top: isMobile ? 20 : 40,
                      bottom: AppSpacing.extraLarge,
                    ),
                    child: isMobile
                        ? _buildMobileLayout(true)
                        : _buildDesktopLayout(),
                  ),
                ),
              ),
            ],
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
            onPressed: _handleBack,
          ),
          title: Text(
            'Meeting Created',
            style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
          ),
          centerTitle: true,
          actions: [
            const SizedBox(width: 40), // Balance leading icon
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              children: [
                // Meeting Icon
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
                    Icons.video_call,
                    size: 48,
                    color: AppColors.primaryMain,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // Meeting Title
                Text(
                  widget.isInstant ? 'Instant Meeting' : 'Scheduled Meeting',
                  style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.tiny),

                // Meeting ID
                Text(
                  'Meeting ID: ${widget.meetingId}',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.large),

                // Meeting Link
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Link:',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.tiny),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.meetingLink,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.small),
                          IconButton(
                            icon: Icon(
                              _isCopied ? Icons.check : Icons.copy,
                              color: AppColors.primaryMain,
                            ),
                            onPressed: _handleCopyLink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Share Section
                Text(
                  'Share Meeting',
                  style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.medium),

                // Share Options Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: _handleShare,
                    ),
                    _buildShareOption(
                      icon: Icons.email,
                      label: 'Email',
                      color: const Color(0xFFEA4335),
                      onTap: _handleShare,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.message,
                      label: 'SMS',
                      color: const Color(0xFF34A853),
                      onTap: _handleShare,
                    ),
                    _buildShareOption(
                      icon: Icons.more_horiz,
                      label: 'More',
                      color: AppColors.textSecondary,
                      onTap: _handleShare,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.extraLarge),

                // Join Meeting Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joining ? null : _handleJoinMeeting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_call, color: Colors.white),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          _joining ? 'Joining...' : 'Join Meeting',
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

  // Desktop layout with side panel for meeting tips
  Widget _buildDesktopLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Meeting tips/info
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.warmBrown, AppColors.accentMain],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Decorative circles
                  Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 50,
                        top: 50,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates, size: 48, color: Colors.white),
                          const SizedBox(height: 20),
                          Text(
                            'Meeting Tips',
                            style: AppTypography.heading3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTipItem(Icons.mic_off, 'Mute when not speaking'),
                          _buildTipItem(Icons.video_camera_front, 'Ensure good lighting'),
                          _buildTipItem(Icons.wifi, 'Check your internet connection'),
                          _buildTipItem(Icons.headphones, 'Use headphones for better audio'),
                          _buildTipItem(Icons.share, 'Share link with participants'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Right side - Meeting details
          Expanded(
            flex: 5,
            child: _buildMeetingDetailsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Meeting details card - used in desktop right side and mobile
  Widget _buildMeetingDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown, AppColors.accentMain],
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
                child: const Icon(Icons.check, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Meeting Type
              Text(
                widget.isInstant ? 'Instant Meeting' : 'Scheduled Meeting',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Meeting ID Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'ID: ${widget.meetingId}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warmBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Meeting Link - Pill shaped
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: AppColors.warmBrown, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.meetingLink,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleCopyLink,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCopied ? Icons.check : Icons.copy,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isCopied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Share Section - Compact horizontal pills
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Meeting',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              
              // Share buttons in a row - compact pill style
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCompactShareButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _handleShare,
                  ),
                  _buildCompactShareButton(
                    icon: Icons.email,
                    label: 'Email',
                    color: const Color(0xFFEA4335),
                    onTap: _handleShare,
                  ),
                  _buildCompactShareButton(
                    icon: Icons.message,
                    label: 'SMS',
                    color: const Color(0xFF34A853),
                    onTap: _handleShare,
                  ),
                  _buildCompactShareButton(
                    icon: Icons.share,
                    label: 'More',
                    color: AppColors.warmBrown,
                    onTap: _handleShare,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Join Meeting Button - Pill shaped with gradient
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warmBrown, AppColors.accentMain],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _joining ? null : _handleJoinMeeting,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: _joining
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_call, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Join Meeting Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Mobile layout - for mobile only
  Widget _buildMobileLayout(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button row
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.warmBrown),
                onPressed: _handleBack,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Meeting Created',
                style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildMeetingDetailsCard(),
      ],
    );
  }

  // Compact pill-shaped share button for web
  Widget _buildCompactShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    if (kIsWeb) {
      // Web version - compact pill style
      return _buildCompactShareButton(
        icon: icon,
        label: label,
        color: color,
        onTap: onTap,
      );
    } else {
      // Mobile version
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: AppSpacing.tiny),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

