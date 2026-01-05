import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../services/livekit_meeting_service.dart';
import '../../widgets/meeting/video_track_view.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Live Stream Broadcaster Screen - Go live and broadcast using LiveKit
class LiveStreamBroadcaster extends StatefulWidget {
  final String token;
  final String serverUrl;
  final String streamTitle;
  final String roomName;
  final VoidCallback? onStreamEnded;

  const LiveStreamBroadcaster({
    super.key,
    required this.token,
    required this.serverUrl,
    required this.streamTitle,
    required this.roomName,
    this.onStreamEnded,
  });

  @override
  State<LiveStreamBroadcaster> createState() => _LiveStreamBroadcasterState();
}

class _LiveStreamBroadcasterState extends State<LiveStreamBroadcaster> {
  final LiveKitMeetingService _meetingService = LiveKitMeetingService();
  bool _isStreaming = false;
  bool _isMuted = false;
  bool _isCameraOn = true;
  lk.LocalVideoTrack? _localVideoTrack;
  int _viewerCount = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  Future<void> _startStreaming() async {
    try {
      setState(() {
        _isStreaming = true;
        _startTime = DateTime.now();
      });

      // Join LiveKit room
      await _meetingService.joinMeeting(
        roomName: widget.roomName,
        jwtToken: widget.token,
        displayName: widget.streamTitle,
        audioMuted: false,
        videoMuted: false,
        wsUrl: widget.serverUrl,
      );

      // Create and publish local video track
      final room = _meetingService.currentRoom;
      if (room?.localParticipant != null) {
        final localVideo = await lk.LocalVideoTrack.createCameraTrack();
        await room!.localParticipant!.publishVideoTrack(localVideo);
        setState(() {
          _localVideoTrack = localVideo;
          _isCameraOn = true;
        });
      }

      // Listen for participant count updates
      _updateViewerCount();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _startTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start streaming: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopStreaming() async {
    try {
      if (_localVideoTrack != null) {
        // Stop the track - room cleanup will handle unpublishing
        await _localVideoTrack!.stop();
        _localVideoTrack = null;
      }
      await _meetingService.leaveMeeting();

      if (mounted) {
        setState(() {
          _isStreaming = false;
          _startTime = null;
        });

        if (widget.onStreamEnded != null) {
          widget.onStreamEnded!();
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error stopping stream: $e');
    }
  }

  Future<bool> _showLeaveConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Leave Stream?'),
        content: const Text('Are you sure you want to leave this stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _toggleMute() async {
    try {
      await _meetingService.toggleMicrophone();
      setState(() {
        _isMuted = !_meetingService.isMicrophoneEnabled();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle microphone: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _toggleCamera() async {
    try {
      await _meetingService.toggleCamera();
      final isEnabled = _meetingService.isCameraEnabled();

      if (!isEnabled && _localVideoTrack != null) {
        // Camera turned off, stop track
        await _localVideoTrack!.stop();
        _localVideoTrack = null;
      } else if (isEnabled && _localVideoTrack == null) {
        // Camera turned on, create and publish track
        final localVideo = await lk.LocalVideoTrack.createCameraTrack();
        final room = _meetingService.currentRoom;
        if (room?.localParticipant != null) {
          await room!.localParticipant!.publishVideoTrack(localVideo);
          setState(() {
            _localVideoTrack = localVideo;
          });
        }
      }

      setState(() {
        _isCameraOn = isEnabled;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle camera: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _updateViewerCount() {
    if (_isStreaming) {
      final count = _meetingService.getParticipantCount();
      setState(() {
        _viewerCount = count > 0 ? count - 1 : 0; // Subtract 1 for broadcaster
      });
      Future.delayed(const Duration(seconds: 5), _updateViewerCount);
    }
  }

  String _getStreamingDuration() {
    if (_startTime == null) return '00:00';
    final duration = DateTime.now().difference(_startTime!);
    final mins = duration.inMinutes.toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _meetingService.leaveMeeting();
    _localVideoTrack?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = _meetingService.currentRoom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showLeaveConfirmation();
        if (shouldLeave && mounted) {
          await _stopStreaming();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          // Video preview
          if (_localVideoTrack != null && _isCameraOn)
            VideoTrackView(
                track: _localVideoTrack!, isLocal: true, mirror: false)
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white70, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Camera is off',
                      style: AppTypography.body.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

          // Top bar with streaming info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: kIsWeb ? AppSpacing.medium : 0,
                left: kIsWeb
                    ? ResponsiveGridDelegate.getResponsivePadding(context)
                        .horizontal
                    : AppSpacing.medium,
                right: kIsWeb
                    ? ResponsiveGridDelegate.getResponsivePadding(context)
                        .horizontal
                    : AppSpacing.medium,
                bottom: AppSpacing.medium,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
              ),
              child: Row(
                children: [
                  if (_isStreaming) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                        vertical: AppSpacing.tiny,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_viewerCount',
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Text(
                      _getStreamingDuration(),
                      style: AppTypography.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        widget.streamTitle,
                        style: AppTypography.body.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    onPressed: _stopStreaming,
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: kIsWeb
                    ? ResponsiveGridDelegate.getResponsivePadding(context)
                        .horizontal
                    : AppSpacing.large,
                right: kIsWeb
                    ? ResponsiveGridDelegate.getResponsivePadding(context)
                        .horizontal
                    : AppSpacing.large,
                top: AppSpacing.large,
                bottom: kIsWeb ? AppSpacing.large : 0,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle camera
                  IconButton(
                    icon:
                        Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                    iconSize: 32,
                    color: Colors.white,
                    onPressed: _toggleCamera,
                  ),

                  // Start/Stop streaming
                  _isStreaming
                      ? ElevatedButton(
                          onPressed: _stopStreaming,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            'End Stream',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _startStreaming,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            'Go Live',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                  // Toggle mute
                  IconButton(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    iconSize: 32,
                    color: _isMuted ? Colors.red : Colors.white,
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
