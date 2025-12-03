import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/format_utils.dart';
import '../../services/api_service.dart';
import '../shared/image_helper.dart';

/// Instagram-like post card widget
/// Shows photo posts with like, comment, share, and bookmark functionality
class InstagramPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;

  const InstagramPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
  });

  @override
  State<InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<InstagramPostCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isAnimating = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['is_liked'] ?? false;
    _likesCount = widget.post['likes_count'] ?? 0;

    // Animation for like heart
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    setState(() {
      if (_isLiked) {
        _likesCount--;
      } else {
        _likesCount++;
        // Animate heart on like
        _isAnimating = true;
        _animationController.forward().then((_) {
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isAnimating = false;
              });
            }
          });
        });
      }
      _isLiked = !_isLiked;
    });

    // Call callback if provided
    if (widget.onLike != null) {
      widget.onLike!();
    }
  }

  String _getImageUrl() {
    final imageUrl = widget.post['image_url'];
    if (imageUrl == null) return '';
    
    // If image_url starts with 'images/', treat as asset path
    // Otherwise, treat as full media URL
    if (imageUrl.toString().startsWith('images/')) {
      // Use asset path for images in assets folder
      return imageUrl.toString().replaceFirst('images/', 'assets/images/');
    }
    
    // Otherwise, use API service to get media URL
    final apiService = ApiService();
    return apiService.getMediaUrl(imageUrl.toString());
  }

  Widget _buildProfilePicture(String? avatarUrl, String userName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: ImageHelper.getImageProvider(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: avatarUrl.isEmpty 
            ? Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    }
    
    // Fallback: Use first letter of username as avatar
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primaryMain,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
        style: AppTypography.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.post['user_name'] ?? 'User';
    final userAvatar = widget.post['user_avatar'];
    final content = widget.post['content'] ?? widget.post['title'] ?? '';
    final imageUrl = widget.post['image_url'];
    final postType = widget.post['post_type'] ?? 'image'; // 'text' or 'image'
    final createdAt = widget.post['created_at'];
    final commentsCount = widget.post['comments_count'] ?? 0;
    final DateTime? createdDate = createdAt != null
        ? (createdAt is DateTime
            ? createdAt
            : DateTime.tryParse(createdAt.toString()))
        : null;
    
    // For text posts, don't show image even if image_url exists (image is for carousel only)
    final isTextPost = postType == 'text';
    final shouldShowImage = !isTextPost && imageUrl != null && imageUrl.toString().isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Profile picture, username, three dots menu
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: Row(
              children: [
                _buildProfilePicture(userAvatar, userName),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    userName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textInverse,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  color: AppColors.textInverse,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Show options menu
                  },
                ),
              ],
            ),
          ),

          // Content section: Image for image posts, Text for text posts
          if (shouldShowImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: GestureDetector(
                onDoubleTap: _handleLike, // Double tap to like
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                      // Main image - reduced size on web
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: imageUrl.toString().startsWith('assets/')
                            ? Image.asset(
                                imageUrl.toString(),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.backgroundTertiary,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppColors.textTertiary,
                                      size: 48,
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                _getImageUrl(),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: AppColors.backgroundTertiary,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.primaryMain,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.backgroundTertiary,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppColors.textTertiary,
                                      size: 48,
                                    ),
                                  );
                                },
                              ),
                      ),
                    // Animated heart overlay on double tap
                    if (_isAnimating)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Icon(
                          Icons.favorite,
                          size: 80,
                          color: AppColors.errorMain,
                        ),
                      ),
                  ],
                ),
              ),
            )
          else if (isTextPost)
            // Text post content (Facebook-style) - show text prominently
            Container(
              padding: EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (if different from content)
                  if (widget.post['title'] != null && 
                      widget.post['title'].toString().trim().isNotEmpty &&
                      widget.post['title'] != content)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.medium),
                      child: Text(
                        widget.post['title'].toString(),
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Content text (quote)
                  Text(
                    content,
                    style: AppTypography.body.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Footer: Like, comment, share, bookmark icons
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.tiny,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.errorMain : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: _handleLike,
                  padding: EdgeInsets.all(AppSpacing.tiny),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: AppSpacing.tiny),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: widget.onComment,
                  padding: EdgeInsets.all(AppSpacing.tiny),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: AppSpacing.tiny),
                IconButton(
                  icon: const Icon(Icons.send_outlined, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: widget.onShare,
                  padding: EdgeInsets.all(AppSpacing.tiny),
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: widget.onBookmark,
                  padding: EdgeInsets.all(AppSpacing.tiny),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Likes count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
            child: Text(
              '${_likesCount == 0 ? 'No' : _likesCount} like${_likesCount == 1 ? '' : 's'}',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.tiny),

          // Caption: Username + content (truncated for compact display)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$userName ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),

          // Timestamp (moved inline, comments count removed for compactness)
          if (createdDate != null) ...[
            const SizedBox(height: AppSpacing.tiny),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
              child: Text(
                FormatUtils.formatRelativeTime(createdDate),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],

          SizedBox(height: AppSpacing.tiny),
        ],
      ),
      ),
    );
  }
}

