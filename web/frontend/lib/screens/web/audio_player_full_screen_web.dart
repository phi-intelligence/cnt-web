import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:convert' as convert;
import '../../providers/audio_player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/content_item.dart';
import '../donation_modal.dart';
import '../../utils/bank_details_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/image_helper.dart';
import '../../widgets/web/queue_modal_web.dart';
import '../../services/logger_service.dart';

/// Web Full-Screen Audio Player - Spotify-style Design
/// Features:
/// - Max width constraint for better proportions
/// - Large album art with rounded corners and shadow
/// - Gradient progress bar with warm brown theme
/// - Volume slider and shuffle/repeat controls
class AudioPlayerFullScreenWeb extends StatefulWidget {
  const AudioPlayerFullScreenWeb({super.key});

  @override
  State<AudioPlayerFullScreenWeb> createState() =>
      _AudioPlayerFullScreenWebState();
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
      // Show a friendly "No track playing" state instead of auto-navigating
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Album art placeholder
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.warmBrown.withOpacity(0.2),
                          AppColors.warmBrown.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warmBrown.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 80,
                      color: AppColors.warmBrown.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'No Track Playing',
                    style: AppTypography.heading2.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a track from the library to start playing',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Back button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/music');
                      }
                    },
                    icon: const Icon(Icons.library_music_rounded),
                    label: const Text('Browse Music'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warmBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.warmBrown.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Responsive layout - use more screen width on larger screens
    final isWideScreen = screenWidth > 1000;
    final maxContentWidth = isWideScreen ? 1200.0 : screenWidth * 0.95;
    final horizontalPadding = isWideScreen ? 64.0 : 24.0;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0E8), // Warm background like landing page
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildHeader(),

            // Content Area
            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: isWideScreen
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Side: Album Art
                            Expanded(
                              flex: 5,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate available size for album art by subtracting slider width and spacing
                                  final availableWidth = constraints.maxWidth -
                                      24 -
                                      60; // 24 spacing + 60 slider
                                  final size =
                                      availableWidth.clamp(200.0, 500.0);

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildAlbumArtCard(track, size),
                                      const SizedBox(width: 24),
                                      _buildVerticalVolumeSlider(audioPlayer),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 48),
                            // Right Side: Controls & Info
                            Expanded(
                              flex: 6,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTrackInfo(track),
                                  const SizedBox(height: 32),
                                  _buildProgressBar(audioPlayer),
                                  const SizedBox(height: 24),
                                  _buildPlaybackControls(audioPlayer),
                                  const SizedBox(height: 24),
                                  _buildExtraControls(audioPlayer),
                                  const SizedBox(height: 32),
                                  _buildDonateButton(track),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              // Album Art with Vertical Volume Slider
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final albumArtSize = screenWidth < 600
                                      ? screenWidth * 0.7
                                      : 350.0;
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 40), // Balance spacer
                                      _buildAlbumArtCard(track, albumArtSize),
                                      _buildVerticalVolumeSlider(audioPlayer),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildTrackInfo(track),
                              const SizedBox(height: 20),
                              _buildProgressBar(audioPlayer),
                              const SizedBox(height: 20),
                              _buildPlaybackControls(audioPlayer),
                              const SizedBox(height: 20),
                              _buildExtraControls(audioPlayer),
                              const SizedBox(height: 24),
                              _buildDonateButton(track),
                              const SizedBox(height: 32),
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
              icon: Icon(
                Icons.keyboard_arrow_down,
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
              icon: Icon(
                Icons.more_horiz,
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

  Widget _buildAlbumArtCard(ContentItem track, double size) {
    // Size is now passed directly from caller for better responsiveness

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
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
          onTap: track.creatorId != null
              ? () {
                  // Navigate to artist profile
                  Navigator.pop(context); // Close player first
                  context.go('/artist/${track.creatorId}');
                }
              : null,
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
                  decoration:
                      track.creatorId != null ? TextDecoration.underline : null,
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

  bool _isSeeking = false;
  double _seekValue = 0.0;

  Widget _buildProgressBar(AudioPlayerState audioPlayer) {
    // Check if duration is valid before allowing seeking
    final isValidDuration = audioPlayer.duration.inSeconds > 0;
    final progress = isValidDuration
        ? audioPlayer.position.inSeconds / audioPlayer.duration.inSeconds
        : 0.0;

    // Use local seek value while actively seeking, otherwise use actual progress
    final displayProgress = _isSeeking ? _seekValue : progress;

    return Column(
      children: [
        // Custom Progress Bar with warm brown gradient
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.warmBrown,
            inactiveTrackColor: AppColors.warmBrown.withOpacity(0.2),
            thumbColor: AppColors.warmBrown,
            overlayColor: AppColors.warmBrown.withOpacity(0.2),
          ),
          child: Slider(
            value: displayProgress.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            onChangeStart: (value) {
              if (!isValidDuration) {
                LoggerService.w('⚠️ Cannot seek - duration not available');
                return;
              }
              setState(() {
                _isSeeking = true;
                _seekValue = value;
              });
            },
            onChanged: (value) {
              if (!isValidDuration) {
                return;
              }
              setState(() {
                _seekValue = value;
              });
            },
            onChangeEnd: (value) async {
              if (!isValidDuration) {
                setState(() {
                  _isSeeking = false;
                });
                return;
              }
              final newPosition = Duration(
                milliseconds:
                    (value * audioPlayer.duration.inMilliseconds).toInt(),
              );
              await audioPlayer.seek(newPosition);
              if (mounted) {
                setState(() {
                  _isSeeking = false;
                });
              }
            },
          ),
        ),
        // Time labels - show seek preview time when dragging
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSeeking
                    ? _formatDuration(Duration(
                        milliseconds: isValidDuration
                            ? (_seekValue * audioPlayer.duration.inMilliseconds)
                                .toInt()
                            : 0,
                      ))
                    : _formatDuration(audioPlayer.position),
                style: AppTypography.caption.copyWith(
                  color: _isSeeking
                      ? AppColors.warmBrown
                      : AppColors.primaryDark.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                isValidDuration
                    ? _formatDuration(audioPlayer.duration)
                    : '--:--',
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
            color: audioPlayer.hasPrevious
                ? AppColors.primaryDark
                : AppColors.primaryDark.withOpacity(0.3),
            tooltip: 'Previous',
            onPressed:
                audioPlayer.hasPrevious || audioPlayer.currentTrack != null
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
            color: audioPlayer.hasNext
                ? AppColors.primaryDark
                : AppColors.primaryDark.withOpacity(0.3),
            tooltip: 'Next',
            onPressed: audioPlayer.hasNext ? () => audioPlayer.next() : null,
          ),
        ),

        const SizedBox(width: 16),

        // Repeat button - connected to provider
        IconButton(
          icon: Icon(
            audioPlayer.repeatOneEnabled
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
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
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
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
              _volume == 0
                  ? Icons.volume_off_rounded
                  : Icons.volume_mute_rounded,
              color: AppColors.warmBrown.withOpacity(_volume == 0 ? 0.9 : 0.4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Extra controls (queue, favorite, download)
  Widget _buildExtraControls(AudioPlayerState audioPlayer) {
    final track = audioPlayer.currentTrack;
    final hasQueue = audioPlayer.queue.isNotEmpty;

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorite =
            track != null && favoritesProvider.isFavorite(track.id);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Queue button with badge
              Stack(
                children: [
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
                        color: hasQueue
                            ? AppColors.warmBrown
                            : AppColors.warmBrown.withOpacity(0.5),
                        size: 24,
                      ),
                      tooltip: 'Queue (${audioPlayer.queue.length} tracks)',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const QueueModalWeb(),
                        );
                      },
                    ),
                  ),
                  // Queue count badge
                  if (hasQueue)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.warmBrown,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${audioPlayer.queue.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Favorite button - connected to FavoritesProvider
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
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite
                        ? AppColors.errorMain
                        : AppColors.warmBrown.withOpacity(0.8),
                    size: 24,
                  ),
                  tooltip:
                      isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                  onPressed: track != null
                      ? () async {
                          final success =
                              await favoritesProvider.toggleFavorite(track);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? (isFavorite
                                          ? 'Removed from favorites'
                                          : 'Added to favorites')
                                      : 'Failed to update favorites',
                                ),
                                backgroundColor: success
                                    ? AppColors.successMain
                                    : AppColors.errorMain,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Download button
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
                    Icons.download_rounded,
                    color: AppColors.warmBrown.withOpacity(0.8),
                    size: 24,
                  ),
                  tooltip: 'Download',
                  onPressed: track?.audioUrl != null
                      ? () => _handleDownload(track!)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // View Artist button
              if (track?.creatorId != null)
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
                      Icons.person_rounded,
                      color: AppColors.warmBrown.withOpacity(0.8),
                      size: 24,
                    ),
                    tooltip: 'View Artist',
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/artist/${track!.creatorId}');
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Handle download of current track
  Future<void> _handleDownload(ContentItem track) async {
    if (track.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file available for download')),
      );
      return;
    }

    try {
      // For web, we create an anchor element to trigger download
      // This is handled via dart:html
      final url = track.audioUrl!;
      final filename = '${track.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.mp3';

      // Show downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text('Downloading "${track.title}"...')),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Track download in localStorage for web
      _trackDownloadInLocalStorage(track);

      // Trigger download via JavaScript
      _triggerWebDownload(url, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  /// Track download in localStorage for web platform
  void _trackDownloadInLocalStorage(ContentItem track) {
    if (!kIsWeb) return;

    try {
      // Get existing downloads from localStorage
      final existingDownloadsJson =
          html.window.localStorage['cnt_downloads'] ?? '[]';
      List<dynamic> downloads = [];

      try {
        downloads = (html.window.localStorage['cnt_downloads'] != null)
            ? (html.window.localStorage['cnt_downloads']!.isNotEmpty
                ? (convert.jsonDecode(
                    html.window.localStorage['cnt_downloads']!) as List)
                : [])
            : [];
      } catch (e) {
        LoggerService.e('Error parsing existing downloads: $e');
        downloads = [];
      }

      // Check if already downloaded
      final alreadyDownloaded = downloads.any((d) => d['id'] == track.id);
      if (alreadyDownloaded) {
        return; // Already tracked
      }

      // Add new download entry
      final downloadEntry = {
        'id': track.id,
        'title': track.title,
        'creator': track.creator ?? '',
        'cover_image': track.coverImage ?? '',
        'audio_url': track.audioUrl ?? '',
        'duration': track.duration?.inSeconds,
        'category': track.category ?? '',
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      };

      downloads.add(downloadEntry);

      // Save back to localStorage
      html.window.localStorage['cnt_downloads'] = convert.jsonEncode(downloads);
      LoggerService.i('✅ Download tracked in localStorage: ${track.title}');
    } catch (e) {
      LoggerService.e('Error tracking download in localStorage: $e');
    }
  }

  /// Trigger download on web using dart:html
  void _triggerWebDownload(String url, String filename) {
    if (!kIsWeb) return;

    try {
      // Create an anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download started: $filename'),
            backgroundColor: AppColors.successMain,
          ),
        );
      }
    } catch (e) {
      LoggerService.e('Download error: $e');
      if (mounted) {
        // Fallback: open in new tab
        html.window.open(url, '_blank');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening audio in new tab...'),
          ),
        );
      }
    }
  }

  Widget _buildDonateButton(ContentItem track) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      child: ElevatedButton.icon(
        onPressed: () async {
          final recipientId =
              track.creatorId ?? 1; // Fallback to 1 if not available
          final recipientName = track.creator ?? 'Artist';

          // Check if recipient has bank details before showing donation modal
          final hasRecipientBankDetails =
              await checkRecipientBankDetails(recipientId);
          if (!hasRecipientBankDetails) {
            // Show error dialog if recipient doesn't have bank details
            if (context.mounted) {
              await showRecipientBankDetailsMissingDialog(
                  context, recipientName);
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
}
