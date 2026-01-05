import 'package:flutter/material.dart';
import '../../models/content_item.dart';
import '../shared/image_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Disc-style card widget for web
/// Shows circular image with label below (similar to mobile)
class DiscCardWeb extends StatefulWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final double size;

  const DiscCardWeb({
    super.key,
    required this.item,
    this.onTap,
    this.onPlay,
    this.size = 160.0,
  });

  @override
  State<DiscCardWeb> createState() => _DiscCardWebState();
}

class _DiscCardWebState extends State<DiscCardWeb> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap ?? widget.onPlay,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular Disc Image
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    widget.item.coverImage != null
                        ? Image(
                            image: ImageHelper.getImageProvider(
                              widget.item.coverImage,
                              fallbackAsset: ImageHelper.getFallbackAsset(
                                int.tryParse(widget.item.id) ?? 0,
                              ),
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackImage();
                            },
                          )
                        : Image.asset(
                            ImageHelper.getFallbackAsset(
                              int.tryParse(widget.item.id) ?? 0,
                            ),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackImage();
                            },
                          ),
                    // Play button overlay on hover
                    if (_isHovered)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: widget.size * 0.4,
                            color: AppColors.backgroundPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label below disc
            SizedBox(
              width: widget.size + 20,
              child: Text(
                widget.item.title,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.2, // Tighter line height
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Optional: Creator name (smaller text)
            if (widget.item.creator.isNotEmpty) ...[
              const SizedBox(height: 1),
              SizedBox(
                width: widget.size + 20,
                child: Text(
                  widget.item.creator,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.1, // Tighter line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.textTertiary,
        size: widget.size * 0.3,
      ),
    );
  }
}

