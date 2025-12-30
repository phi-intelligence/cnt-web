import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../services/livekit_meeting_service.dart';
import '../../widgets/meeting/video_track_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';

/// Live Stream Viewer Screen - Watch live streams using LiveKit
class LiveStreamViewer extends StatefulWidget {
  final String streamId;
  final String roomName;
  final String streamTitle;
  final String token;
  final String serverUrl;
  final VoidCallback? onStreamEnded;

  const LiveStreamViewer({
    super.key,
    required this.streamId,
    required this.roomName,
    required this.streamTitle,
    required this.token,
    required this.serverUrl,
    this.onStreamEnded,
  });

  @override
  State<LiveStreamViewer> createState() => _LiveStreamViewerState();
}

class _LiveStreamViewerState extends State<LiveStreamViewer> {
  final LiveKitMeetingService _meetingService = LiveKitMeetingService();
  bool _isMuted = false;
  bool _isLoading = true;
  bool _isConnected = false;
  int _viewerCount = 0;
  lk.RemoteVideoTrack? _remoteVideoTrack;
  String? _broadcasterIdentity;

  @override
  void initState() {
    super.initState();
    _connectToStream();
  }

  Future<void> _connectToStream() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Join LiveKit room (viewer only, no camera/mic)
      await _meetingService.joinMeeting(
        roomName: widget.roomName,
        jwtToken: widget.token,
        displayName: 'Viewer',
        audioMuted: true,  // Viewer muted by default
        videoMuted: true,  // Viewer has no camera
        wsUrl: widget.serverUrl,
      );

      // Listen for remote video tracks
      final room = _meetingService.currentRoom;
      if (room != null) {
        _setupTrackListener(room);
        
        // Check for existing tracks
        _updateVideoTrack(room);
        
        // Update viewer count
        _updateViewerCount();
      }

      setState(() {
        _isLoading = false;
        _isConnected = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to stream: $e')),
        );
      }
    }
  }

  void _setupTrackListener(lk.Room room) {
    room.createListener().on<lk.TrackSubscribedEvent>((event) {
      // Check if this is from a remote participant (not local)
      final isRemoteParticipant = room.remoteParticipants.values
          .any((p) => p.trackPublications.values.any((pub) => pub.track == event.track));
      if (event.track.kind == lk.TrackType.VIDEO && isRemoteParticipant) {
        _updateVideoTrack(room);
      }
    });

    room.createListener().on<lk.TrackUnsubscribedEvent>((event) {
      if (event.track.kind == lk.TrackType.VIDEO) {
        _updateVideoTrack(room);
      }
    });

    room.createListener().on<lk.ParticipantConnectedEvent>((event) {
      // Check if this is a remote participant (not the local participant)
      final isRemoteParticipant = room.remoteParticipants.values
          .any((p) => p.identity == event.participant.identity);
      if (isRemoteParticipant) {
        _updateVideoTrack(room);
        _updateViewerCount();
      }
    });

    room.createListener().on<lk.ParticipantDisconnectedEvent>((event) {
      _updateVideoTrack(room);
      _updateViewerCount();
    });
  }

  void _updateVideoTrack(lk.Room room) {
    // Find broadcaster's video track (first remote participant with video)
    for (final participant in room.remoteParticipants.values) {
      final videoTracks = participant.trackPublications.values
          .where((pub) => pub.kind == lk.TrackType.VIDEO && pub.track != null && pub.subscribed && !pub.isScreenShare)
          .map((pub) => pub.track as lk.RemoteVideoTrack);
      
      if (videoTracks.isNotEmpty) {
        setState(() {
          _remoteVideoTrack = videoTracks.first;
          _broadcasterIdentity = participant.identity;
        });
        return;
      }
    }

    // No video track found
    setState(() {
      _remoteVideoTrack = null;
      _broadcasterIdentity = null;
    });
  }

  void _updateViewerCount() {
    if (_isConnected) {
      final count = _meetingService.getParticipantCount();
      setState(() {
        _viewerCount = count > 0 ? count : 0;
      });
      Future.delayed(const Duration(seconds: 5), _updateViewerCount);
    }
  }

  Future<void> _toggleMute() async {
    // Viewers can't unmute themselves in broadcast mode
    // This is just for UI consistency
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _leaveStream() async {
    try {
      await _meetingService.leaveMeeting();
      if (widget.onStreamEnded != null) {
        widget.onStreamEnded!();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error leaving stream: $e');
    }
  }

  @override
  void dispose() {
    _meetingService.leaveMeeting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Connecting to stream...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isConnected) {
      if (kIsWeb) {
        // Web version with design system
        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: Container(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'Failed to connect to stream',
                    style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  ElevatedButton(
                    onPressed: _connectToStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Mobile version
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.white),
                  const SizedBox(height: AppSpacing.large),
                  const Text(
                    'Failed to connect to stream',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  ElevatedButton(
                    onPressed: _connectToStream,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: kIsWeb ? Column(
        children: [
          // Header with title and viewer count (web version)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveGridDelegate.getResponsivePadding(context).horizontal,
              vertical: AppSpacing.medium,
            ),
            color: Colors.black.withOpacity(0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          widget.streamTitle,
                          style: AppTypography.body.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_viewerCount',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      onPressed: _leaveStream,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video player area
          Expanded(
            child: _remoteVideoTrack != null
                ? VideoTrackView(track: _remoteVideoTrack!, isLocal: false)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, size: 80, color: Colors.white38),
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for broadcaster...',
                            style: AppTypography.body.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ) : SafeArea(
        child: Column(
          children: [
            // Header with title and viewer count (mobile version)
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              color: Colors.black.withOpacity(0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        const Text(
                          'LIVE',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Text(
                            widget.streamTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_viewerCount',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        onPressed: _leaveStream,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Video player area
            Expanded(
              child: _remoteVideoTrack != null
                  ? VideoTrackView(track: _remoteVideoTrack!, isLocal: false)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, size: 80, color: Colors.white38),
                            SizedBox(height: 16),
                            Text(
                              'Waiting for broadcaster...',
                              style: TextStyle(color: Colors.white70),
                            ),
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
}
