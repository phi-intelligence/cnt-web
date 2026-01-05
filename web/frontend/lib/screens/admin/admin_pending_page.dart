import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_content_card.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/web/styled_filter_chip.dart';

/// Reject reason dialog
class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Reject Content', style: AppTypography.heading3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: 'Reason (optional)',
          hintText: 'Enter reason for rejection...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
        maxLines: 3,
      ),
      actions: [
        StyledPillButton(
          label: 'Cancel',
          icon: Icons.close,
          onPressed: () => Navigator.pop(context),
          variant: StyledPillButtonVariant.outlined,
          width: 100,
        ),
        const SizedBox(width: AppSpacing.small),
        StyledPillButton(
          label: 'Reject',
          icon: Icons
              .check, // Or warning icon? Sticking to check for "Confirm Action" or keep close? Using 'check' as 'Confirm Rejection'.
          onPressed: () => Navigator.pop(context, _controller.text),
          variant: StyledPillButtonVariant.filled,
          width: 100,
        ),
      ],
    );
  }
}

/// Admin Pending Page - Shows all pending content with tabs
/// Tabs: All, Podcasts, Movies, Posts
class AdminPendingPage extends StatefulWidget {
  final int initialTabIndex;

  const AdminPendingPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminPendingPage> createState() => _AdminPendingPageState();
}

