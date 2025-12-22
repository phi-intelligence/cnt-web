import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../shared/image_helper.dart';

/// Queue Modal for Web Audio Player
/// Shows current queue with drag-to-reorder and remove functionality
class QueueModalWeb extends StatefulWidget {
  const QueueModalWeb({super.key});

  @override
  State<QueueModalWeb> createState() => _QueueModalWebState();
}

class _QueueModalWebState extends State<QueueModalWeb> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerState>(
      builder: (context, audioPlayer, _) {
        final queue = audioPlayer.queue;
        final currentTrack = audioPlayer.currentTrack;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, queue.length),
                
                // Divider
                Divider(
                  height: 1,
                  color: AppColors.warmBrown.withOpacity(0.2),
                ),
                
                // Queue List
                Flexible(
                  child: queue.isEmpty
                      ? _buildEmptyState()
                      : _buildQueueList(audioPlayer, currentTrack),
                ),
                
                // Footer actions
                if (queue.isNotEmpty) _buildFooter(context, audioPlayer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int queueLength) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Icon(
            Icons.queue_music_rounded,
            color: AppColors.warmBrown,
            size: 28,
          ),
          SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Queue',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$queueLength track${queueLength == 1 ? '' : 's'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.extraLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 64,
            color: AppColors.warmBrown.withOpacity(0.3),
          ),
          SizedBox(height: AppSpacing.large),
          Text(
            'Queue is Empty',
            style: AppTypography.heading3.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppSpacing.small),
          Text(
            'Add tracks to your queue to play next',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(AudioPlayerState audioPlayer, ContentItem? currentTrack) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
      itemCount: audioPlayer.queue.length,
      onReorder: (oldIndex, newIndex) {
        // Reorder queue
        if (newIndex > oldIndex) newIndex--;
        final item = audioPlayer.queue.removeAt(oldIndex);
        audioPlayer.queue.insert(newIndex, item);
        audioPlayer.notifyListeners();
      },
      itemBuilder: (context, index) {
        final track = audioPlayer.queue[index];
        final isCurrentTrack = currentTrack?.id == track.id;
        
        return _buildQueueItem(
          key: ValueKey(track.id),
          track: track,
          index: index,
          isCurrentTrack: isCurrentTrack,
          isPlaying: isCurrentTrack && audioPlayer.isPlaying,
          onTap: () {
            // Play this track
            audioPlayer.loadTrack(track);
            audioPlayer.play();
          },
          onRemove: () {
            // Remove from queue
            audioPlayer.queue.removeAt(index);
            audioPlayer.notifyListeners();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed "${track.title}" from queue'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQueueItem({
    required Key key,
    required ContentItem track,
    required int index,
    required bool isCurrentTrack,
    required bool isPlaying,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: isCurrentTrack 
            ? AppColors.warmBrown.withOpacity(0.1) 
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTrack 
            ? Border.all(color: AppColors.warmBrown.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            SizedBox(width: AppSpacing.small),
            // Track number or playing indicator
            SizedBox(
              width: 24,
              child: isCurrentTrack
                  ? Icon(
                      isPlaying ? Icons.equalizer : Icons.pause,
                      color: AppColors.warmBrown,
                      size: 20,
                    )
                  : Text(
                      '${index + 1}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            SizedBox(width: AppSpacing.medium),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.coverImage != null && track.coverImage!.isNotEmpty
                  ? Image(
                      image: ImageHelper.getImageProvider(
                        track.coverImage,
                        fallbackAsset: 'assets/images/placeholder.png',
                      ),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ],
        ),
        title: Text(
          track.title,
          style: AppTypography.bodyMedium.copyWith(
            color: isCurrentTrack ? AppColors.warmBrown : AppColors.primaryDark,
            fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.creator ?? 'Unknown Artist',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
          tooltip: 'Remove from queue',
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.warmBrown.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.warmBrown.withOpacity(0.5),
        size: 24,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AudioPlayerState audioPlayer) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.warmBrown.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle toggle
          TextButton.icon(
            onPressed: () => audioPlayer.toggleShuffle(),
            icon: Icon(
              Icons.shuffle,
              color: audioPlayer.shuffleEnabled 
                  ? AppColors.warmBrown 
                  : AppColors.textSecondary,
              size: 20,
            ),
            label: Text(
              'Shuffle',
              style: AppTypography.bodySmall.copyWith(
                color: audioPlayer.shuffleEnabled 
                    ? AppColors.warmBrown 
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Clear queue button
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Queue?'),
                  content: const Text('This will remove all tracks from your queue.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        audioPlayer.clearQueue();
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close modal
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Queue cleared')),
                        );
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: AppColors.errorMain),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            label: Text(
              'Clear Queue',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

