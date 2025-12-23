import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/artist.dart';
import '../../models/content_item.dart';
import '../../providers/artist_provider.dart';
import '../../widgets/shared/content_section.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../config/app_config.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtistProfileScreen extends StatefulWidget {
  final int artistId;

  const ArtistProfileScreen({super.key, required this.artistId});

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use addPostFrameCallback to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadArtistData();
      }
    });
  }

  Future<void> _loadArtistData() async {
    if (!mounted) return;
    
    final provider = context.read<ArtistProvider>();
    await provider.fetchArtist(widget.artistId);
    
    if (!mounted) return;
    await provider.fetchArtistPodcasts(widget.artistId);
    
    if (!mounted) return;
    final artist = provider.getArtist(widget.artistId);
    if (artist != null) {
      setState(() {
        _isFollowing = artist.isFollowing ?? false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final provider = context.read<ArtistProvider>();
    final success = _isFollowing
        ? await provider.unfollowArtist(widget.artistId)
        : await provider.followArtist(widget.artistId);

    if (success) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
          
          return Consumer<ArtistProvider>(
            builder: (context, provider, _) {
          final artist = provider.getArtist(widget.artistId);
          final isLoading = provider.isArtistLoading(widget.artistId);
          final error = provider.getArtistError(widget.artistId);

          if (isLoading && artist == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (error != null && artist == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadArtistData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (artist == null) {
            return const Center(child: Text('Artist not found'));
          }

          final podcasts = provider.getArtistPodcasts(widget.artistId) ?? [];
          final videoPodcasts = podcasts.where((p) => p.videoUrl != null).toList();
          final audioPodcasts = podcasts.where((p) => p.videoUrl == null && p.audioUrl != null).toList();

          return CustomScrollView(
            slivers: [
              // Header with cover image and artist info
              SliverAppBar(
                expandedHeight: isSmallMobile ? 220 : 300,
                pinned: true,
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image
                      if (artist.coverImage != null)
                        Image.network(
                          artist.coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.warmBrown.withOpacity(0.3),
                            child: Icon(Icons.person, size: isSmallMobile ? 60 : 100, color: AppColors.warmBrown),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.warmBrown.withOpacity(0.3),
                          child: Icon(Icons.person, size: isSmallMobile ? 60 : 100, color: AppColors.warmBrown),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      // Artist info at bottom
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.displayName,
                              style: AppTypography.heading1.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${artist.followersCount} followers',
                                  style: AppTypography.body.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(width: 16),
                                if (artist.isVerified)
                                  Icon(Icons.verified, color: AppColors.accentMain, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats, bio, social links, follow button
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Podcasts', podcasts.length.toString()),
                          _buildStat('Total Plays', artist.totalPlays.toString()),
                          _buildStat('Followers', artist.followersCount.toString()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.large),
                      
                      // Follow button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _toggleFollow,
                          icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
                          label: Text(_isFollowing ? 'Following' : 'Follow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? AppColors.warmBrown : AppColors.accentMain,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                        ),
                      ),
                      
                      // Bio
                      if (artist.bio != null) ...[
                        SizedBox(height: AppSpacing.large),
                        Text('About', style: AppTypography.heading2),
                        SizedBox(height: AppSpacing.small),
                        Text(artist.bio!, style: AppTypography.body),
                      ],
                      
                      // Social links
                      if (artist.socialLinks != null && artist.socialLinks!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.large),
                        Text('Connect', style: AppTypography.heading2),
                        SizedBox(height: AppSpacing.small),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (artist.instagram != null)
                              IconButton(
                                icon: Icon(Icons.photo_camera),
                                color: AppColors.accentMain,
                                onPressed: () => _launchUrl(artist.instagram!),
                              ),
                            if (artist.twitter != null)
                              IconButton(
                                icon: Icon(Icons.chat),
                                color: AppColors.accentMain,
                                onPressed: () => _launchUrl(artist.twitter!),
                              ),
                            if (artist.youtube != null)
                              IconButton(
                                icon: Icon(Icons.play_circle_outline),
                                color: AppColors.accentMain,
                                onPressed: () => _launchUrl(artist.youtube!),
                              ),
                            if (artist.website != null)
                              IconButton(
                                icon: Icon(Icons.language),
                                color: AppColors.accentMain,
                                onPressed: () => _launchUrl(artist.website!),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Tabs for content
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accentMain,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.accentMain,
                    tabs: const [
                      Tab(text: 'Video Podcasts'),
                      Tab(text: 'Audio Podcasts'),
                    ],
                  ),
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Video podcasts
                    _buildPodcastGrid(videoPodcasts, isVideo: true),
                    // Audio podcasts
                    _buildPodcastGrid(audioPodcasts, isVideo: false),
                  ],
                ),
              ),
            ],
          );
        },
      );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value, 
          style: ResponsiveUtils.isSmallMobile(context) 
            ? AppTypography.heading3.copyWith(color: AppColors.accentMain)
            : AppTypography.heading1.copyWith(color: AppColors.accentMain),
        ),
        SizedBox(height: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildPodcastGrid(List<ContentItem> podcasts, {required bool isVideo}) {
    if (podcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVideo ? Icons.videocam_off : Icons.music_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isVideo ? 'video' : 'audio'} podcasts yet',
              style: AppTypography.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ContentSection(
      title: '',
      items: podcasts,
      isHorizontal: false,
      useDiscDesign: !isVideo,
      onItemTap: (item) {
        if (item.videoUrl != null) {
          context.push('/player/video/${item.id}');
        } else if (item.audioUrl != null) {
          context.push('/player/audio/${item.id}');
        }
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

