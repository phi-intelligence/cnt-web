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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryMain),
        title: Text(
          'Check Your Setup',
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 800,
            ),
            child: SingleChildScrollView(
              child: SectionContainer(
                showShadow: true,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'Room Details',
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Stream Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Stream Title *',
                            hintText: 'Enter a title for your live stream',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a stream title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Stream Description (optional)
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Add a description for your stream',
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.borderPrimary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Action Buttons Section
                        Text(
                          'Start Options',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Start Stream Now Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isCreating ? null : _startStreamNow,
                            icon: _isCreating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(Icons.videocam),
                            label: Text('Start Live Stream Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warmBrown,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Instant Start Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _isCreating ? null : _startInstant,
                            icon: Icon(Icons.flash_on),
                            label: Text('Start Instant Stream'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warmBrown,
                              side: BorderSide(color: AppColors.borderPrimary, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),

                        // Help text
                        Text(
                          'Instant stream generates a default title automatically',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

