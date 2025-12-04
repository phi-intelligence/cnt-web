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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.warmBrown.withOpacity(0.03),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: AppColors.warmBrown),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Go Live',
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stream Setup Card
                    Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            TextFormField(
                              controller: _titleController,
                              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Enter a title for your live stream',
                                hintStyle: TextStyle(color: AppColors.textTertiary),
                                filled: true,
                                fillColor: AppColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: AppColors.borderPrimary),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: AppColors.borderPrimary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a stream title';
                                }
                                return null;
                              },
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
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Add a description for your stream',
                                hintStyle: TextStyle(color: AppColors.textTertiary),
                                filled: true,
                                fillColor: AppColors.backgroundSecondary,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: AppColors.borderPrimary),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: AppColors.borderPrimary),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ],
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
                        borderRadius: BorderRadius.circular(28),
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
                          borderRadius: BorderRadius.circular(28),
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
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.warmBrown, width: 2),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isCreating ? null : _startInstant,
                          borderRadius: BorderRadius.circular(28),
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

