import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/livekit_meeting_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/section_container.dart';
import '../meeting/prejoin_screen.dart';

/// Live Stream Setup Screen
/// Allows users to configure stream details before going live
class LiveStreamSetupScreen extends StatefulWidget {
  const LiveStreamSetupScreen({super.key});

  @override
  State<LiveStreamSetupScreen> createState() => _LiveStreamSetupScreenState();
}

class _LiveStreamSetupScreenState extends State<LiveStreamSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startStreamNow() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?['name'] as String? ?? 'Host';
      
      final apiService = ApiService();
      final streamResp = await apiService.createStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      final streamId = (streamResp['id'] ?? '').toString();
      final identity = 'host-${DateTime.now().millisecondsSinceEpoch}';

      final meetingSvc = LiveKitMeetingService();
      final joinResp = await meetingSvc.fetchTokenForMeeting(
        streamOrMeetingId: int.parse(streamId),
        userIdentity: identity,
        userName: userName,
        isHost: true,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrejoinScreen(
            meetingId: streamId,
            jitsiUrl: joinResp.url,
            jwtToken: joinResp.token,
            roomName: joinResp.roomName,
            userName: userName,
            isHost: true,
            initialCameraEnabled: true,
            initialMicEnabled: true,
            isLiveStream: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start stream: ${e.toString()}'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _startInstant() async {
    _titleController.text = 'Live Stream - ${DateTime.now().toString().substring(0, 16)}';
    await _startStreamNow();
  }

  @override
  Widget build(BuildContext context) {
    // Check for web platform
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Mobile breakpoint

    if (isMobile) {
       return _buildMobileLayout(context);
    } else {
       return _buildDesktopSplitLayout(context);
    }
  }

  Widget _buildDesktopSplitLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Row(
        children: [
          // Left Side: Content (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.backgroundPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Back Button
                   SafeArea(
                     child: Align(
                       alignment: Alignment.topLeft,
                       child: TextButton.icon(
                         onPressed: () => Navigator.pop(context),
                         icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                         label: Text('Back', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                         style: TextButton.styleFrom(padding: EdgeInsets.zero),
                       ),
                     ),
                   ),
                   const Spacer(),
                   
                   // Title & Description
                   Text(
                     'Go Live',
                     style: AppTypography.heading1.copyWith(
                       color: AppColors.textPrimary,
                       fontSize: 48,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: AppSpacing.medium),
                   Text(
                     'Share your message with the community',
                     style: AppTypography.body.copyWith(
                       color: AppColors.textSecondary,
                       fontSize: 18,
                     ),
                   ),
                   const SizedBox(height: 32),

                   // Stream Form - directly embedded in the left column
                   // Note: We don't use the card container here to keep it clean on the white background
                   Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
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
                            child: const Icon(Icons.live_tv, size: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Center(
                          child: Text(
                            'Stream Details',
                            style: AppTypography.heading4.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title Field
                        Text(
                          'Stream Title *',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Enter a title for your live stream',
                              hintStyle: TextStyle(color: AppColors.textTertiary),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a stream title';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description Field
                        Text(
                          'Description (Optional)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Add a description for your stream',
                              hintStyle: TextStyle(color: AppColors.textTertiary),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Actions
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
                              onTap: _isCreating ? null : _startStreamNow,
                              borderRadius: BorderRadius.circular(30),
                              child: Center(
                                child: _isCreating
                                    ? SizedBox(
                                        width: 24, height: 24,
                                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2),
                                      )
                                    : Text(
                                        'Start Live Stream',
                                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _isCreating ? null : _startInstant,
                            icon: Icon(Icons.flash_on, color: AppColors.warmBrown, size: 20),
                            label: Text('Quick Start', style: TextStyle(color: AppColors.warmBrown, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Quick Start generates a default title automatically',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                   ),

                   const Spacer(),
                ],
              ),
            ),
          ),
          
          // Right Side: Image + Tips Overlay (60%)
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/jesus-walking.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                  ),
                ),
                
                // Tips removed as per user request
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
             // Mobile Background logic...
             Positioned(
              top: -30,
              right: -MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 1.3,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/thumb6.jpg'),
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),
             // Gradient
             Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.98),
                            const Color(0xFFF5F0E8).withOpacity(0.85),
                            const Color(0xFFF5F0E8).withOpacity(0.4),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8],
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.large,
                    right: AppSpacing.large,
                    top: 20,
                    bottom: AppSpacing.extraLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Go Live',
                              style: AppTypography.heading2.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.small),
                      Text(
                        'Share your message with the community',
                        style: AppTypography.body.copyWith(color: AppColors.primaryDark.withOpacity(0.7)),
                      ),
                      SizedBox(height: 32),
                      
                      _buildStreamFormCard(),
                      const SizedBox(height: 24),
                      // Tips removed as per user request
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method so I don't break existing reference
  Widget _buildDesktopLayout() { 
    // This is now redundant with _buildDesktopSplitLayout but kept if something references it (unlikely)
    return Container(); 
  }

  Widget _buildStreamTipsCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown.withOpacity(0.15), AppColors.accentMain.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tips_and_updates, color: AppColors.warmBrown),
              ),
              const SizedBox(width: 12),
              Text('Tips for a Great Stream', style: AppTypography.heading4.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem(Icons.lightbulb_outline, 'Good Lighting', 'Position yourself facing a light source for clear visibility.'),
          _buildTipItem(Icons.mic_outlined, 'Clear Audio', 'Use a quiet environment and speak clearly.'),
          _buildTipItem(Icons.wifi, 'Stable Internet', 'A strong connection ensures smooth streaming.'),
          _buildTipItem(Icons.camera_alt_outlined, 'Frame Yourself', 'Keep your face centered and well-framed.'),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.warmBrown, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamFormCard() {
    return Container(
      padding: EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Center(
              child: Container(
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
                child: const Icon(Icons.live_tv, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            
            Center(
              child: Text(
                'Stream Details',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stream Title Label
            Text(
              'Stream Title *',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _titleController,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter a title for your live stream',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a stream title';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            // Description Label
            Text(
              'Description (Optional)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.borderPrimary,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add a description for your stream',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Start Stream Button - Pill shaped with gradient
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
                  onTap: _isCreating ? null : _startStreamNow,
                  borderRadius: BorderRadius.circular(30),
                  child: Center(
                    child: _isCreating
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
                              Icon(Icons.videocam, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Start Live Stream',
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
            const SizedBox(height: 16),

            // Instant Start Button - Outlined pill
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.warmBrown, width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCreating ? null : _startInstant,
                  borderRadius: BorderRadius.circular(30),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on, color: AppColors.warmBrown, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Quick Start',
                          style: TextStyle(
                            color: AppColors.warmBrown,
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
            const SizedBox(height: 12),

            // Help text
            Text(
              'Quick Start generates a default title automatically',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
