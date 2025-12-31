import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/content_section.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../services/api_service.dart';
import '../../providers/music_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/content_item.dart';
import '../../models/api_models.dart';
import '../video/video_player_full_screen.dart';
import '../../widgets/hero_carousel_widget.dart';
import '../../utils/platform_helper.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/bible/bible_reader_section.dart';
import '../../widgets/meeting/meeting_section.dart';
import '../../widgets/live_stream/live_stream_section.dart';
import '../../models/document_asset.dart';
import 'community_screen_web.dart';
import '../../widgets/web/welcome_section_web.dart';
import 'movie_detail_screen_web.dart';
import 'video_podcast_detail_screen_web.dart';
import 'audio_player_full_screen_web.dart';
import '../audio/audio_player_full_screen_new.dart';

/// Web Home Screen - Real data integration matching mobile
class HomeScreenWeb extends StatefulWidget {
  const HomeScreenWeb({super.key});

  @override
  State<HomeScreenWeb> createState() => _HomeScreenWebState();
}

class _HomeScreenWebState extends State<HomeScreenWeb> {
  final ApiService _api = ApiService();
  final GlobalKey _audioPodcastsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<HeroCarouselWidgetState> _heroCarouselKey =
      GlobalKey<HeroCarouselWidgetState>();

  List<ContentItem> _audioPodcasts = [];
  List<ContentItem> _videoPodcasts = [];
  List<ContentItem> _recentPodcasts = [];
  List<BibleStory> _bibleStories = [];
  List<DocumentAsset> _bibleDocuments = [];
  List<ContentItem> _movies = [];
  List<ContentItem> _animatedBibleStories = [];
  bool _isLoadingPodcasts = false;
  bool _isLoadingBibleStories = false;
  bool _isLoadingBibleDocuments = false;
  bool _isLoadingMovies = false;
  bool _isLoadingAnimatedBibleStories = false;

  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    print('✅ HomeScreenWeb initState');

