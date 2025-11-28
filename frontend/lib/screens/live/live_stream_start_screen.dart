import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/livekit_meeting_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../meeting/prejoin_screen.dart';

/// Live Stream Start Screen
/// Immediately creates and starts a live stream
class LiveStreamStartScreen extends StatefulWidget {
  const LiveStreamStartScreen({super.key});

  @override
  State<LiveStreamStartScreen> createState() => _LiveStreamStartScreenState();
}

class _LiveStreamStartScreenState extends State<LiveStreamStartScreen> {
  bool _isCreating = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startLiveStream();
  }

  Future<void> _startLiveStream() async {
    try {
      setState(() {
        _isCreating = true;
        _errorMessage = null;
      });

      // Get current user info
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?['name'] as String? ?? 'Host';
      final userEmail = authProvider.user?['email'] as String? ?? '';

      // Create stream immediately
      final apiService = ApiService();
      final streamResp = await apiService.createStream(
        title: 'Live Stream - ${DateTime.now().toString().substring(0, 16)}',
      );

      final streamId = (streamResp['id'] ?? '').toString();
      final roomName = streamResp['room_name'] as String;

      if (streamId.isEmpty) {
        throw Exception('Failed to create stream: Invalid response');
      }

      // Generate identity for host
      final identity = 'host-${DateTime.now().millisecondsSinceEpoch}';

      // Get LiveKit token for host
      final meetingSvc = LiveKitMeetingService();
      final joinResp = await meetingSvc.fetchTokenForMeeting(
        streamOrMeetingId: int.parse(streamId),
        userIdentity: identity,
        userName: userName,
        isHost: true,
      );

      if (!mounted) return;

      // Navigate directly to prejoin screen, then to meeting room
      // Host will have mic and camera ON by default
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
            isLiveStream: true, // Mark as live stream
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        String errorMessage;
        bool isAuthError = false;
        
        // Check if it's an authentication error
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('session has expired') || 
            errorString.contains('authentication failed') ||
            errorString.contains('please log in again')) {
          errorMessage = 'Your session has expired. Please log in again to start a live stream.';
          isAuthError = true;
          
          // Auto-logout user
          final authProvider = context.read<AuthProvider>();
          if (authProvider.isAuthenticated) {
            await authProvider.logout();
          }
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        setState(() {
          _isCreating = false;
          _errorMessage = errorMessage;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorMain,
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

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with web design system
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
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
                      title: 'Live Stream',
                      size: StyledPageHeaderSize.h2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              // Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
                    ),
                    child: _isCreating
                  ? SectionContainer(
                      showShadow: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryMain,
                          ),
                          const SizedBox(height: AppSpacing.large),
                          Text(
                            'Starting Live Stream...',
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'Please wait',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SectionContainer(
                      showShadow: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.errorMain,
                          ),
                          const SizedBox(height: AppSpacing.large),
                          Text(
                            'Failed to Start Stream',
                            style: AppTypography.heading3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.medium),
                            Text(
                              _errorMessage!,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.extraLarge),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StyledPillButton(
                                label: 'Go Back',
                                icon: Icons.arrow_back,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              StyledPillButton(
                                label: 'Try Again',
                                icon: Icons.refresh,
                                onPressed: _startLiveStream,
                              ),
                            ],
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
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Center(
            child: _isCreating
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryMain,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        'Starting Live Stream...',
                        style: AppTypography.heading3,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Please wait',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        'Failed to Start Stream',
                        style: AppTypography.heading3,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.medium),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.extraLarge,
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.extraLarge),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMain,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.extraLarge,
                            vertical: AppSpacing.medium,
                          ),
                        ),
                        child: Text(
                          'Go Back',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      TextButton(
                        onPressed: _startLiveStream,
                        child: Text(
                          'Try Again',
                          style: AppTypography.button.copyWith(
                            color: AppColors.primaryMain,
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
}
