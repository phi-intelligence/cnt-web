import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../utils/platform_helper.dart';
import '../../screens/audio/audio_player_full_screen_new.dart';
import '../../screens/web/audio_player_full_screen_web.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

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
        padding: const EdgeInsets.all(AppSpacing.medium),
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
        child: Column(
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
                          width: 60,
                          height: 60,
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
                        onPressed: audioPlayer.queue.isNotEmpty && audioPlayer.currentTrack != null
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
                        onPressed: audioPlayer.queue.isNotEmpty && audioPlayer.currentTrack != null
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
        ),
      ),
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

  const _ControlButton({
    required this.icon,
    this.onPressed,
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
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}
