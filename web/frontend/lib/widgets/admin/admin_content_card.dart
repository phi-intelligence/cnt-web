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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        side: BorderSide(
          color: isSelected 
              ? AppColors.warmBrown 
              : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              // Selection checkbox (if enabled)
              if (onSelectionChanged != null) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged?.call(value ?? false),
                  activeColor: AppColors.warmBrown,
                ),
                const SizedBox(width: AppSpacing.small),
              ],

              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  color: AppColors.backgroundSecondary,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  child: thumbnail != null
                      ? Image(
                          image: ImageHelper.getImageProvider(thumbnail),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),

              // Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.heading4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        AdminStatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.tiny),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: AppSpacing.iconSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.tiny),
                        Expanded(
                          child: Text(
                            creatorName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (date != null) ...[
                      const SizedBox(height: AppSpacing.tiny),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: AppSpacing.iconSizeSmall,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.tiny),
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions - Approve/Reject buttons (pill-shaped)
              if (showApproveReject && (onApprove != null || onReject != null)) ...[
                SizedBox(width: isMobile ? AppSpacing.tiny : AppSpacing.small),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
                    children: [
                      if (onApprove != null)
                        StyledPillButton(
                          label: 'Approve',
                          icon: Icons.check,
                          onPressed: onApprove,
                          variant: StyledPillButtonVariant.filled,
                          width: isMobile ? null : 100,
                        ),
                      if (onApprove != null && onReject != null)
                        SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.tiny),
                      if (onReject != null)
                        StyledPillButton(
                          label: 'Reject',
                          icon: Icons.close,
                          onPressed: onReject,
                          variant: StyledPillButtonVariant.outlined,
                          width: isMobile ? null : 100,
                        ),
                    ],
                  ),
                ),
              ],
              // Actions - Delete/Archive buttons (pill-shaped)
              if (showDeleteArchive && (onDelete != null || onArchive != null)) ...[
                SizedBox(width: isMobile ? AppSpacing.tiny : AppSpacing.small),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
                    children: [
                      if (onArchive != null)
                        StyledPillButton(
                          label: 'Archive',
                          icon: Icons.archive_outlined,
                          onPressed: onArchive,
                          variant: StyledPillButtonVariant.outlined,
                          width: isMobile ? null : 100,
                        ),
                      if (onArchive != null && onDelete != null)
                        SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.tiny),
                      if (onDelete != null)
                        StyledPillButton(
                          label: 'Delete',
                          icon: Icons.delete_outline,
                          onPressed: onDelete,
                          variant: StyledPillButtonVariant.outlined,
                          width: isMobile ? null : 100,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final type = item['type'] as String? ?? 'unknown';
    return Container(
      color: AppColors.backgroundSecondary,
      child: Center(
        child: Text(
          _getTypeIcon(type),
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
