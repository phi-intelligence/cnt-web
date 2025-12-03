import 'package:flutter/material.dart';
import '../../models/content_item.dart';
import '../shared/image_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';

class ContentCardWeb extends StatefulWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;

  const ContentCardWeb({
    super.key,
    required this.item,
    this.onTap,
    this.onPlay,
  });

  @override
  State<ContentCardWeb> createState() => _ContentCardWebState();
}

class _ContentCardWebState extends State<ContentCardWeb> {
  bool _isHovered = false;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final playIconSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );
    
    final cardPadding = ResponsiveUtils.getResponsivePadding(context, AppSpacing.small);
    final borderRadius = ResponsiveUtils.getResponsivePadding(context, AppSpacing.radiusMedium);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          elevation: _isHovered ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(
                        image: ImageHelper.getImageProvider(
                          widget.item.coverImage,
                          fallbackAsset: ImageHelper.getFallbackAsset(
                            int.tryParse(widget.item.id) ?? 0,
                          ),
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            ImageHelper.getFallbackAsset(
                              int.tryParse(widget.item.id) ?? 0,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.music_note,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Play button overlay
                      if (_isHovered)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: IconButton(
                              icon: Icon(
                                Icons.play_circle_filled,
                                size: playIconSize,
                                color: Colors.white,
                              ),
                              onPressed: widget.onPlay,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content Info
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusMedium),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textInverse,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            widget.item.creator,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textInverse.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (widget.item.duration != null ||
                          widget.item.plays > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.item.duration != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 12, color: AppColors.textInverse.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(widget.item.duration),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textInverse.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.item.duration != null && widget.item.plays > 0)
                              const SizedBox(width: 12),
                            if (widget.item.plays > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, size: 12, color: AppColors.textInverse.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.item.plays}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textInverse.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
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

