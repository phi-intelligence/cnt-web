import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../shared/image_helper.dart';
import '../../utils/responsive_utils.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../screens/video/video_player_full_screen.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import 'admin_status_badge.dart';

/// Content card for admin management pages
/// Displays content item with thumbnail, info, status, and actions
class AdminContentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onTap;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool showApproveReject;
  final bool showDeleteArchive;

  const AdminContentCard({
    super.key,
    required this.item,
    this.onApprove,
    this.onReject,
    this.onDelete,
    this.onArchive,
    this.onTap,
    this.isSelected = false,
    this.onSelectionChanged,
    this.showApproveReject = true,
    this.showDeleteArchive = false,
  });

  String _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'podcast':
        return '🎙️';
      case 'movie':
        return '🎬';
      case 'music':
        return '🎵';
      case 'community_post':
        return '📝';
      default:
        return '📄';
    }
  }

  String? _getThumbnail() {
    return item['cover_image'] as String? ?? 
           item['thumbnail_url'] as String? ?? 
           item['image_url'] as String?;
  }

  bool _hasPlayableContent() {
    final audioUrl = item['audio_url'] as String?;
    final videoUrl = item['video_url'] as String?;
    final imageUrl = item['image_url'] as String?;
    return (audioUrl != null && audioUrl.toString().isNotEmpty) ||
           (videoUrl != null && videoUrl.toString().isNotEmpty) ||
           (imageUrl != null && imageUrl.toString().isNotEmpty);
  }

  String? _getContentType() {
    final type = item['type'] as String? ?? '';
    final audioUrl = item['audio_url'] as String?;
    final videoUrl = item['video_url'] as String?;
    final imageUrl = item['image_url'] as String?;
    
    if (type == 'community_post' && imageUrl != null && imageUrl.toString().isNotEmpty) {
      return 'image';
    }
    if (videoUrl != null && videoUrl.toString().isNotEmpty) {
      return 'video';
    }
    if (audioUrl != null && audioUrl.toString().isNotEmpty) {
      return 'audio';
    }
    return null;
  }

  String _getMediaUrl(String? path) {
    if (path == null || path.toString().isEmpty) return '';
    final apiService = ApiService();
    return apiService.getMediaUrl(path.toString());
  }

  ContentItem _itemToContentItem() {
    final id = item['id'];
    final title = item['title'] as String? ?? 'Untitled';
    final description = item['description'] as String?;
    final audioUrl = item['audio_url'] as String?;
    final coverImage = item['cover_image'] as String?;
    final creatorName = item['creator_name'] as String? ?? 
                       item['user']?['name'] as String? ?? 
                       'Unknown';
    final duration = item['duration'] as int?;
    
    // Get full media URL if audioUrl exists
    String? fullAudioUrl;
    if (audioUrl != null && audioUrl.toString().isNotEmpty) {
      fullAudioUrl = _getMediaUrl(audioUrl);
    }
    
    // Get full media URL for cover image if it exists
    String? fullCoverImage;
    if (coverImage != null && coverImage.toString().isNotEmpty) {
      fullCoverImage = _getMediaUrl(coverImage);
    }
    
    // Parse created_at with fallback to current time
    DateTime createdAt;
    if (item['created_at'] != null) {
      final parsedDate = DateTime.tryParse(item['created_at'].toString());
      createdAt = parsedDate ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    
    return ContentItem(
      id: id?.toString() ?? '',
      title: title,
      description: description,
      audioUrl: fullAudioUrl,
      coverImage: fullCoverImage,
      creator: creatorName,
      category: item['type'] as String? ?? 'music',
      createdAt: createdAt,
      duration: duration != null ? Duration(seconds: duration) : null,
    );
  }

  void _handlePreview(BuildContext context) async {
    final contentType = _getContentType();
    if (contentType == null) return;
    
    final contentId = item['id'];
    if (contentId == null) return;
    
    try {
      // Validate content exists before attempting to view
      // This prevents 404 errors when content was deleted
      final type = item['type'] as String? ?? '';
      final apiService = ApiService();
      
      if (type == 'podcast') {
        // Verify podcast exists by fetching it
        try {
          await apiService.getPodcast(contentId);
        } catch (e) {
          if (e.toString().contains('404') || 
              e.toString().contains('not found') ||
              e.toString().contains('Failed to get podcast')) {
            _showError(context, 'This content is no longer available. It may have been deleted.');
            return;
          }
          rethrow;
        }
      } else if (type == 'movie') {
        // Verify movie exists
        try {
          await apiService.getMovie(contentId);
        } catch (e) {
          if (e.toString().contains('404') || 
              e.toString().contains('not found') ||
              e.toString().contains('Failed to get movie')) {
            _showError(context, 'This content is no longer available. It may have been deleted.');
            return;
          }
          rethrow;
        }
      }
      // Similar validation could be added for other content types if needed
      
      // Proceed with preview/playback
      if (contentType == 'audio') {
        // Use audio player provider to play content
        // This will automatically show the compact music player
        try {
          final contentItem = _itemToContentItem();
          if (contentItem.audioUrl == null || contentItem.audioUrl!.isEmpty) {
            _showError(context, 'Audio URL is not available for this content.');
            return;
          }
          
          // Play content using audio player provider
          // This will show the compact player and start playback
          Provider.of<AudioPlayerState>(context, listen: false)
              .playContent(contentItem);
        } catch (e) {
          LoggerService.e('Error playing audio: $e');
          _showError(context, 'Failed to play audio. Please try again.');
        }
      } else if (contentType == 'video') {
        final videoType = item['type'] as String? ?? '';
        if (videoType == 'movie') {
          // Show movie in video player dialog
          final videoUrl = item['video_url'] as String?;
          if (videoUrl != null && videoUrl.toString().isNotEmpty) {
            final fullVideoUrl = _getMediaUrl(videoUrl);
            final title = item['title'] as String? ?? 'Movie';
            final creator = item['creator_name'] as String? ?? 
                          item['user']?['name'] as String? ?? 
                          'Unknown';
            final duration = (item['duration'] as int?) ?? 0;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerFullScreen(
                  videoId: contentId.toString(),
                  title: title,
                  author: creator,
                  duration: duration,
                  gradientColors: const [AppColors.backgroundPrimary, AppColors.backgroundSecondary],
                  videoUrl: fullVideoUrl,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            );
          }
        } else {
          // Podcast video
          context.push('/player/video/$contentId');
        }
      } else if (contentType == 'image') {
        final imageUrl = item['image_url'] as String?;
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final fullImageUrl = _getMediaUrl(imageUrl);
          showDialog(
            context: context,
            barrierColor: Colors.black87,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        fullImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.white, size: 48),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.e('Error previewing content: $e');
      _showError(context, 'Failed to load content. Please try again.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorMain,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? 'unknown';
    final title = item['title'] as String? ?? 'Untitled';
    final creatorName = item['creator_name'] as String? ?? 
                       item['user']?['name'] as String? ?? 
                       'Unknown';
    final createdAt = item['created_at'] as String?;
    final status = item['status'] as String? ?? 'pending';
    final thumbnail = _getThumbnail();
    final isMobile = ResponsiveUtils.isMobile(context);

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (e) {
        // Ignore parse errors
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected 
            ? Border.all(color: AppColors.warmBrown, width: 2) 
            : Border.all(color: Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selection checkbox (if enabled)
              if (onSelectionChanged != null) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged?.call(value ?? false),
                  activeColor: AppColors.warmBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 8),
              ],

              // Thumbnail
              Container(
                width: 72, 
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.backgroundSecondary,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnail != null
                      ? Image(
                          image: ImageHelper.getImageProvider(thumbnail),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(type);
                          },
                        )
                      : _buildPlaceholder(type),
                ),
              ),
              const SizedBox(width: 16),

              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // Status Badge first if mobile, or inline? 
                        // Let's keep title prominent.
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.heading4.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isMobile) AdminStatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (isMobile) ...[
                           AdminStatusBadge(status: status),
                           const SizedBox(width: 8),
                        ],
                        _buildInfoIcon(Icons.person_outline),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            creatorName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(width: 12),
                          _buildInfoIcon(Icons.calendar_today_outlined),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              const SizedBox(width: 16),
              _buildActions(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoIcon(IconData icon) {
    return Icon(
      icon,
      size: 14,
      color: AppColors.textTertiary,
    );
  }

  Widget _buildActions(BuildContext context, bool isMobile) {
    final hasPreview = _hasPlayableContent();
    final contentType = _getContentType();
    final previewIcon = contentType == 'image' ? Icons.visibility : Icons.play_arrow;
    final previewTooltip = contentType == 'image' ? 'View Image' : 
                           contentType == 'video' ? 'Play Video' : 'Play Audio';
    
    // Pending Actions: Preview / Approve / Reject
    if (showApproveReject && (onApprove != null || onReject != null)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPreview)
            _buildActionButton(
              icon: previewIcon,
              color: AppColors.warmBrown,
              tooltip: previewTooltip,
              onPressed: () => _handlePreview(context),
            ),
          if (hasPreview) const SizedBox(width: 8),
          if (onReject != null)
            _buildActionButton(
              icon: Icons.close,
              color: AppColors.errorMain,
              tooltip: 'Reject',
              onPressed: onReject!,
            ),
          if (onReject != null) const SizedBox(width: 8),
          if (onApprove != null)
             _buildActionButton(
              icon: Icons.check,
              color: AppColors.successMain,
              tooltip: 'Approve',
              onPressed: onApprove!,
              isFilled: true, 
            ),
        ],
      );
    }
    
    // Approved Actions: Preview / Delete / Archive
    if (showDeleteArchive && (onDelete != null || onArchive != null)) {
       return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPreview)
            _buildActionButton(
              icon: previewIcon,
              color: AppColors.warmBrown,
              tooltip: previewTooltip,
              onPressed: () => _handlePreview(context),
            ),
          if (hasPreview) const SizedBox(width: 8),
          if (onArchive != null)
            _buildActionButton(
              icon: Icons.archive_outlined,
              color: AppColors.textSecondary,
              tooltip: 'Archive',
              onPressed: onArchive!,
            ),
          if (onArchive != null && onDelete != null)
            const SizedBox(width: 8),
          if (onDelete != null)
            _buildActionButton(
              icon: Icons.delete_outline,
              color: AppColors.textSecondary,
              hoverColor: AppColors.errorMain,
              tooltip: 'Delete',
              onPressed: onDelete!,
            ),
        ],
      );
    }
    
    // If no actions but has preview
    if (hasPreview) {
      return _buildActionButton(
        icon: previewIcon,
        color: AppColors.warmBrown,
        tooltip: previewTooltip,
        onPressed: () => _handlePreview(context),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    Color? hoverColor,
    bool isFilled = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isFilled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(isFilled ? 20 : 50),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isFilled ? 20 : 50),
          hoverColor: (hoverColor ?? color).withOpacity(0.1),
          child: Container(
            width: 40,
            height: 40,
            decoration: isFilled ? null : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: isFilled ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type) {
    return Container(
      color: AppColors.backgroundSecondary,
      child: Center(
        child: Text(
          _getTypeIcon(type),
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}
