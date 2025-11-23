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
import '../../models/content_item.dart';
import '../../models/api_models.dart';
import '../../utils/format_utils.dart';
import '../../widgets/video_player.dart';
import '../video/video_player_full_screen.dart';
import '../../widgets/hero_carousel_widget.dart';
import '../../utils/platform_helper.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../audio/audio_player_full_screen_new.dart';
import '../movie_detail_screen.dart';
import 'movie_detail_screen_web.dart';
import 'video_podcast_detail_screen_web.dart';
import 'audio_player_full_screen_web.dart';
import '../../widgets/voice/voice_bubble.dart';
import 'voice_agent_screen_web.dart';
import '../../widgets/bible/bible_reader_section.dart';
import '../../models/document_asset.dart';
import 'community_screen_web.dart';
import '../../widgets/web/welcome_section_web.dart';
import 'podcasts_screen_web.dart';

/// Web Home Screen - Real data integration matching mobile
class HomeScreenWeb extends StatefulWidget {
  const HomeScreenWeb({super.key});

  @override
  State<HomeScreenWeb> createState() => _HomeScreenWebState();
}

class _HomeScreenWebState extends State<HomeScreenWeb> {
  final ApiService _api = ApiService();
  final GlobalKey _audioPodcastsKey = GlobalKey();
  
  List<ContentItem> _audioPodcasts = [];
  List<ContentItem> _videoPodcasts = [];
  List<ContentItem> _recentPodcasts = [];
  List<BibleStory> _bibleStories = [];
  List<DocumentAsset> _bibleDocuments = [];
  List<ContentItem> _movies = [];
  bool _isLoadingPodcasts = false;
  bool _isLoadingBibleStories = false;
  bool _isLoadingBibleDocuments = false;
  bool _isLoadingMovies = false;

