import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/admin/admin_content_card.dart';
import '../../widgets/admin/admin_button.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';

/// Posts management page for approving/rejecting community posts
class AdminPostsPage extends StatefulWidget {
  const AdminPostsPage({super.key});

  @override
  State<AdminPostsPage> createState() => _AdminPostsPageState();
}

class _AdminPostsPageState extends State<AdminPostsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _content = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _selectedIndices = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedIndices.clear();
    });

    try {
      final content = await _api.getAllContent(
        contentType: 'community_post',
      );
      if (mounted) {
        setState(() {
          _content = content;
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

  Future<void> _handleApprove(int index) async {
    final item = _content[index];
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;

    try {
      final success = await _api.approveContent(contentType, contentId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post approved successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );
        _loadContent();
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

  Future<void> _handleReject(int index) async {
    final item = _content[index];
    final contentType = item['type'] as String;
    final contentId = item['id'] as int;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null) return;

    try {
      final success = await _api.rejectContent(contentType, contentId, reason: reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post rejected'),
            backgroundColor: AppColors.warningMain,
          ),
        );
        _loadContent();
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

  List<dynamic> get _filteredContent {
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isEmpty) return _content;
    return _content.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final creator = (item['creator_name'] as String? ?? '').toLowerCase();
      return title.contains(searchQuery) || creator.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Column(
              children: [
                // Header
                StyledPageHeader(
                  title: 'Community Posts Management',
                  size: StyledPageHeaderSize.h2,
                ),
                const SizedBox(height: AppSpacing.extraLarge),

                // Filter and Search Section
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search by title or creator...',
                          prefixIcon: const Icon(Icons.search),
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundPrimary,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      // Actions
                      Row(
                        children: [
                          const Spacer(),
                          StyledPillButton(
                            label: 'Refresh',
                            icon: Icons.refresh,
                            variant: StyledPillButtonVariant.outlined,
                            onPressed: _loadContent,
                          ),
                        ],
                      ),
                      // Bulk Actions
                      if (_selectedIndices.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.large),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMain.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            border: Border.all(
                              color: AppColors.primaryMain.withOpacity(0.3),
                            ),
                          ),
                          child: isMobile
                              ? Column(
                                  children: [
                                    Text(
                                      '${_selectedIndices.length} selected',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryMain,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.medium),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: StyledPillButton(
                                            label: 'Approve',
                                            icon: Icons.check,
                                            variant: StyledPillButtonVariant.outlined,
                                            onPressed: () async {
                                              for (final index in _selectedIndices.toList()) {
                                                await _handleApprove(index);
                                              }
                                              setState(() {
                                                _selectedIndices.clear();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.small),
                                        Expanded(
                                          child: StyledPillButton(
                                            label: 'Reject',
                                            icon: Icons.close,
                                            variant: StyledPillButtonVariant.outlined,
                                            onPressed: () async {
                                              for (final index in _selectedIndices.toList()) {
                                                await _handleReject(index);
                                              }
                                              setState(() {
                                                _selectedIndices.clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(
                                      '${_selectedIndices.length} selected',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryMain,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    StyledPillButton(
                                      label: 'Approve Selected',
                                      icon: Icons.check,
                                      variant: StyledPillButtonVariant.outlined,
                                      onPressed: () async {
                                        for (final index in _selectedIndices.toList()) {
                                          await _handleApprove(index);
                                        }
                                        setState(() {
                                          _selectedIndices.clear();
                                        });
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.small),
                                    StyledPillButton(
                                      label: 'Reject Selected',
                                      icon: Icons.close,
                                      variant: StyledPillButtonVariant.outlined,
                                      onPressed: () async {
                                        for (final index in _selectedIndices.toList()) {
                                          await _handleReject(index);
                                        }
                                        setState(() {
                                          _selectedIndices.clear();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryMain,
              ),
            ),
          )
        else if (_error != null)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.errorMain,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      'Error loading posts',
                      style: AppTypography.heading3,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      _error!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    StyledPillButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: _loadContent,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_filteredContent.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.large),
              child: EmptyState(
                icon: Icons.article_outlined,
                title: 'No posts',
                message: 'No community posts found',
              ),
            ),
          )
        else
          SliverPadding(
            padding: ResponsiveGridDelegate.getResponsivePadding(context).copyWith(top: 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _filteredContent[index];
                  final originalIndex = _content.indexOf(item);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _filteredContent.length - 1 ? 0 : AppSpacing.medium,
                    ),
                    child: AdminContentCard(
                      item: item,
                      isSelected: _selectedIndices.contains(originalIndex),
                      onSelectionChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedIndices.add(originalIndex);
                          } else {
                            _selectedIndices.remove(originalIndex);
                          }
                        });
                      },
                      onApprove: () => _handleApprove(originalIndex),
                      onReject: () => _handleReject(originalIndex),
                    ),
                  );
                },
                childCount: _filteredContent.length,
              ),
            ),
          ),
      ],
    );
  }
}

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
      title: Text(
        'Reject Post',
        style: AppTypography.heading3,
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
        AdminOutlinedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AdminErrorButton(
          label: 'Reject',
          icon: Icons.close,
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}

