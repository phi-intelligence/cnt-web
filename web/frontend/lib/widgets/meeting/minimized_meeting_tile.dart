import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../theme/app_typography.dart';
import 'video_track_view.dart';

/// Minimized Meeting Tile - Floating draggable widget
/// Similar to Google Meet's picture-in-picture mode
class MinimizedMeetingTile extends StatefulWidget {
  final lk.Room room;
  final String roomName;
  final VoidCallback onExpand;
  final VoidCallback onLeave;

  const MinimizedMeetingTile({
    super.key,
    required this.room,
    required this.roomName,
    required this.onExpand,
    required this.onLeave,
  });

  @override
  State<MinimizedMeetingTile> createState() => _MinimizedMeetingTileState();
}

class _MinimizedMeetingTileState extends State<MinimizedMeetingTile> {
  Offset _position = const Offset(20, 100); // Default position

  @override
  Widget build(BuildContext context) {
    final localParticipant = widget.room.localParticipant;
    if (localParticipant == null) return const SizedBox.shrink();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
            // Constrain position to screen bounds
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            _position = Offset(
              _position.dx.clamp(0.0, screenWidth - 280),
              _position.dy.clamp(0.0, screenHeight - 200),
            );
          });
        },
        child: Container(
          width: 280,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Video or placeholder - access participants directly
                Builder(
                  builder: (context) {
                    final participants = widget.room.remoteParticipants.values.toList();
                    final visibleParticipants = participants.where((p) {
                      final videoTracks = p.trackPublications.values
                          .where((pub) => 
                              pub.kind == lk.TrackType.VIDEO && 
                              pub.track != null && 
                              pub.subscribed && 
                              !pub.muted);
                      return videoTracks.isNotEmpty;
                    }).toList();

                    if (visibleParticipants.isNotEmpty) {
                      final videoTrack = visibleParticipants.first.trackPublications.values
                          .where((pub) => pub.kind == lk.TrackType.VIDEO && pub.track != null)
                          .map((pub) => pub.track as lk.RemoteVideoTrack)
                          .first;
                      return VideoTrackView(track: videoTrack, isLocal: false);
                    }

                    // Show local participant video if available
                    final localVideoTrack = localParticipant.trackPublications.values
                        .where((pub) => pub.kind == lk.TrackType.VIDEO && pub.track != null)
                        .map((pub) => pub.track as lk.LocalVideoTrack)
                        .firstOrNull;
                    
                    if (localVideoTrack != null) {
                      return VideoTrackView(track: localVideoTrack, isLocal: true);
                    }

                    // Placeholder
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                      ),
                    );
                  },
                ),

                // Controls overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header with room name
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.roomName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom controls
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Expand button
                              IconButton(
                                icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                                onPressed: widget.onExpand,
                                tooltip: 'Expand',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              // End button
                              IconButton(
                                icon: const Icon(Icons.call_end, color: Colors.red, size: 20),
                                onPressed: widget.onLeave,
                                tooltip: 'End meeting',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
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
      ),
    );
  }
}