  @override
  void initState() {
    super.initState();
    print('✅ HomeScreenWeb initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        print('✅ HomeScreenWeb: Fetching data...');
        _fetchPodcasts();
        _fetchBibleStories();
        _fetchBibleDocuments();
        _fetchMovies();
        context.read<MusicProvider>().fetchTracks();
        context.read<UserProvider>().fetchUser();
        context.read<PlaylistProvider>().fetchPlaylists();
        print('✅ HomeScreenWeb: Data fetch initiated');
      } catch (e) {
        print('❌ HomeScreenWeb: Error initializing providers: $e');
      }
    });
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
        final audioUrl = podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty
            ? _api.getMediaUrl(podcast.audioUrl!)
            : null;
        final videoUrl = podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty
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
      _audioPodcasts = allContentItems.where((p) => 
        p.audioUrl != null && 
        p.audioUrl!.isNotEmpty && 
        (p.videoUrl == null || p.videoUrl!.isEmpty)
      ).toList();
      
      _videoPodcasts = allContentItems.where((p) => 
        p.videoUrl != null && 
        p.videoUrl!.isNotEmpty
      ).toList();
      
      // Get recent podcasts (audio podcasts sorted by created_at)
      _recentPodcasts = List.from(_audioPodcasts);
      _recentPodcasts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _recentPodcasts = _recentPodcasts.take(5).toList();
      
      print('✅ Loaded ${_audioPodcasts.length} audio podcasts and ${_videoPodcasts.length} video podcasts');
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

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1: return 'Sermons';
      case 2: return 'Bible Study';
      case 3: return 'Devotionals';
      case 4: return 'Prayer';
      case 5: return 'Worship';
      case 6: return 'Gospel';
      default: return 'Podcast';
    }
  }

  String _getGreeting(Map<String, dynamic>? user) {
    final username = user?['name'] ?? 'Guest';
    return 'Hey $username';
  }

  void _handlePlay(ContentItem item) {
    if (item.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio available for ${item.title}')),
      );
      return;
    }

    context.read<AudioPlayerState>().playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
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
          gradientColors: const [AppColors.backgroundPrimary, AppColors.backgroundSecondary],
          videoUrl: item.videoUrl!,
          playlist: playlist,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          onBack: () => Navigator.of(context).pop(),
          onDonate: () {},
          onFavorite: () {},
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
        context.read<AudioPlayerState>().playContent(firstPodcast);
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
      audioUrl: story.audioUrl != null ? _api.getMediaUrl(story.audioUrl!) : null,
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
              color: AppColors.backgroundSecondary,
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
    final hasContent =
        _bibleStories.isNotEmpty || _bibleDocuments.isNotEmpty;

    if (isLoading) {
      return _buildBibleSectionWrapper(
        const LoadingShimmer(width: double.infinity, height: 300),
      );
    }

    if (hasContent) {
      return BibleReaderSection(
        stories: _bibleStories,
        documents: _bibleDocuments,
        isWeb: true,
        onOpenStory: _openBibleStory,
      );
    }

    return _buildBibleSectionWrapper(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: AppColors.borderPrimary.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Bible documents yet',
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Admins can upload Bible PDFs and study notes from the dashboard. '
              'Once documents are available, they will appear here.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton.icon(
              onPressed: () {
                _fetchBibleStories();
                _fetchBibleDocuments();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibleSectionWrapper(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bible Reader',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  _fetchPodcasts(),
                  _fetchBibleStories(),
                  _fetchBibleDocuments(),
                  _fetchMovies(),
                  musicProvider.fetchTracks(),
                  context.read<PlaylistProvider>().fetchPlaylists(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Hero Section (Carousel)
                      _buildHeroSection(),
                      
                    const SizedBox(height: AppSpacing.extraLarge),
                    
                    // Welcome Section
                    WelcomeSectionWeb(
                      onStartListening: () {
                        // Scroll to audio podcasts section
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final context = _audioPodcastsKey.currentContext;
                          if (context != null) {
                            Scrollable.ensureVisible(
                              context,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      },
                      onJoinPrayer: () {
                        // Navigate to prayer screen
                        Navigator.pushNamed(context, '/prayer');
                      },
                    ),
                    
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Audio Podcasts
                      Builder(
                        key: _audioPodcastsKey,
                        builder: (context) {
                      if (_isLoadingPodcasts)
                            return _buildLoadingSection('Audio Podcasts', height: 240);
                      else if (_audioPodcasts.isEmpty)
                            return const SizedBox.shrink();
                      else
                            return ContentSection(
                          title: 'Audio Podcasts',
                          items: _audioPodcasts.take(8).toList(),
                          isHorizontal: false,
                          useDiscDesign: true,
                          onItemPlay: _handlePlay,
                          onItemTap: _handleItemTap,
                            );
                        },
                        ),
                      
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Video Podcasts (moved right after Audio Podcasts to match mobile)
                      if (_isLoadingPodcasts)
                        _buildLoadingSection('Video Podcasts', height: 300)
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
                      
                      // Recently Played
                      if (_isLoadingPodcasts)
                        _buildLoadingSection('Recently Played', height: 200)
                      else if (_recentPodcasts.isEmpty)
                        const EmptyState(
                          icon: Icons.history,
                          title: 'No Recent Playbacks',
                          message: 'Start exploring content to see your recently played items here',
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
                      
                      // Movies Section
                      if (_isLoadingMovies)
                        _buildLoadingSection('Movies', height: 300)
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
                      
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Music Section
                      Consumer<MusicProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return _buildLoadingSection('Music', height: 200);
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
                            return _buildLoadingSection('Your Playlists', height: 200);
                          }
                          
                          if (provider.playlists.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          // Convert playlists to ContentItems for display
                          final playlistItems = provider.playlists.take(4).map((playlist) {
                            return ContentItem(
                              id: playlist['id'].toString(),
                              title: playlist['name'] ?? 'Untitled Playlist',
                              creator: 'You',
                              description: playlist['description'],
                              coverImage: playlist['cover_image'],
                              category: 'Playlist',
                              createdAt: DateTime.parse(playlist['created_at'] ?? DateTime.now().toIso8601String()),
                            );
                          }).toList();
                          
                          return ContentSection(
                            title: 'Your Playlists',
                            items: playlistItems,
                            isHorizontal: false,
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
                          isHorizontal: false,
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


  Widget _buildHeroSection() {
    // Hero Carousel Widget for Web (web-optimized size)
    // Wrapped in Container to match other sections' styling
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary, // Cream/beige background
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: HeroCarouselWidget(
          onItemTap: (postId) {
            // Navigate to community page with postId (web navigation)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CommunityScreenWeb(postId: postId),
              ),
            );
          },
          height: MediaQuery.of(context).size.height * 0.3, // 30% of screen height for web
        ),
      ),
    );
  }
}
