import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../shared/image_helper.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_utils.dart';
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
              _buildActions(isMobile),
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

  Widget _buildActions(bool isMobile) {
    // Pending Actions: Approve / Reject
    if (showApproveReject && (onApprove != null || onReject != null)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReject != null)
            _buildActionButton(
              icon: Icons.close,
              color: AppColors.errorMain,
              tooltip: 'Reject',
              onPressed: onReject!,
            ),
          const SizedBox(width: 8),
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
    
    // Approved Actions: Delete / Archive
    if (showDeleteArchive && (onDelete != null || onArchive != null)) {
       return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
