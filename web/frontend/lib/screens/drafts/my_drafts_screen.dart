import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/content_draft.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../utils/responsive_grid_delegate.dart';

/// My Drafts Screen - Shows all user's saved drafts for videos, audio, posts, and quotes
class MyDraftsScreen extends StatefulWidget {
  const MyDraftsScreen({super.key});

  @override
  State<MyDraftsScreen> createState() => _MyDraftsScreenState();
}

class _MyDraftsScreenState extends State<MyDraftsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ContentDraft> _allDrafts = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _draftTypes = ['all', 'video_podcast', 'audio_podcast', 'community_post', 'quote_post'];
  final List<String> _tabLabels = ['All', 'Videos', 'Audio', 'Posts', 'Quotes'];
  final List<IconData> _tabIcons = [
    Icons.folder_outlined,
    Icons.videocam_outlined,
    Icons.mic_outlined,
    Icons.article_outlined,
    Icons.format_quote_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _draftTypes.length, vsync: this);
    _loadDrafts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final drafts = await ApiService().getDrafts();
      if (mounted) {
        setState(() {
          _allDrafts = drafts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ContentDraft> _getFilteredDrafts(String type) {
    if (type == 'all') return _allDrafts;
    return _allDrafts.where((d) => d.draftType.value == type).toList();
  }

  Future<void> _deleteDraft(ContentDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: Text('Are you sure you want to delete "${draft.title ?? 'Untitled'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorMain),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService().deleteDraft(draft.id);
        if (mounted) {
          setState(() {
            _allDrafts.removeWhere((d) => d.id == draft.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft deleted successfully'),
              backgroundColor: AppColors.successMain,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete draft: $e'),
              backgroundColor: AppColors.errorMain,
            ),
          );
        }
      }
    }
  }

  void _openDraft(ContentDraft draft) {
    try {
      // Navigate to appropriate editor based on draft type
      switch (draft.draftType) {
        case DraftType.videoPodcast:
          if (draft.originalMediaUrl == null || draft.originalMediaUrl!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video URL is missing. Cannot open draft.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          context.push('/video-editor', extra: {
            'videoUrl': draft.originalMediaUrl,
            'draftId': draft.id,
            'editingState': draft.editingState,
          });
          break;
        case DraftType.audioPodcast:
          if (draft.originalMediaUrl == null || draft.originalMediaUrl!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio URL is missing. Cannot open draft.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          context.push('/audio-editor', extra: {
            'audioUrl': draft.originalMediaUrl,
            'draftId': draft.id,
            'editingState': draft.editingState,
          });
          break;
        case DraftType.communityPost:
          context.push('/create-post', extra: {
            'draftId': draft.id,
            'title': draft.title,
            'content': draft.content,
            'category': draft.category,
          });
          break;
        case DraftType.quotePost:
          context.push('/quote', extra: {
            'draftId': draft.id,
            'content': draft.content,
          });
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open draft: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildDraftCard(ContentDraft draft) {
    final typeInfo = _getDraftTypeInfo(draft.draftType.value);
    final createdAt = draft.createdAt;
    final timeAgo = _getTimeAgo(createdAt);

    return SectionContainer(
      showShadow: true,
      child: InkWell(
        onTap: () => _openDraft(draft),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail or icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: typeInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: draft.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          draft.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            typeInfo['icon'],
                            size: 36,
                            color: typeInfo['color'],
                          ),
                        ),
                      )
                    : Icon(
                        typeInfo['icon'],
                        size: 36,
                        color: typeInfo['color'],
                      ),
              ),
              const SizedBox(width: AppSpacing.medium),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.small,
                            vertical: AppSpacing.tiny,
                          ),
                          decoration: BoxDecoration(
                            color: typeInfo['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            typeInfo['label'],
                            style: AppTypography.caption.copyWith(
                              color: typeInfo['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      draft.title ?? 'Untitled Draft',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (draft.description != null || draft.content != null) ...[
                      const SizedBox(height: AppSpacing.tiny),
                      Text(
                        draft.description ?? draft.content ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (draft.duration != null) ...[
                      const SizedBox(height: AppSpacing.tiny),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: AppSpacing.tiny),
                          Text(
                            _formatDuration(draft.duration!),
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
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.warmBrown),
                    onPressed: () => _openDraft(draft),
                    tooltip: 'Continue Editing',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.errorMain),
                    onPressed: () => _deleteDraft(draft),
                    tooltip: 'Delete Draft',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getDraftTypeInfo(String type) {
    switch (type) {
      case 'video_podcast':
        return {'icon': Icons.videocam_outlined, 'color': AppColors.primaryMain, 'label': 'Video'};
      case 'audio_podcast':
        return {'icon': Icons.mic_outlined, 'color': AppColors.accentMain, 'label': 'Audio'};
      case 'community_post':
        return {'icon': Icons.article_outlined, 'color': AppColors.warmBrown, 'label': 'Post'};
      case 'quote_post':
        return {'icon': Icons.format_quote_outlined, 'color': AppColors.successMain, 'label': 'Quote'};
      default:
        return {'icon': Icons.drafts_outlined, 'color': AppColors.textSecondary, 'label': 'Draft'};
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState(String type) {
    final typeInfo = type == 'all'
        ? {'icon': Icons.folder_open_outlined, 'label': 'drafts'}
        : _getDraftTypeInfo(type);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.extraLarge * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative circles background
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown.withOpacity(0.05),
                        AppColors.accentMain.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warmBrown.withOpacity(0.08),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown.withOpacity(0.15),
                        AppColors.accentMain.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    type == 'all' ? Icons.folder_open_outlined : typeInfo['icon'],
                    size: 36,
                    color: AppColors.warmBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'No ${type == 'all' ? 'drafts' : typeInfo['label'].toString().toLowerCase() + ' drafts'} yet',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Your saved drafts will appear here',
              style: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            // Create button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warmBrown, AppColors.accentMain],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/create'),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Create Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = ResponsiveGridDelegate.getMaxContentWidth(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.warmBrown, AppColors.accentMain],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(Icons.drafts_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: StyledPageHeader(
                        title: 'My Drafts',
                        size: StyledPageHeaderSize.h2,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppColors.warmBrown),
                      onPressed: _loadDrafts,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),

                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      color: AppColors.warmBrown,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: List.generate(_tabLabels.length, (index) {
                      final draftsCount = _getFilteredDrafts(_draftTypes[index]).length;
                      return Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_tabIcons[index], size: 18),
                            const SizedBox(width: AppSpacing.small),
                            Text(_tabLabels[index]),
                            if (draftsCount > 0) ...[
                              const SizedBox(width: AppSpacing.small),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.small,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$draftsCount',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // Content
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: AppColors.warmBrown),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: AppColors.errorMain),
                                  const SizedBox(height: AppSpacing.medium),
                                  Text(
                                    'Failed to load drafts',
                                    style: AppTypography.heading4.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    _error!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.large),
                                  ElevatedButton.icon(
                                    onPressed: _loadDrafts,
                                    icon: Icon(Icons.refresh),
                                    label: Text('Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warmBrown,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: _draftTypes.map((type) {
                                final drafts = _getFilteredDrafts(type);
                                if (drafts.isEmpty) {
                                  return _buildEmptyState(type);
                                }
                                return ListView.separated(
                                  padding: EdgeInsets.only(bottom: AppSpacing.extraLarge),
                                  itemCount: drafts.length,
                                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.medium),
                                  itemBuilder: (context, index) => _buildDraftCard(drafts[index]),
                                );
                              }).toList(),
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

