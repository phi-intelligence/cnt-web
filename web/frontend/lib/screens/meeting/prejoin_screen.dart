import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_pill_button.dart';
import 'meeting_room_screen.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/media_utils.dart';
import '../../utils/web_video_recorder.dart';
import '../../utils/platform_view_registry_helper.dart';
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;

/// Prejoin Screen - Device check before joining meeting
/// Allows user to toggle camera/mic before joining
class PrejoinScreen extends StatefulWidget {
  final String meetingId;
  final String
      jitsiUrl; // Keep name for compatibility, but will contain LiveKit URL
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

  // Camera preview state
  WebVideoRecorder? _cameraRecorder;
  html.VideoElement? _videoElement;
  String? _videoElementViewId;
  bool _isInitializingCamera = false;
  String? _cameraError;
  bool _actualCameraEnabled = false;

  @override
  void initState() {
    super.initState();
    cameraEnabled = widget.initialCameraEnabled;
    micEnabled = widget.initialMicEnabled;

    // Initialize camera if enabled on web
    if (kIsWeb && widget.initialCameraEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCamera();
      });
    }

    // Request microphone permission if enabled on web
    if (kIsWeb && widget.initialMicEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestMicrophonePermission();
      });
    }
  }

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
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
            wsUrl: widget
                .jitsiUrl, // Use jitsiUrl as wsUrl (it will be LiveKit URL from backend)
            initialCameraEnabled: cameraEnabled,
            initialMicEnabled: micEnabled,
            avatarUrl: avatarUrl,
            isLiveStream: widget.isLiveStream,
          ),
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    if (!kIsWeb) return;

    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      _cameraRecorder = WebVideoRecorder();

      // Check permissions first
      final hasPermission = await _cameraRecorder!.hasPermission();
      if (!hasPermission) {
        setState(() {
          _cameraError =
              'Camera permission denied. Please allow camera access in your browser settings.';
          _isInitializingCamera = false;
          _actualCameraEnabled = false;
          cameraEnabled = false;
        });
        return;
      }

      // Initialize camera
      _videoElement = await _cameraRecorder!.initializeCamera();

      // Register video element for HtmlElementView
      _videoElementViewId =
          'prejoin-camera-${DateTime.now().millisecondsSinceEpoch}';
      platformViewRegistry.registerViewFactory(
        _videoElementViewId!,
        (int viewId) => _videoElement!,
      );

      setState(() {
        _isInitializingCamera = false;
        _actualCameraEnabled = true;
      });
    } catch (e) {
      print('❌ Error initializing camera: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      setState(() {
        _cameraError = errorMsg.isNotEmpty
            ? errorMsg
            : 'Failed to initialize camera. Please check your browser settings.';
        _isInitializingCamera = false;
        _actualCameraEnabled = false;
        cameraEnabled = false;
      });
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraRecorder != null) {
      await _cameraRecorder!.dispose();
      _cameraRecorder = null;
      _videoElement = null;
      _videoElementViewId = null;
    }

    if (mounted) {
      setState(() {
        _actualCameraEnabled = false;
      });
    }
  }

  Future<void> _onCameraToggle(bool enabled) async {
    setState(() {
      cameraEnabled = enabled;
    });

    if (enabled) {
      await _initializeCamera();
    } else {
      await _disposeCamera();
    }
  }

  Future<void> _requestMicrophonePermission() async {
    if (!kIsWeb) return;

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices != null) {
        // Request microphone permission
        final stream = await mediaDevices.getUserMedia({'audio': true});
        // Stop the test stream immediately
        stream.getTracks().forEach((track) => track.stop());
      }
    } catch (e) {
      print('❌ Microphone permission error: $e');
      if (mounted) {
        setState(() {
          micEnabled = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Microphone permission denied. Please allow microphone access in your browser settings.'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _onMicrophoneToggle(bool enabled) async {
    setState(() {
      micEnabled = enabled;
    });

    if (enabled && kIsWeb) {
      await _requestMicrophonePermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with register page design pattern
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;
      final isTablet = screenWidth >= 600 && screenWidth < 1024;

      return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      resizeToAvoidBottomInset: false,
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
                      image: const AssetImage('assets/images/jesus.png'),
                      fit: isMobile ? BoxFit.contain : BoxFit.cover,
                      alignment:
                          isMobile ? Alignment.topRight : Alignment.centerRight,
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
                      left: isMobile
                          ? AppSpacing.large
                          : AppSpacing.extraLarge * 2,
                      right: isMobile
                          ? AppSpacing.large
                          : AppSpacing.extraLarge * 3,
                      top: isMobile ? 20 : 40,
                      bottom: AppSpacing.extraLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: AppColors.primaryDark),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Check Your Setup',
                                style: AppTypography.getResponsiveHeroTitle(
                                        context)
                                    .copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      isMobile ? 28 : (isTablet ? 36 : 42),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.small),
                        Text(
                          'Configure your camera and microphone before joining',
                          style:
                              AppTypography.getResponsiveBody(context).copyWith(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: AppSpacing.extraLarge * 1.5),

                        // Preview Section - Pill-shaped container
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 500.0),
                          padding: EdgeInsets.all(
                              isMobile ? AppSpacing.medium : AppSpacing.large),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(isMobile ? 20 : 30),
                            border: Border.all(
                              color: AppColors.warmBrown.withOpacity(0.2),
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
                          child: Column(
                            children: [
                              // Preview with actual camera feed or placeholder
                              Container(
                                height: isMobile ? 200 : 300,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.warmBrown.withOpacity(0.2),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: _videoElementViewId != null &&
                                          _actualCameraEnabled
                                      ? AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: HtmlElementView(
                                              viewType: _videoElementViewId!),
                                        )
                                      : _isInitializingCamera
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.warmBrown,
                                              ),
                                            )
                                          : Container(
                                              alignment: Alignment.center,
                                              child: _cameraError != null
                                                  ? Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.error_outline,
                                                          size: 60,
                                                          color: AppColors
                                                              .errorMain,
                                                        ),
                                                        SizedBox(
                                                            height: AppSpacing
                                                                .medium),
                                                        Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      AppSpacing
                                                                          .large),
                                                          child: Text(
                                                            _cameraError!,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: AppTypography
                                                                .bodySmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .errorMain,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Icon(
                                                      cameraEnabled
                                                          ? Icons.videocam
                                                          : Icons.videocam_off,
                                                      size: 80,
                                                      color: cameraEnabled
                                                          ? AppColors.warmBrown
                                                          : AppColors
                                                              .textSecondary,
                                                    ),
                                            ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.large),
                              Text(
                                'Room: ${widget.roomName}',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.large),

                        // Device Settings Section
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 500.0),
                          padding: EdgeInsets.all(
                              isMobile ? AppSpacing.medium : AppSpacing.large),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(isMobile ? 20 : 30),
                            border: Border.all(
                              color: AppColors.warmBrown.withOpacity(0.2),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Device Settings',
                                style: AppTypography.heading4.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 18 : null,
                                ),
                              ),
                              SizedBox(
                                  height: isMobile
                                      ? AppSpacing.medium
                                      : AppSpacing.large),
                              // Device Controls Grid
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final isMobile = screenWidth < 768;

                                  if (isMobile) {
                                    // Mobile: Stack vertically with full width
                                    return Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: _buildDeviceControlCard(
                                            icon: cameraEnabled
                                                ? Icons.videocam
                                                : Icons.videocam_off,
                                            title: 'Camera',
                                            subtitle:
                                                cameraEnabled ? 'On' : 'Off',
                                            enabled: cameraEnabled,
                                            onChanged: _onCameraToggle,
                                            isMobile: true,
                                          ),
                                        ),
                                        SizedBox(height: AppSpacing.medium),
                                        SizedBox(
                                          width: double.infinity,
                                          child: _buildDeviceControlCard(
                                            icon: micEnabled
                                                ? Icons.mic
                                                : Icons.mic_off,
                                            title: 'Microphone',
                                            subtitle: micEnabled ? 'On' : 'Off',
                                            enabled: micEnabled,
                                            onChanged: _onMicrophoneToggle,
                                            isMobile: true,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Desktop: Side by side
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildDeviceControlCard(
                                            icon: cameraEnabled
                                                ? Icons.videocam
                                                : Icons.videocam_off,
                                            title: 'Camera',
                                            subtitle:
                                                cameraEnabled ? 'On' : 'Off',
                                            enabled: cameraEnabled,
                                            onChanged: _onCameraToggle,
                                            isMobile: false,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.large),
                                        Expanded(
                                          child: _buildDeviceControlCard(
                                            icon: micEnabled
                                                ? Icons.mic
                                                : Icons.mic_off,
                                            title: 'Microphone',
                                            subtitle: micEnabled ? 'On' : 'Off',
                                            enabled: micEnabled,
                                            onChanged: _onMicrophoneToggle,
                                            isMobile: false,
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
                        SizedBox(height: AppSpacing.extraLarge),

                        // Join button
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 500.0),
                          child: StyledPillButton(
                            label: 'Join Meeting',
                            icon: Icons.meeting_room,
                            onPressed: _onJoin,
                            width: double.infinity,
                          ),
                        ),
                        SizedBox(height: AppSpacing.extraLarge),
                      ],
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
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Check Your Setup',
            style:
                AppTypography.heading3.copyWith(color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.extraLarge),
              // Preview with actual camera feed or placeholder
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _videoElementViewId != null && _actualCameraEnabled
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child:
                              HtmlElementView(viewType: _videoElementViewId!),
                        )
                      : _isInitializingCamera
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryMain,
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: _cameraError != null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 60,
                                          color: AppColors.errorMain,
                                        ),
                                        SizedBox(height: AppSpacing.medium),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.large),
                                          child: Text(
                                            _cameraError!,
                                            textAlign: TextAlign.center,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.errorMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Icon(
                                      cameraEnabled
                                          ? Icons.videocam
                                          : Icons.videocam_off,
                                      size: 80,
                                      color: cameraEnabled
                                          ? AppColors.primaryMain
                                          : AppColors.textSecondary,
                                    ),
                            ),
                ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              Text(
                'Room: ${widget.roomName}',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Camera toggle
              ListTile(
                leading: Icon(
                  cameraEnabled ? Icons.videocam : Icons.videocam_off,
                  color: cameraEnabled
                      ? AppColors.primaryMain
                      : AppColors.textSecondary,
                ),
                title: Text(
                  cameraEnabled ? 'Camera On' : 'Camera Off',
                  style:
                      AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                trailing: Switch(
                  value: cameraEnabled,
                  onChanged: _onCameraToggle,
                ),
              ),
              // Microphone toggle
              ListTile(
                leading: Icon(
                  micEnabled ? Icons.mic : Icons.mic_off,
                  color: micEnabled
                      ? AppColors.primaryMain
                      : AppColors.textSecondary,
                ),
                title: Text(
                  micEnabled ? 'Microphone On' : 'Microphone Off',
                  style:
                      AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
                trailing: Switch(
                  value: micEnabled,
                  onChanged: _onMicrophoneToggle,
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
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                  onPressed: _onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.large),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLarge),
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
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
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
        color: enabled ? null : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
        border: Border.all(
          color: enabled
              ? AppColors.warmBrown.withOpacity(0.3)
              : AppColors.warmBrown.withOpacity(0.2),
          width: enabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
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
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppSpacing.medium),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.heading4.copyWith(
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: AppSpacing.tiny),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: enabled
                                ? AppColors.warmBrown
                                : AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                  activeColor: AppColors.warmBrown,
                ),
              ],
            )
          : Column(
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
                    color:
                        enabled ? AppColors.warmBrown : AppColors.textSecondary,
                    size: 30,
                  ),
                ),
                SizedBox(height: AppSpacing.medium),
                Text(
                  title,
                  style: AppTypography.heading4.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.small),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        enabled ? AppColors.warmBrown : AppColors.textTertiary,
                  ),
                ),
                SizedBox(height: AppSpacing.medium),
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
