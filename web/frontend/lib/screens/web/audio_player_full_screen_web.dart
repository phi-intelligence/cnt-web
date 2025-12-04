import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../donation_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/shared/image_helper.dart';

/// Web Full-Screen Audio Player - Spotify-style Design
/// Features:
/// - Max width constraint for better proportions
/// - Large album art with rounded corners and shadow
/// - Gradient progress bar with warm brown theme
/// - Volume slider and shuffle/repeat controls
class AudioPlayerFullScreenWeb extends StatefulWidget {
  const AudioPlayerFullScreenWeb({super.key});

  @override
  State<AudioPlayerFullScreenWeb> createState() => _AudioPlayerFullScreenWebState();
}

class _AudioPlayerFullScreenWebState extends State<AudioPlayerFullScreenWeb>
    with SingleTickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  double _volume = 1.0;
  bool _isShuffled = false;
  bool _isRepeat = false;
  bool _isRepeatOne = false;
  
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = Provider.of<AudioPlayerState>(context);
    final track = audioPlayer.currentTrack;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Control rotation animation based on play state
    if (audioPlayer.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    if (track == null) {
      // Auto-navigate back when track becomes null (playback ended)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // Warm background like landing page
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900), // Max width for better proportions
            child: Column(
              children: [
                // Top Header
                _buildHeader(),
                
                // Content Area (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Album Art with Vertical Volume Slider on the right
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Spacer for balance
                            const SizedBox(width: 60),
                            
                            // Large Album Art with vinyl effect
                            Flexible(
                              child: _buildAlbumArtCard(track, screenWidth),
                            ),
                            
                            // Vertical Volume Slider on the right
                            _buildVerticalVolumeSlider(audioPlayer),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Track Info
                        _buildTrackInfo(track),
                        
                        const SizedBox(height: 24),
                        
                        // Progress Bar
                        _buildProgressBar(audioPlayer),
                        
                        const SizedBox(height: 24),
                        
                        // Playback Controls
                        _buildPlaybackControls(audioPlayer),
                        
                        const SizedBox(height: 24),
                        
                        // Extra Controls (queue, favorite - without horizontal volume)
                        _buildExtraControls(audioPlayer),
                        
                        const SizedBox(height: 24),
                        
                        // Donate Button
                        _buildDonateButton(track),
                        
                        const SizedBox(height: 24),
                        
                        // Description
                        if (track.description != null && track.description!.isNotEmpty)
                          _buildExpandableDescription(track),
                          
                        const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.keyboard_arrow_down, 
                color: AppColors.warmBrown,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Text(
              'NOW PLAYING',
              style: AppTypography.caption.copyWith(
                color: AppColors.warmBrown,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // More options button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.more_horiz, 
                color: AppColors.warmBrown,
                size: 24,
              ),
              onPressed: () {
                // Show more options
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtCard(ContentItem track, double screenWidth) {
    final size = screenWidth < 600 ? screenWidth * 0.7 : 350.0;
    
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Album Art
              track.coverImage != null && track.coverImage!.isNotEmpty
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
              // Subtle gradient overlay at bottom for depth
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size * 0.3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.3),
            AppColors.warmBrown.withOpacity(0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.25,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildTrackInfo(ContentItem track) {
    return Column(
      children: [
        // Title
        Text(
          track.title,
          style: AppTypography.heading2.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // Artist - Tappable to view profile
        GestureDetector(
          onTap: track.creatorId != null ? () {
            // Navigate to artist profile
            Navigator.pop(context); // Close player first
            context.go('/artist/${track.creatorId}');
          } : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                track.creator ?? 'Unknown Artist',
                style: AppTypography.body.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  decoration: track.creatorId != null ? TextDecoration.underline : null,
                ),
                textAlign: TextAlign.center,
              ),
              if (track.creatorId != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.warmBrown,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayerState audioPlayer) {
    final progress = audioPlayer.duration.inSeconds > 0
        ? audioPlayer.position.inSeconds / audioPlayer.duration.inSeconds
        : 0.0;

    return Column(
      children: [
        // Custom Progress Bar with warm brown gradient
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.warmBrown,
            inactiveTrackColor: AppColors.warmBrown.withOpacity(0.2),
            thumbColor: AppColors.warmBrown,
            overlayColor: AppColors.warmBrown.withOpacity(0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              final newPosition = Duration(
                seconds: (value * audioPlayer.duration.inSeconds).toInt(),
              );
              audioPlayer.seek(newPosition);
            },
          ),
        ),
        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(audioPlayer.position),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(audioPlayer.duration),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryDark.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(AudioPlayerState audioPlayer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle button - connected to provider
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            size: 24,
            color: audioPlayer.shuffleEnabled 
                ? AppColors.warmBrown 
                : AppColors.primaryDark.withOpacity(0.4),
          ),
          tooltip: 'Shuffle',
          onPressed: () {
            audioPlayer.toggleShuffle();
            setState(() => _isShuffled = audioPlayer.shuffleEnabled);
          },
        ),
        
        const SizedBox(width: 16),
        
        // Previous Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.skip_previous_rounded, size: 32),
            color: audioPlayer.hasPrevious ? AppColors.primaryDark : AppColors.primaryDark.withOpacity(0.3),
            tooltip: 'Previous',
            onPressed: audioPlayer.hasPrevious || audioPlayer.currentTrack != null
                ? () => audioPlayer.previous()
                : null,
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Large Play Button with gradient
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
                  AppColors.warmBrown,
                  AppColors.warmBrown.withRed(120),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              audioPlayer.isPlaying 
                  ? Icons.pause_rounded 
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Next Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.skip_next_rounded, size: 32),
            color: audioPlayer.hasNext ? AppColors.primaryDark : AppColors.primaryDark.withOpacity(0.3),
            tooltip: 'Next',
            onPressed: audioPlayer.hasNext
                ? () => audioPlayer.next()
                : null,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Repeat button - connected to provider
        IconButton(
          icon: Icon(
            audioPlayer.repeatOneEnabled ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            size: 24,
            color: (audioPlayer.repeatEnabled || audioPlayer.repeatOneEnabled)
                ? AppColors.warmBrown 
                : AppColors.primaryDark.withOpacity(0.4),
          ),
          tooltip: audioPlayer.repeatOneEnabled 
              ? 'Repeat One' 
              : audioPlayer.repeatEnabled 
                  ? 'Repeat All' 
                  : 'Repeat',
          onPressed: () {
            audioPlayer.toggleRepeat();
            setState(() {
              _isRepeat = audioPlayer.repeatEnabled;
              _isRepeatOne = audioPlayer.repeatOneEnabled;
            });
          },
        ),
      ],
    );
  }

  /// Vertical volume slider positioned on the right side of album art
  Widget _buildVerticalVolumeSlider(AudioPlayerState audioPlayer) {
    return Container(
      width: 60,
      height: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Volume up icon
          Icon(
            Icons.volume_up_rounded,
            color: AppColors.warmBrown.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(height: 8),
          // Vertical slider
          Expanded(
            child: RotatedBox(
              quarterTurns: 3, // Rotate to vertical (270 degrees)
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.warmBrown,
                  inactiveTrackColor: AppColors.warmBrown.withOpacity(0.2),
                  thumbColor: AppColors.warmBrown,
                  overlayColor: AppColors.warmBrown.withOpacity(0.2),
                ),
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() => _volume = value);
                    audioPlayer.setVolume(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Volume off/mute icon
          GestureDetector(
            onTap: () {
              // Toggle mute
              final newVolume = _volume == 0 ? 1.0 : 0.0;
              setState(() => _volume = newVolume);
              audioPlayer.setVolume(newVolume);
            },
            child: Icon(
              _volume == 0 ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
              color: AppColors.warmBrown.withOpacity(_volume == 0 ? 0.9 : 0.4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Extra controls (queue, favorite) without volume slider
  Widget _buildExtraControls(AudioPlayerState audioPlayer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Queue button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.queue_music_rounded,
                color: AppColors.warmBrown.withOpacity(0.8),
                size: 24,
              ),
              tooltip: 'Queue',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Queue feature coming soon')),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Favorite button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                audioPlayer.currentTrack?.isFavorite == true 
                    ? Icons.favorite_rounded 
                    : Icons.favorite_border_rounded,
                color: audioPlayer.currentTrack?.isFavorite == true 
                    ? AppColors.errorMain 
                    : AppColors.warmBrown.withOpacity(0.8),
                size: 24,
              ),
              tooltip: 'Favorite',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Favorite feature coming soon')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton(ContentItem track) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => DonationModal(
              recipientName: track.creator ?? 'Artist',
              recipientUserId: 1, // TODO: Get actual creator ID from track
            ),
          );
        },
        icon: Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
        label: Text(
          'Support this artist',
          style: AppTypography.button.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: AppColors.warmBrown.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildExpandableDescription(ContentItem track) {
    final description = track.description!;
    final isLong = description.length > 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.warmBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isDescriptionExpanded || !isLong
                ? description
                : '${description.substring(0, 150)}...',
            style: AppTypography.body.copyWith(
              color: AppColors.primaryDark.withOpacity(0.7),
              height: 1.5,
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
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isDescriptionExpanded ? 'Show less' : 'Show more',
                style: TextStyle(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
