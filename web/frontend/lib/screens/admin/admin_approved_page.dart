import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_content_card.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';

/// Admin Approved Page - Shows all approved content with tabs
/// Tabs: All, Podcasts, Movies, Posts
class AdminApprovedPage extends StatefulWidget {
  final int initialTabIndex;
  
  const AdminApprovedPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminApprovedPage> createState() => _AdminApprovedPageState();
}

class _AdminApprovedPageState extends State<AdminApprovedPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  // Content lists
  List<dynamic> _allContent = [];
  List<dynamic> _podcasts = [];
  List<dynamic> _movies = [];
  List<dynamic> _posts = [];
  
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
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      // Load all approved content types in parallel
      final results = await Future.wait([
        _api.getAllContent(contentType: 'podcast', status: 'approved'),
        _api.getAllContent(contentType: 'movie', status: 'approved'),
        _api.getAllContent(contentType: 'community_post', status: 'approved'),
      ]);

      if (mounted) {
        setState(() {
          _podcasts = results[0];
          _movies = results[1];
          _posts = results[2];
          _allContent = [..._podcasts, ..._movies, ..._posts];
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

  Future<void> _handleDelete(dynamic item) async {
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;
    final title = item['title'] as String? ?? 'this content';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Content', style: AppTypography.heading3),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: AppTypography.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        actions: [
          StyledPillButton(
            label: 'Cancel',
            icon: Icons.close,
            onPressed: () => Navigator.pop(context, false),
            variant: StyledPillButtonVariant.outlined,
            width: 100,
          ),
          const SizedBox(width: AppSpacing.small),
          StyledPillButton(
            label: 'Delete',
            icon: Icons.delete_outline,
            onPressed: () => Navigator.pop(context, true),
            variant: StyledPillButtonVariant.outlined, // Outlined Brown for Negative actions per plan
            width: 100,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteContent(contentType, contentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Content deleted successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );
        _loadAllContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting content: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _handleArchive(dynamic item) async {
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;
    final title = item['title'] as String? ?? 'this content';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive Content', style: AppTypography.heading3),
        content: Text(
          'Are you sure you want to archive "$title"? It will be hidden from users.',
          style: AppTypography.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.archiveContent(contentType, contentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Content archived successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );
        _loadAllContent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error archiving content: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  List<dynamic> _getFilteredPodcasts() {
    if (_podcastFilter == 'All') return _podcasts;
    if (_podcastFilter == 'Audio') {
      return _podcasts.where((p) => p['video_url'] == null || (p['video_url'] as String).isEmpty).toList();
    }
    if (_podcastFilter == 'Video') {
      return _podcasts.where((p) => p['video_url'] != null && (p['video_url'] as String).isNotEmpty).toList();
    }
    return _podcasts;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.warmBrown,
              labelColor: AppColors.warmBrown,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'All (${_allContent.length})'),
                Tab(text: 'Podcasts (${_podcasts.length})'),
                Tab(text: 'Movies (${_movies.length})'),
                Tab(text: 'Posts (${_posts.length})'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContentList(_allContent, 'approved content'),
                _buildPodcastsTab(),
                _buildContentList(_movies, 'movies'),
                _buildContentList(_posts, 'posts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.successMain.withOpacity(0.08),
            AppColors.warmBrown.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.successMain.withOpacity(0.2),
                      AppColors.warmBrown.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.successMain,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approved Content',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage published content - delete or archive',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StyledPillButton(
                label: 'Refresh',
                icon: Icons.refresh,
                variant: StyledPillButtonVariant.outlined,
                onPressed: _loadAllContent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title or creator...',
              prefixIcon: Icon(Icons.search, color: AppColors.warmBrown),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastsTab() {
    final filteredPodcasts = _getFilteredPodcasts();
    
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          color: Colors.white,
          child: Row(
            children: [
              Text('Filter:', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.small),
              _buildFilterChip('All', _podcastFilter == 'All'),
              const SizedBox(width: AppSpacing.tiny),
              _buildFilterChip('Audio', _podcastFilter == 'Audio'),
              const SizedBox(width: AppSpacing.tiny),
              _buildFilterChip('Video', _podcastFilter == 'Video'),
            ],
          ),
        ),
        Expanded(
          child: _buildContentList(filteredPodcasts, 'podcasts'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _podcastFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warmBrown : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.warmBrown : AppColors.borderPrimary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContentList(List<dynamic> content, String contentType) {
    final filtered = _applySearch(content);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.warmBrown),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.errorMain),
              const SizedBox(height: AppSpacing.medium),
              Text('Error loading content', style: AppTypography.heading3),
              const SizedBox(height: AppSpacing.small),
              Text(_error!, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.large),
              StyledPillButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _loadAllContent,
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: EmptyState(
          icon: Icons.folder_open_outlined,
          title: 'No $contentType',
          message: 'No approved $contentType found',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllContent,
      color: AppColors.warmBrown,
      child: ListView.builder(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == filtered.length - 1 ? 0 : AppSpacing.small,
            ),
            child: AdminContentCard(
              item: item,
              showApproveReject: false,
              showDeleteArchive: true,
              onDelete: () => _handleDelete(item),
              // onArchive: () => _handleArchive(item), // Removed per user request
            ),
          );
        },
      ),
    );
  }
}

