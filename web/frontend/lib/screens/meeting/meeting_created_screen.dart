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
      // Web version with web design system
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            // Background image with low opacity overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/jesus-walking.png'),
                    fit: BoxFit.cover,
                    opacity: 0.05,
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
                              onPressed: _handleBack,
                            ),
                            Expanded(
                              child: StyledPageHeader(
                                title: 'Meeting Created',
                                size: StyledPageHeaderSize.h2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Meeting Details Section
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            children: [
                              // Meeting Icon
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
                                  Icons.video_call,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Meeting Title
                              Text(
                                widget.isInstant ? 'Instant Meeting' : 'Scheduled Meeting',
                                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.small),

                              // Meeting ID
                              Text(
                                'Meeting ID: ${widget.meetingId}',
                                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Meeting Link with brown border accent
                              Container(
                                padding: EdgeInsets.all(AppSpacing.medium),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                  border: Border.all(
                                    color: AppColors.warmBrown,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
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
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.warmBrown,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isCopied ? Icons.check : Icons.copy,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _handleCopyLink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Share Section with brown-themed gradient cards
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Meeting',
                                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.medium),

                              // Share Options Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: AppSpacing.medium,
                                mainAxisSpacing: AppSpacing.medium,
                                childAspectRatio: 2.5,
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
                                  _buildShareOption(
                                    icon: Icons.message,
                                    label: 'SMS',
                                    color: const Color(0xFF34A853),
                                    onTap: _handleShare,
                                  ),
                                  _buildShareOption(
                                    icon: Icons.more_horiz,
                                    label: 'More',
                                    color: AppColors.warmBrown,
                                    onTap: _handleShare,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Join Meeting Button - proper pill button size
                        StyledPillButton(
                          label: _joining ? 'Joining...' : 'Join Meeting',
                          icon: Icons.video_call,
                          onPressed: _joining ? null : _handleJoinMeeting,
                          isLoading: _joining,
                          width: double.infinity,
                        ),
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

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    if (kIsWeb) {
      // Web version - used in GridView with brown-themed gradient
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.tiny),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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