class _AdminPendingPageState extends State<AdminPendingPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  // Content lists
  List<dynamic> _allContent = [];
  List<dynamic> _podcasts = [];
  List<dynamic> _movies = [];
  List<dynamic> _posts = [];
  List<dynamic> _music = [];
  List<dynamic> _events = [];

  // Loading states
  bool _isLoading = true;
  String? _error;

  // Podcast filter (All, Audio, Video)
  String _podcastFilter = 'All';

  // Search
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
        setState(() {}); // Update UI when tab changes
      }
    });
    _loadAllContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all pending content types with individual error handling
      final List<Future<List<dynamic>>> futures = [
        _api.getAllContent(contentType: 'podcast', status: 'pending')
            .catchError((e) {
          LoggerService.e('Error loading podcasts: $e');
          return <dynamic>[];
        }),
        _api.getAllContent(contentType: 'movie', status: 'pending')
            .catchError((e) {
          LoggerService.e('Error loading movies: $e');
          return <dynamic>[];
        }),
        _api.getAllContent(contentType: 'community_post', status: 'pending')
            .catchError((e) {
          LoggerService.e('Error loading posts: $e');
          return <dynamic>[];
        }),
        _api.getAllContent(contentType: 'music', status: 'pending')
            .catchError((e) {
          LoggerService.e('Error loading music: $e');
          return <dynamic>[];
        }),
        _api.getAllContent(contentType: 'event', status: 'pending')
            .catchError((e) {
          LoggerService.e('Error loading events: $e');
          return <dynamic>[];
        }),
      ];

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _podcasts = results[0];
          _movies = results[1];
          _posts = results[2];
          _music = results[3];
          _events = results[4];
          _allContent = [
            ..._podcasts,
            ..._movies,
            ..._posts,
            ..._music,
            ..._events
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.e('Error loading all content: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load content. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApprove(dynamic item) async {
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;

    try {
      final success = await _api.approveContent(contentType, contentId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Content approved successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );
        _loadAllContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(dynamic item) async {
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null) return;

    try {
      final success =
          await _api.rejectContent(contentType, contentId, reason: reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Content rejected'),
            backgroundColor: AppColors.warningMain,
          ),
        );
        _loadAllContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  List<dynamic> _getFilteredPodcasts() {
    if (_podcastFilter == 'All') return _podcasts;
    if (_podcastFilter == 'Audio') {
      return _podcasts
          .where((p) =>
              p['video_url'] == null || (p['video_url'] as String).isEmpty)
          .toList();
    }
    if (_podcastFilter == 'Video') {
      return _podcasts
          .where((p) =>
              p['video_url'] != null && (p['video_url'] as String).isNotEmpty)
          .toList();
    }
    return _podcasts;
  }

  List<dynamic> _getFilteredAllContent() {
    final filteredPodcasts = _getFilteredPodcasts();
    return [...filteredPodcasts, ..._movies, ..._posts, ..._music, ..._events];
  }

  List<dynamic> _applySearch(List<dynamic> content) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return content;
    return content.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final creator = (item['creator_name'] as String? ?? '').toLowerCase();
      return title.contains(query) || creator.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // Cream background match
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: _loadAllContent,
        color: AppColors.warmBrown,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(isDesktop),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                color: const Color(0xFFF5F0E8), // Match bg
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _tabController.index == 0, 0),
                      const SizedBox(width: 8),
                      _buildFilterChip('Podcasts', _tabController.index == 1, 1),
                      const SizedBox(width: 8),
                      _buildFilterChip('Movies', _tabController.index == 2, 2),
                      const SizedBox(width: 8),
                      _buildFilterChip('Posts', _tabController.index == 3, 3),
                      const SizedBox(width: 8),
                      _buildFilterChip('Music', _tabController.index == 4, 4),
                      const SizedBox(width: 8),
                      _buildFilterChip('Events', _tabController.index == 5, 5),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: const SizedBox(height: 16),
            ),

            // Tab Content - Use IndexedStack to switch between different sliver content
            _buildTabContentSliver(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, int index) {
    return StyledFilterChip(
      label: label,
      selected: isSelected,
      onTap: () {
        _tabController.animateTo(index);
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Approvals',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_allContent.length} pending items',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              StyledPillButton(
                label: 'Refresh',
                icon: Icons.refresh,
                variant: StyledPillButtonVariant.outlined,
                onPressed: _loadAllContent,
                width: 120, // compact width
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Field - Pill-shaped white search bar
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: _searchController,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by title or creator...',
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.warmBrown),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide:
                      const BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContentSliver(bool isDesktop) {
    switch (_tabController.index) {
      case 0: // All
        return _buildContentListSliver(
            _getFilteredAllContent(), 'All pending content', isDesktop);
      case 1: // Podcasts
        return _buildPodcastsTabSliver(isDesktop);
      case 2: // Movies
        return _buildContentListSliver(_movies, 'movies', isDesktop);
      case 3: // Posts
        return _buildContentListSliver(_posts, 'posts', isDesktop);
      case 4: // Music
        return _buildContentListSliver(_music, 'music', isDesktop);
      case 5: // Events
        return _buildContentListSliver(_events, 'events', isDesktop);
      default:
        return _buildContentListSliver(
            _getFilteredAllContent(), 'All pending content', isDesktop);
    }
  }

  Widget _buildPodcastsTabSliver(bool isDesktop) {
    final filteredPodcasts = _getFilteredPodcasts();

    return SliverMainAxisGroup(
      slivers: [
        // Filter chips for Podcast Type - Now scrollable
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text('Type:',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: AppSpacing.small),
                _buildPodcastTypeChip('All', _podcastFilter == 'All'),
                const SizedBox(width: 8),
                _buildPodcastTypeChip('Audio', _podcastFilter == 'Audio'),
                const SizedBox(width: 8),
                _buildPodcastTypeChip('Video', _podcastFilter == 'Video'),
              ],
            ),
          ),
        ),
        _buildContentListSliver(filteredPodcasts, 'podcasts', isDesktop),
      ],
    );
  }

  Widget _buildPodcastTypeChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _podcastFilter = label;
          });
        }
      },
      selectedColor: AppColors.warmBrown.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.warmBrown : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.warmBrown : AppColors.borderPrimary,
      ),
    );
  }

  Widget _buildContentListSliver(
      List<dynamic> content, String contentType, bool isDesktop) {
    final filtered = _applySearch(content);

    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.warmBrown),
              const SizedBox(height: 16),
              Text(
                'Loading content...',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.errorMain),
                const SizedBox(height: 16),
                Text('Error loading content', style: AppTypography.heading3),
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                StyledPillButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onPressed: _loadAllContent,
                  width: 120,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No pending $contentType',
            message: 'All $contentType have been reviewed',
          ),
        ),
      );
    }

    return isDesktop
        ? SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600, // Wide cards
                childAspectRatio: 2.5, // Similar ratio to User Management
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filtered[index];
                  return AdminContentCard(
                    item: item,
                    showApproveReject: true,
                    showDeleteArchive: false,
                    onApprove: () => _handleApprove(item),
                    onReject: () => _handleReject(item),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          )
        : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AdminContentCard(
                      item: item,
                      showApproveReject: true,
                      showDeleteArchive: false,
                      onApprove: () => _handleApprove(item),
                      onReject: () => _handleReject(item),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          );
  }
}
