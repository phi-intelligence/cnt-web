import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/community/instagram_post_card.dart';
import '../../providers/community_provider.dart';
import '../community/comment_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../community/create_post_screen.dart';

/// Web Community Screen - Full implementation
class CommunityScreenWeb extends StatefulWidget {
  final int? postId; // Optional postId to scroll to
  
  const CommunityScreenWeb({super.key, this.postId});

  @override
  State<CommunityScreenWeb> createState() => _CommunityScreenWebState();
}

class _CommunityScreenWebState extends State<CommunityScreenWeb> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _postKeys = {}; // Store keys for posts to scroll to
  bool _hasScrolledToPost = false;

  @override
  void initState() {
    super.initState();
    print('✅ CommunityScreenWeb initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<CommunityProvider>().fetchPosts(refresh: true);
      } catch (e) {
        print('❌ CommunityScreenWeb: Error fetching posts: $e');
      }
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = context.read<CommunityProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.fetchPosts();
      }
    }
  }

  void _scrollToPost(int postId) {
    if (_hasScrolledToPost) return; // Only scroll once
    
    final provider = context.read<CommunityProvider>();
    if (provider.posts.isEmpty) return;
    
    // Find the post index
    final index = provider.posts.indexWhere((post) {
      final postIdValue = post is Map<String, dynamic> 
          ? post['id'] 
          : post.id;
      final id = postIdValue is int 
          ? postIdValue 
          : int.tryParse(postIdValue.toString());
      return id == postId;
    });
    
    if (index < 0) {
      print('⚠️ Post $postId not found in list');
      // Show user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post not found. It may have been removed.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Wait for ListView to be built, then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Use GlobalKey to get exact position if available
      final key = _postKeys[postId];
      if (key?.currentContext != null) {
        final RenderBox? renderBox = key!.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final scrollPosition = _scrollController.offset + position.dy - 100; // Offset for padding
          _scrollController.animateTo(
            scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          _hasScrolledToPost = true;
          return;
        }
      }
      
      // Fallback: estimate position based on index
      // For grid layout: calculate row and scroll position
      // 3 columns on desktop, 2 on tablet, 1 on mobile
      final screenWidth = MediaQuery.of(context).size.width;
      final columnsPerRow = screenWidth >= 1024 ? 3 : (screenWidth >= 640 ? 2 : 1);
      final rowIndex = (index / columnsPerRow).floor();
      // Approximate item height with spacing in grid is ~300-350px
      const estimatedItemHeight = 320.0;
      final scrollPosition = (rowIndex * estimatedItemHeight).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _hasScrolledToPost = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
        fullscreenDialog: true,
      ),
    ).then((created) {
      if (created == true) {
      context.read<CommunityProvider>().fetchPosts(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildCreatePill(),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                
                // Posts List
                Expanded(
                  child: Consumer<CommunityProvider>(
                          builder: (context, provider, child) {
                        if (provider.isLoading && provider.posts.isEmpty) {
                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 3,
                              tablet: 2,
                              mobile: 1,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: AppSpacing.medium,
                              mainAxisSpacing: AppSpacing.medium,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              return const LoadingShimmer(width: double.infinity, height: 320);
                            },
                          );
                        }

                        if (provider.posts.isEmpty && !provider.isLoading) {
                          return const EmptyState(
                            icon: Icons.forum,
                            title: 'No Posts Yet',
                            message: 'Be the first to share something with the community!',
                          );
                        }

                        // Scroll to post if postId is provided and posts are loaded
                        if (widget.postId != null && !provider.isLoading && provider.posts.isNotEmpty && !_hasScrolledToPost) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _scrollToPost(widget.postId!);
                            }
                          });
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await provider.fetchPosts(refresh: true);
                            _hasScrolledToPost = false; // Reset to allow scrolling again after refresh
                          },
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 3,
                              tablet: 2,
                              mobile: 1,
                              childAspectRatio: 0.95, // Increased from 0.85 - less tall cards
                              crossAxisSpacing: AppSpacing.large,
                              mainAxisSpacing: AppSpacing.large,
                            ),
                            itemCount: provider.posts.length + (provider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.posts.length) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final post = provider.posts[index];
                              final postMap = post is Map<String, dynamic>
                                  ? post
                                  : {
                                      'id': post.id,
                                      'user_id': post.user_id,
                                      'user_name': post.user_name ?? 'User',
                                      'user_avatar': post.user_avatar,
                                      'title': post.title,
                                      'content': post.content,
                                      'image_url': post.image_url,
                                      'post_type': post.post_type ?? 'image', // Include post_type
                                      'category': post.category,
                                      'likes_count': post.likes_count,
                                      'comments_count': post.comments_count,
                                      'is_liked': post.is_liked,
                                      'created_at': post.created_at.toString(),
                                    };
                              
                              // Get post ID for key
                              final postIdValue = postMap['id'];
                              final postIdInt = postIdValue is int 
                                  ? postIdValue 
                                  : int.tryParse(postIdValue.toString());
                              
                              // Create key for target post
                              if (postIdInt != null && widget.postId == postIdInt && !_postKeys.containsKey(postIdInt)) {
                                _postKeys[postIdInt] = GlobalKey();
                              }

                              final postCard = InstagramPostCard(
                                post: postMap,
                                  onLike: () {
                                    final postId = postMap['id'];
                                    if (postId != null) {
                                      final id = postId is int 
                                          ? postId 
                                          : int.tryParse(postId.toString());
                                      if (id != null) {
                                        provider.likePost(id);
                                      }
                                    }
                                  },
                                  onComment: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommentScreen(post: postMap),
                                      ),
                                    );
                                  },
                                  onShare: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Share coming soon')),
                                    );
                                  },
                                  onBookmark: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bookmark coming soon')),
                                    );
                                  },
                                );

                              return postIdInt != null && widget.postId == postIdInt && _postKeys.containsKey(postIdInt)
                                    ? Container(
                                        key: _postKeys[postIdInt],
                                        child: postCard,
                                      )
                                  : postCard;
                            },
                          ),
                        );
                      },
                    ),
                ),
              ],
        ),
      ),
    );
  }

  Widget _buildCreatePill() {
    return GestureDetector(
      onTap: _handleCreatePost,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: AppColors.warmBrown.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.textInverse, size: 20),
            const SizedBox(width: 6),
            Text(
              'New Post',
              style: AppTypography.body.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
