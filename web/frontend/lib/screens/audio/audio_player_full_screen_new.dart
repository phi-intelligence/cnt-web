import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/image_helper.dart';
import '../donation_modal.dart';
import '../../utils/bank_details_helper.dart';

/// Full-Screen Audio Player Screen
/// Modern design with large album art, depth effects, and intuitive controls
class AudioPlayerFullScreenNew extends StatefulWidget {
  const AudioPlayerFullScreenNew({super.key});

  @override
  State<AudioPlayerFullScreenNew> createState() => _AudioPlayerFullScreenNewState();
}

class _AudioPlayerFullScreenNewState extends State<AudioPlayerFullScreenNew> {
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

    // Auto-navigate back when track becomes null (playback ended)
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        resizeToAvoidBottomInset: false,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final albumArtSize = screenWidth * 0.75; // 75% of screen width

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
                    const SizedBox(height: 24),

                    // Large Album Art Card
                    _buildAlbumArtCard(track, albumArtSize),

                    const SizedBox(height: 24),

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),

          // Title
          Expanded(
            child: Text(
              'Playing now',
              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),

          // Spacer for balance
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAlbumArtCard(ContentItem track, double size) {
    // Debug: Print cover image info
    print('📸 Full-screen player - Cover image: ${track.coverImage}');
    print('📸 Full-screen player - Track ID: ${track.id}');
    
    return Container(
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
            ? Builder(
                builder: (context) {
                  final imageProvider = ImageHelper.getImageProvider(
                    track.coverImage,
                    fallbackAsset: ImageHelper.getFallbackAsset(
                      int.tryParse(track.id) ?? 0,
                    ),
                  );
                  print('📸 Full-screen player - ImageProvider: $imageProvider');
                  
                  return Image(
                    image: imageProvider,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        print('✅ Full-screen player - Image loaded successfully');
                        return child;
                      }
                      print('⏳ Full-screen player - Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                      return Container(
                        width: size,
                        height: size,
                        color: AppColors.backgroundTertiary,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primaryMain,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Full-screen player - Image error for ${track.coverImage}: $error');
                      print('📸 Full-screen player - Falling back to asset image');
                      return Image.asset(
                        ImageHelper.getFallbackAsset(
                          int.tryParse(track.id) ?? 0,
                        ),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Full-screen player - Fallback asset also failed: $error');
                          return Container(
                            width: size,
                            height: size,
                            color: AppColors.backgroundTertiary,
                            child: const Icon(
                              Icons.music_note,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              )
            : Builder(
                builder: (context) {
                  print('📸 Full-screen player - No cover image, using fallback asset');
                  return Image.asset(
                    ImageHelper.getFallbackAsset(
                      int.tryParse(track.id) ?? 0,
                    ),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: size,
                      height: size,
                      color: AppColors.backgroundTertiary,
                      child: const Icon(
                        Icons.music_note,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                },
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Donate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final recipientId = track.creatorId ?? 1; // Use creatorId from track
                final recipientName = track.creator;
                
                // Check if recipient has bank details before showing donation modal
                final hasRecipientBankDetails = await checkRecipientBankDetails(recipientId);
                if (!hasRecipientBankDetails) {
                  // Show error dialog if recipient doesn't have bank details
                  if (context.mounted) {
                    await showRecipientBankDetailsMissingDialog(context, recipientName);
                  }
                  return;
                }
                
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (_) => DonationModal(
                    recipientName: recipientName,
                    recipientUserId: recipientId,
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
                  track.creator,
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
                  // TODO: Implement favorite toggle
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Favorite feature coming soon')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description (Expandable)
          if (track.description != null) _buildExpandableDescription(track),
        ],
      ),
    );
  }

  Widget _buildExpandableDescription(ContentItem track) {
    final description = track.description!;
    final isLong = description.length > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isDescriptionExpanded || !isLong
              ? description
              : '${description.substring(0, 100)}...',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: _isDescriptionExpanded ? null : 2,
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
          onPressed: () => audioPlayer.previous(),
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
          onPressed: () => audioPlayer.next(),
        ),
      ],
    );
  }
}

