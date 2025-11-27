import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// Widget to render video tracks from LiveKit
class VideoTrackView extends StatelessWidget {
  final lk.VideoTrack? track;
  final bool isLocal;
  final bool mirror;

  const VideoTrackView({
    super.key,
    required this.track,
    this.isLocal = false,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
        ),
      );
    }

    // Create the video renderer
    final videoRenderer = lk.VideoTrackRenderer(track!);
    
    // Mirror local video tracks horizontally to provide proper mirror effect
    // When you raise your RIGHT hand, you see it on the RIGHT side (like a real mirror)
    if (mirror && isLocal) {
      // Apply horizontal flip transform to create mirror effect
      // This ensures: raise RIGHT hand → appears on RIGHT side of screen
      // Transform respects parent constraints automatically
      return Transform(
        alignment: Alignment.center,
        // Horizontal flip: scale X by -1 (flip left-right), keep Y as 1
        // This creates proper mirror effect where right stays right
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: videoRenderer,
      );
    }

    // For remote tracks or when mirror is false, render normally (no flip)
    return videoRenderer;
  }
}

/// Placeholder widget for video when track is not available
class PlaceholderVideoView extends StatelessWidget {
  final String? name;
  final String? avatarUrl;

  const PlaceholderVideoView({super.key, this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[700],
        backgroundImage: NetworkImage(avatarUrl!),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[700],
        child: Text(
          name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            avatarWidget,
            if (name != null) ...[
              const SizedBox(height: 8),
              Text(
                name!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