    // Listen to scroll changes for fade and parallax effects
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        print('✅ HomeScreenWeb: Fetching data...');
        _fetchPodcasts();
        _fetchBibleStories();
        _fetchBibleDocuments();
        _fetchMovies();
        _fetchAnimatedBibleStories();
        context.read<MusicProvider>().fetchTracks();
        context.read<UserProvider>().fetchUser();
        context.read<PlaylistProvider>().fetchPlaylists();
        context.read<FavoritesProvider>().fetchFavorites();
        print('✅ HomeScreenWeb: Data fetch initiated');
      } catch (e) {
        print('❌ HomeScreenWeb: Error initializing providers: $e');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Calculate carousel opacity based on scroll position
  double _calculateCarouselOpacity() {
    const fadeStart = 200.0;
    const fadeEnd = 600.0;

    if (_scrollOffset < fadeStart) return 1.0;
    if (_scrollOffset > fadeEnd) return 0.0;

    final fadeProgress = (_scrollOffset - fadeStart) / (fadeEnd - fadeStart);
    return (1.0 - fadeProgress).clamp(0.0, 1.0);
  }

  // Calculate parallax offset for carousel
  double _calculateParallaxOffset() {
    return _scrollOffset * 0.5;
  }

  Future<void> _fetchPodcasts() async {
    if (_isLoadingPodcasts) return;

    setState(() {
      _isLoadingPodcasts = true;
    });

    try {
      final podcastsData = await _api.getPodcasts(
        status: 'approved',
        newestFirst: true,
      );
      podcastsData.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Convert Podcast models to ContentItem models
      final allContentItems = podcastsData.map((podcast) {
        final audioUrl =
            podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty
                ? _api.getMediaUrl(podcast.audioUrl!)
                : null;
        final videoUrl =
            podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty
                ? _api.getMediaUrl(podcast.videoUrl!)
                : null;

        return ContentItem(
          id: podcast.id.toString(),
          title: podcast.title,
          creator: 'Christ Tabernacle',
          description: podcast.description,
          coverImage: podcast.coverImage != null
              ? _api.getMediaUrl(podcast.coverImage!)
              : null,
          audioUrl: audioUrl,
          videoUrl: videoUrl,
          duration: podcast.duration != null
              ? Duration(seconds: podcast.duration!)
              : null,
          category: _getCategoryName(podcast.categoryId),
          plays: podcast.playsCount,
          createdAt: podcast.createdAt,
        );
      }).toList();

      // Separate audio and video podcasts
      _audioPodcasts = allContentItems
          .where((p) =>
              p.audioUrl != null &&
              p.audioUrl!.isNotEmpty &&
              (p.videoUrl == null || p.videoUrl!.isEmpty))
          .toList();

      _videoPodcasts = allContentItems
          .where((p) => p.videoUrl != null && p.videoUrl!.isNotEmpty)
          .toList();

      // Get recent podcasts (audio podcasts sorted by created_at)
      _recentPodcasts = List.from(_audioPodcasts);
      _recentPodcasts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _recentPodcasts = _recentPodcasts.take(5).toList();

      print(
          '✅ Loaded ${_audioPodcasts.length} audio podcasts and ${_videoPodcasts.length} video podcasts');
    } catch (e) {
      print('❌ Error fetching podcasts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPodcasts = false;
        });
      }
    }
  }

  Future<void> _fetchBibleStories() async {
    if (_isLoadingBibleStories) return;

    setState(() {
      _isLoadingBibleStories = true;
    });

    try {
      final stories = await _api.getBibleStories(limit: 12);
      if (mounted) {
        setState(() {
          _bibleStories = stories;
        });
      }
    } catch (e) {
      print('❌ Error fetching bible stories: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBibleStories = false;
        });
      }
    }
  }

  Future<void> _fetchBibleDocuments() async {
    if (_isLoadingBibleDocuments) return;

    setState(() {
      _isLoadingBibleDocuments = true;
    });

    try {
      final docs = await _api.getDocuments(category: 'Bible');
      if (mounted) {
        setState(() {
          _bibleDocuments = docs;
        });
      }
    } catch (e) {
      print('❌ Error fetching bible documents: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBibleDocuments = false;
        });
      }
    }
  }

  Future<void> _fetchMovies() async {
    if (_isLoadingMovies) return;

    setState(() {
      _isLoadingMovies = true;
    });

    try {
      final moviesData = await _api.getMovies(limit: 20);

      // Convert Movie models to ContentItem models
      _movies = moviesData.map((movie) {
        return _api.movieToContentItem(movie);
      }).toList();

      print('✅ Loaded ${_movies.length} movies');
    } catch (e) {
      print('❌ Error fetching movies: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMovies = false;
        });
      }
    }
  }

  Future<void> _fetchAnimatedBibleStories() async {
    if (_isLoadingAnimatedBibleStories) return;

    setState(() {
      _isLoadingAnimatedBibleStories = true;
    });

    try {
      final storiesData = await _api.getAnimatedBibleStories(limit: 20);

      // Convert Movie models to ContentItem models
      _animatedBibleStories = storiesData.map((movie) {
        return _api.movieToContentItem(movie);
      }).toList();

      print('✅ Loaded ${_animatedBibleStories.length} Kids Bible Stories');
    } catch (e) {
      print('❌ Error fetching Kids Bible Stories: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnimatedBibleStories = false;
        });
      }
    }
  }

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1:
        return 'Sermons';
      case 2:
        return 'Bible Study';
      case 3:
        return 'Devotionals';
      case 4:
        return 'Prayer';
      case 5:
        return 'Worship';
      case 6:
        return 'Gospel';
      default:
        return 'Podcast';
    }
  }

  String _getGreeting(Map<String, dynamic>? user) {
    final username = user?['name'] ?? 'Guest';
    return 'Hey $username';
  }

  void _handlePlay(ContentItem item, {List<ContentItem>? playlist}) {
    if (item.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio available for ${item.title}')),
      );
      return;
    }

    // Use playQueue if we have a playlist for auto-play next functionality
    final audioPlayer = context.read<AudioPlayerState>();

    if (playlist != null && playlist.isNotEmpty) {
      // Filter to only audio tracks and find the index
      final audioTracks = playlist
          .where((p) => p.audioUrl != null && p.audioUrl!.isNotEmpty)
          .toList();
      final startIndex = audioTracks.indexWhere((p) => p.id == item.id);

      if (audioTracks.isNotEmpty) {
        audioPlayer.playQueue(audioTracks,
            startIndex: startIndex >= 0 ? startIndex : 0);
        return;
      }
    }

    // Fallback: If no playlist provided, use all audio podcasts as queue
    if (_audioPodcasts.isNotEmpty) {
      final startIndex = _audioPodcasts.indexWhere((p) => p.id == item.id);
      if (startIndex >= 0) {
        audioPlayer.playQueue(_audioPodcasts, startIndex: startIndex);
        return;
      }
    }

    // Final fallback: just play the single item
    audioPlayer.playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item, playlist: _audioPodcasts);
  }

  void _handlePlayVideo(ContentItem item) {
    if (item.videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No video available for ${item.title}')),
      );
      return;
    }

    // Navigate to full-screen video podcast player
    final playlist = _videoPodcasts
        .where((p) => p.videoUrl != null && p.videoUrl!.isNotEmpty)
        .toList();
    final initialIndex = playlist.indexWhere((p) => p.id == item.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(
          videoId: item.id,
          title: item.title,
          author: item.creator,
          duration: item.duration?.inSeconds ?? 0,
          gradientColors: const [Colors.white, Colors.white],
          videoUrl: item.videoUrl!,
          playlist: playlist,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          onBack: () => Navigator.of(context).pop(),
          onDonate: () {},
          onSeek: null,
        ),
      ),
    );
  }

  void _handleItemTapVideo(ContentItem item) {
    // Navigate to video podcast detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPodcastDetailScreenWeb(
          item: item,
        ),
      ),
    );
  }

  void _handleMovieTap(ContentItem item) {
    // Navigate to movie detail screen (web version)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreenWeb(
          item: item,
          movieId: int.tryParse(item.id),
        ),
      ),
    );
  }

  void _handleDiscIconPress() {
    if (_audioPodcasts.isNotEmpty) {
      final firstPodcast = _audioPodcasts.first;
      if (firstPodcast.audioUrl != null) {
        // Play all audio podcasts as a queue for auto-play next
        context
            .read<AudioPlayerState>()
            .playQueue(_audioPodcasts, startIndex: 0);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlatformHelper.isWebPlatform()
                ? const AudioPlayerFullScreenWeb()
                : const AudioPlayerFullScreenNew(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio available')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No podcasts available')),
      );
    }
  }

  ContentItem _mapBibleStoryToContentItem(BibleStory story) {
    return ContentItem(
      id: story.id.toString(),
      title: story.title,
      creator: 'Scripture',
      description: story.content,
      coverImage: null,
      audioUrl:
          story.audioUrl != null ? _api.getMediaUrl(story.audioUrl!) : null,
      duration: null,
      category: story.scriptureReference,
      plays: 0,
      createdAt: story.createdAt,
    );
  }

  void _openBibleStory(BibleStory story) {
    showDialog(
      context: context,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.75;
        return Dialog(
          insetPadding: const EdgeInsets.all(AppSpacing.large),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: SizedBox(
              height: maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          story.title,
                          style: AppTypography.heading2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    story.scriptureReference,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        story.content,
                        style: AppTypography.bodyMedium.copyWith(height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBibleReaderSection() {
    final isLoading = _isLoadingBibleStories || _isLoadingBibleDocuments;
    final hasContent = _bibleStories.isNotEmpty || _bibleDocuments.isNotEmpty;

    if (isLoading) {
      final isMobile = ResponsiveUtils.isMobile(context);
      final isTablet = ResponsiveUtils.isTablet(context);

      // Loading state with new square box design
      if (isMobile) {
        return Column(
          children: [
            _buildLoadingBibleBox(),
            const SizedBox(height: AppSpacing.medium),
            _buildLoadingBibleBox(),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildLoadingBibleBox()),
          SizedBox(width: isTablet ? AppSpacing.medium : AppSpacing.large),
          Expanded(child: _buildLoadingBibleBox()),
        ],
      );
    }

    // Both loaded and empty states use the BibleReaderSection component
    // which now has the new square box design with Daily Bible Quote feature
    return BibleReaderSection(
      stories: _bibleStories,
      documents: _bibleDocuments,
      isWeb: true,
      onOpenStory: _openBibleStory,
    );
  }

  Widget _buildLoadingBibleBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 24,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.large),
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;

    // Use responsive utilities for better breakpoint handling
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    // Responsive carousel height
    final carouselHeight = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: ResponsiveUtils.isSmallMobile(context)
          ? 200.0
          : 250.0, // Reduced height for small mobile
      tablet: screenHeight * 0.35,
      desktop: screenHeight * 0.5,
    );

    final whiteCardTopMargin = carouselHeight * 0.7;

    // Responsive padding
    final horizontalPadding = ResponsiveUtils.getPageHorizontalPadding(context);
    final verticalPadding = ResponsiveUtils.getPageVerticalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Layer: Carousel with fade and parallax
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: Transform.translate(
              offset: Offset(0, _calculateParallaxOffset()),
              child: AnimatedOpacity(
                opacity: _calculateCarouselOpacity(),
                duration: const Duration(milliseconds: 100),
                child: IgnorePointer(
                  ignoring: _calculateCarouselOpacity() <
                      0.1, // Disable clicks when nearly invisible
                  child: _buildHeroSection(),
                ),
              ),
            ),
          ),

          // Foreground Layer: Scrollable content in white card
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _scrollOffset = notification.metrics.pixels;
                });
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh hero carousel if key is available
                _heroCarouselKey.currentState?.refresh();

                await Future.wait([
                  _fetchPodcasts(),
                  _fetchBibleStories(),
                  _fetchBibleDocuments(),
                  _fetchMovies(),
                  _fetchAnimatedBibleStories(),
                  musicProvider.fetchTracks(),
                  context.read<PlaylistProvider>().fetchPlaylists(),
                ]);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Spacer to push white card down (overlapping carousel)
                    // Wrap in IgnorePointer to prevent ScrollView from capturing events here
                    IgnorePointer(
                      ignoring: true, // Ignore all pointer events in this area
                      child: SizedBox(height: whiteCardTopMargin),
                    ),

                    // White Floating Card containing all content
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: screenHeight - whiteCardTopMargin,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, -5),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Section
                            const WelcomeSectionWeb(),

                            SizedBox(
                                height: ResponsiveUtils.getResponsivePadding(
                                    context, AppSpacing.extraLarge)),

                            // Audio Podcasts + Movies Section with Background Image
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/jesus2.png'),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  opacity: 0.65,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withOpacity(0.88),
                                      Colors.white.withOpacity(0.75),
                                      Colors.white.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveUtils.getResponsiveValue(
                                    context: context,
                                    mobile: AppSpacing.medium,
                                    tablet: AppSpacing.large,
                                    desktop: AppSpacing.extraLarge,
                                  ),
                                  vertical: AppSpacing.large,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Audio Podcasts
                                    Builder(
                                      key: _audioPodcastsKey,
                                      builder: (context) {
                                        if (_isLoadingPodcasts)
                                          return _buildLoadingSection(
                                              'Audio Podcasts',
                                              height: 240);
                                        else if (_audioPodcasts.isEmpty)
                                          return const SizedBox.shrink();
                                        else
                                          return ContentSection(
                                            title: 'Audio Podcasts',
                                            items:
                                                _audioPodcasts.take(8).toList(),
                                            isHorizontal: true,
                                            useDiscDesign: true,
                                            onItemPlay: _handlePlay,
                                            onItemTap: _handleItemTap,
                                          );
                                      },
                                    ),

                                    const SizedBox(
                                        height: AppSpacing.extraLarge),

                                    // Movies Section
                                    if (_isLoadingMovies)
                                      _buildLoadingSection('Movies',
                                          height: 300)
                                    else if (_movies.isEmpty)
                                      const SizedBox.shrink()
                                    else
                                      ContentSection(
                                        title: 'Movies',
                                        items: _movies,
                                        isHorizontal: true,
                                        onItemPlay: _handleMovieTap,
                                        onItemTap: _handleMovieTap,
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Video Podcasts
                            if (_isLoadingPodcasts)
                              _buildLoadingSection('Video Podcasts',
                                  height: 300)
                            else if (_videoPodcasts.isEmpty)
                              const SizedBox.shrink()
                            else
                              ContentSection(
                                title: 'Video Podcasts',
                                items: _videoPodcasts,
                                isHorizontal: true,
                                onItemPlay: _handlePlayVideo,
                                onItemTap: _handleItemTapVideo,
                              ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Bible Reader Section
                            _buildBibleReaderSection(),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Animated Bible Stories Section
                            _buildAnimatedBibleStoriesSection(),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Meetings Section
                            const MeetingSection(),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Recently Played (after Meetings per requirements)
                            if (_isLoadingPodcasts)
                              _buildLoadingSection('Recently Played',
                                  height: 200)
                            else if (_recentPodcasts.isEmpty)
                              const EmptyState(
                                icon: Icons.history,
                                title: 'No Recent Playbacks',
                                message:
                                    'Start exploring content to see your recently played items here',
                              )
                            else
                              ContentSection(
                                title: 'Recently Played',
                                items: _recentPodcasts,
                                isHorizontal: true,
                                onItemPlay: _handlePlay,
                                onItemTap: _handleItemTap,
                              ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Live Stream Section
                            const LiveStreamSection(),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Music Section
                            Consumer<MusicProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading) {
                                  return _buildLoadingSection('Music',
                                      height: 200);
                                }

                                if (provider.featuredTracks.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return ContentSection(
                                  title: 'Featured Music',
                                  items: provider.featuredTracks,
                                  isHorizontal: true,
                                  onItemPlay: _handlePlay,
                                  onItemTap: _handleItemTap,
                                );
                              },
                            ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Playlists
                            Consumer<PlaylistProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading) {
                                  return _buildLoadingSection('Your Playlists',
                                      height: 200);
                                }

                                if (provider.playlists.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                // Convert playlists to ContentItems for display
                                final playlistItems =
                                    provider.playlists.take(4).map((playlist) {
                                  return ContentItem(
                                    id: playlist.id.toString(),
                                    title: playlist.name,
                                    creator: 'You',
                                    description: playlist.description,
                                    coverImage: playlist.thumbnailUrl,
                                    category: 'Playlist',
                                    createdAt: DateTime
                                        .now(), // Playlist model doesn't include createdAt
                                  );
                                }).toList();

                                return ContentSection(
                                  title: 'Your Playlists',
                                  items: playlistItems,
                                  isHorizontal: true,
                                  onItemTap: (item) {
                                    // TODO: Navigate to playlist detail
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: AppSpacing.extraLarge),

                            // Bible Stories
                            if (_isLoadingBibleStories)
                              _buildLoadingSection('Bible Stories', height: 300)
                            else if (_bibleStories.isEmpty)
                              const SizedBox.shrink()
                            else
                              ContentSection(
                                title: 'Bible Stories',
                                items: _bibleStories
                                    .map(_mapBibleStoryToContentItem)
                                    .toList(),
                                isHorizontal: true,
                                onItemTap: (item) {
                                  final story = _bibleStories.firstWhere(
                                    (s) => s.id.toString() == item.id,
                                    orElse: () => _bibleStories.first,
                                  );
                                  _openBibleStory(story);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String title, {required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: AppSpacing.medium),
                child: const LoadingShimmer(width: 180, height: 220),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBibleStoriesSection() {
    if (_isLoadingAnimatedBibleStories) {
      return _buildLoadingSection('Kids Bible Stories', height: 300);
    } else if (_animatedBibleStories.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return ContentSection(
        title: 'Kids Bible Stories',
        items: _animatedBibleStories,
        isHorizontal: true,
        onItemPlay: _handleMovieTap,
        onItemTap: _handleMovieTap,
      );
    }
  }

  Widget _buildHeroSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return SizedBox(
      width: double.infinity,
      height: isMobile ? screenHeight * 0.35 : screenHeight * 0.5,
      child: HeroCarouselWidget(
        key: _heroCarouselKey,
        onItemTap: (postId) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CommunityScreenWeb(postId: postId),
            ),
          );
        },
        height: isMobile ? screenHeight * 0.35 : screenHeight * 0.5,
      ),
    );
  }
}
