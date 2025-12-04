import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../utils/platform_helper.dart';
import '../../screens/audio/audio_player_full_screen_new.dart';
import '../../screens/web/audio_player_full_screen_web.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';

class GlobalAudioPlayer extends StatelessWidget {
  const GlobalAudioPlayer({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = Provider.of<AudioPlayerState>(context);

    // Only show player if there's a current track
    if (audioPlayer.currentTrack == null) {
      return const SizedBox.shrink();
    }

    // Get responsive values
    final isMobile = ResponsiveUtils.isMobile(context);
    final isVerySmall = MediaQuery.of(context).size.width < 400;
    
    final thumbnailSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 60.0,
    );
    
    final iconSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );
    
    final buttonSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 32.0,
      tablet: 36.0,
      desktop: 40.0,
    );

    return GestureDetector(
      onTap: () {
        // Open full-screen player when clicking anywhere on the compact player
        if (PlatformHelper.isWebPlatform()) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AudioPlayerFullScreenWeb(),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AudioPlayerFullScreenNew(),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackground,
              AppColors.backgroundSecondary,
            ],
          ),
          border: const Border(
            top: BorderSide(
              color: AppColors.borderPrimary,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: isMobile ? _buildMobileLayout(
          context,
          audioPlayer,
          thumbnailSize,
          iconSize,
          buttonSize,
          isVerySmall,
        ) : _buildDesktopLayout(
          context,
          audioPlayer,
          thumbnailSize,
          iconSize,
          buttonSize,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AudioPlayerState audioPlayer,
    double thumbnailSize,
    double iconSize,
    double buttonSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Row: Track Details (left), Controls (center), Close (right)
        Row(
          children: [
            // Track Details on the left
            Expanded(
              child: Row(
                children: [
                  // Thumbnail
                  GestureDetector(
                    onTap: () {}, // Consume tap
                    child: Container(
                      width: thumbnailSize,
                      height: thumbnailSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        child: (audioPlayer.currentTrack!.coverImage != null)
                            ? Image.network(
                                audioPlayer.currentTrack!.coverImage!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderArt();
                                },
                              )
                            : _buildPlaceholderArt(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                      
                      // Title and Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              audioPlayer.currentTrack!.title,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              audioPlayer.currentTrack!.creator,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controls in the center
                GestureDetector(
                  onTap: () {}, // Consume tap
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ControlButton(
                        icon: Icons.skip_previous,
                        tooltip: 'Previous',
                        // Allow previous if there's a track (to restart) or queue
                        onPressed: audioPlayer.hasPrevious || audioPlayer.currentTrack != null
                            ? () => audioPlayer.previous()
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      _PlayPauseButton(
                        isPlaying: audioPlayer.isPlaying,
                        isLoading: audioPlayer.isLoading,
                        onPressed: () => audioPlayer.togglePlayPause(),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      _ControlButton(
                        icon: Icons.skip_next,
                        tooltip: 'Next',
                        onPressed: audioPlayer.hasNext
                            ? () => audioPlayer.next()
                            : null,
                      ),
                    ],
                  ),
                ),
                
                // Close button on the right
                if (PlatformHelper.isWebPlatform())
                  GestureDetector(
                    onTap: () {}, // Consume tap
                    child: Container(
                      margin: const EdgeInsets.only(left: AppSpacing.medium),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.errorMain.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: AppColors.errorMain,
                        tooltip: 'Close player',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed: () {
                          audioPlayer.stop();
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            
            // Timeline/Progress Bar
            GestureDetector(
              onTap: () {}, // Consume tap
              child: Row(
                children: [
                  Text(
                    _formatDuration(audioPlayer.position),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: audioPlayer.duration.inSeconds > 0
                            ? audioPlayer.position.inSeconds / audioPlayer.duration.inSeconds
                            : 0.0,
                        onChanged: audioPlayer.isLoading
                            ? null
                            : (value) {
                                final newPosition = Duration(
                                  seconds: (value * audioPlayer.duration.inSeconds).toInt(),
                                );
                                audioPlayer.seek(newPosition);
                              },
                        activeColor: AppColors.warmBrown,
                        inactiveColor: AppColors.borderPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    _formatDuration(audioPlayer.duration),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AudioPlayerState audioPlayer,
    double thumbnailSize,
    double iconSize,
    double buttonSize,
    bool isVerySmall,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: Thumbnail | Title + Artist | Close
        Row(
          children: [
            // Thumbnail
            GestureDetector(
              onTap: () {}, // Consume tap
              child: Container(
                width: thumbnailSize,
                height: thumbnailSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  child: (audioPlayer.currentTrack!.coverImage != null)
                      ? Image.network(
                          audioPlayer.currentTrack!.coverImage!,
                          width: thumbnailSize,
                          height: thumbnailSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderArtMobile(thumbnailSize);
                          },
                        )
                      : _buildPlaceholderArtMobile(thumbnailSize),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            
            // Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    audioPlayer.currentTrack!.title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    audioPlayer.currentTrack!.creator,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Close button
            if (PlatformHelper.isWebPlatform())
              GestureDetector(
                onTap: () {}, // Consume tap
                child: Container(
                  margin: const EdgeInsets.only(left: AppSpacing.tiny),
                  child: IconButton(
                    icon: Icon(Icons.close, size: iconSize - 4),
                    color: AppColors.errorMain,
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: buttonSize - 8,
                      minHeight: buttonSize - 8,
                    ),
                    onPressed: () {
                      audioPlayer.stop();
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        
        // Row 2: Controls | Progress | Time
        Row(
          children: [
            // Play controls
            if (!isVerySmall) ...[
              GestureDetector(
                onTap: () {}, // Consume tap
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.skip_previous, size: iconSize - 2),
                    color: audioPlayer.hasPrevious || audioPlayer.currentTrack != null 
                        ? AppColors.warmBrown 
                        : AppColors.textTertiary,
                    tooltip: 'Previous',
                    onPressed: audioPlayer.hasPrevious || audioPlayer.currentTrack != null
                        ? () => audioPlayer.previous()
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: buttonSize - 8,
                      minHeight: buttonSize - 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            
            // Play/Pause button
            GestureDetector(
              onTap: () => audioPlayer.togglePlayPause(),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown, AppColors.accentMain],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: audioPlayer.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        audioPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: iconSize,
                      ),
              ),
            ),
            
            if (!isVerySmall) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {}, // Consume tap
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.skip_next, size: iconSize - 2),
                    color: audioPlayer.hasNext 
                        ? AppColors.warmBrown 
                        : AppColors.textTertiary,
                    tooltip: 'Next',
                    onPressed: audioPlayer.hasNext
                        ? () => audioPlayer.next()
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: buttonSize - 8,
                      minHeight: buttonSize - 8,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(width: AppSpacing.small),
            
            // Progress slider
            Expanded(
              child: GestureDetector(
                onTap: () {}, // Consume tap
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: audioPlayer.duration.inSeconds > 0
                        ? audioPlayer.position.inSeconds / audioPlayer.duration.inSeconds
                        : 0.0,
                    onChanged: audioPlayer.isLoading
                        ? null
                        : (value) {
                            final newPosition = Duration(
                              seconds: (value * audioPlayer.duration.inSeconds).toInt(),
                            );
                            audioPlayer.seek(newPosition);
                          },
                    activeColor: AppColors.warmBrown,
                    inactiveColor: AppColors.borderPrimary,
                  ),
                ),
              ),
            ),
            
            // Time display
            Text(
              '${_formatDuration(audioPlayer.position)} / ${_formatDuration(audioPlayer.duration)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warmBrown.withOpacity(0.2),
            AppColors.accentMain.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.warmBrown,
        size: 28,
      ),
    );
  }

  Widget _buildPlaceholderArtMobile(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warmBrown.withOpacity(0.2),
            AppColors.accentMain.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.warmBrown,
        size: size * 0.5,
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warmBrown, AppColors.accentMain],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmBrown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: onPressed != null ? AppColors.warmBrown : AppColors.textTertiary,
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}
