import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../donation_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/image_helper.dart';

/// Web Full-Screen Audio Player
/// Desktop-optimized layout with larger controls and better spacing
class AudioPlayerFullScreenWeb extends StatefulWidget {
  const AudioPlayerFullScreenWeb({super.key});

  @override
  State<AudioPlayerFullScreenWeb> createState() => _AudioPlayerFullScreenWebState();
}

class _AudioPlayerFullScreenWebState extends State<AudioPlayerFullScreenWeb> {
  bool _isDescriptionExpanded = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = Provider.of<AudioPlayerState>(context);
    final track = audioPlayer.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: const Center(
          child: Text('No track playing'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildHeader(),
            
            // Content Area (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Large Album Art Card (centered like mobile)
                    _buildAlbumArtCard(track),
                    
                    const SizedBox(height: 32),
                    
                    // Overlapping Dark Shape (Depth Effect) with Audio Details
                    _buildOverlappingShapeWithDetails(track),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Controls
            _buildBottomControls(audioPlayer, track),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Playing now',
              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildAlbumArtCard(ContentItem track) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.6).clamp(400.0, 600.0); // 60% of screen, min 400, max 600
    
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: track.coverImage != null && track.coverImage!.isNotEmpty
              ? Image(
                  image: ImageHelper.getImageProvider(
                    track.coverImage,
                    fallbackAsset: ImageHelper.getFallbackAsset(
                      int.tryParse(track.id) ?? 0,
                    ),
                  ),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackImage(size);
                  },
                )
              : _buildFallbackImage(size),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.backgroundTertiary,
      child: Icon(
        Icons.music_note,
        size: size * 0.2,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildOverlappingShapeWithDetails(ContentItem track) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Overlapping shape (using Transform instead of negative margin)
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundPrimary,
                  AppColors.backgroundSecondary,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
          ),
        ),
        // Audio Details Section (positioned below the overlapping shape)
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: _buildAudioDetails(track),
        ),
      ],
    );
  }

  Widget _buildAudioDetails(ContentItem track) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Donate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Show donation modal
                showDialog(
                  context: context,
                  builder: (_) => DonationModal(
                    recipientName: track.creator,
                    recipientUserId: 1, // TODO: Get actual creator ID from track
                  ),
                );
              },
              icon: const Icon(Icons.favorite, color: Colors.white),
              label: Text(
                'Donate',
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            track.title,
            style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Publisher with Heart Icon
          Row(
            children: [
              Expanded(
                child: Text(
                  track.creator ?? 'Unknown Artist',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  track.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: track.isFavorite
                      ? AppColors.errorMain
                      : AppColors.textTertiary,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Favorite feature coming soon')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description (Expandable)
          if (track.description != null && track.description!.isNotEmpty)
            _buildExpandableDescription(track),
        ],
      ),
    );
  }

  Widget _buildExpandableDescription(ContentItem track) {
    final description = track.description!;
    final isLong = description.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isDescriptionExpanded || !isLong
              ? description
              : '${description.substring(0, 150)}...',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
        ),
        if (isLong)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Show less' : 'Show more',
              style: TextStyle(color: AppColors.primaryMain),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls(AudioPlayerState audioPlayer, ContentItem track) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.borderSecondary, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          _buildProgressBar(audioPlayer),
          
          const SizedBox(height: 24),
          
          // Playback Controls
          _buildPlaybackControls(audioPlayer),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerState audioPlayer) {
    final progress = audioPlayer.duration.inSeconds > 0
        ? audioPlayer.position.inSeconds / audioPlayer.duration.inSeconds
        : 0.0;

    return Column(
      children: [
        Slider(
          value: progress.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.primaryMain,
          inactiveColor: AppColors.borderSecondary,
          onChanged: (value) {
            final newPosition = Duration(
              seconds: (value * audioPlayer.duration.inSeconds).toInt(),
            );
            audioPlayer.seek(newPosition);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(audioPlayer.position),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _formatDuration(audioPlayer.duration),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioPlayerState audioPlayer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 32),
          color: AppColors.textPrimary,
          onPressed: audioPlayer.queue.isNotEmpty && audioPlayer.currentTrack != null
              ? () => audioPlayer.previous()
              : null,
        ),
        
        const SizedBox(width: 24),
        
        // Large Play Button (Gradient)
        GestureDetector(
          onTap: () => audioPlayer.togglePlayPause(),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryMain,
                  AppColors.accentMain,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              audioPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // Next Button
        IconButton(
          icon: const Icon(Icons.skip_next, size: 32),
          color: AppColors.textPrimary,
          onPressed: audioPlayer.queue.isNotEmpty && audioPlayer.currentTrack != null
              ? () => audioPlayer.next()
              : null,
        ),
      ],
    );
  }
}

