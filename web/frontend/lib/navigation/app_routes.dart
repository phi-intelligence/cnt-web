import 'package:go_router/go_router.dart';
import '../screens/web/home_screen_web.dart';
import '../screens/web/search_screen_web.dart';
import '../screens/web/create_screen_web.dart';
import '../screens/web/community_screen_web.dart';
import '../screens/web/profile_screen_web.dart';
import '../screens/web/podcasts_screen_web.dart';
import '../screens/web/movies_screen_web.dart';
import '../screens/admin_dashboard.dart';
import '../screens/web/about_screen_web.dart';
import '../screens/web/meeting_options_screen_web.dart';
import '../screens/web/live_stream_options_screen_web.dart';
import '../screens/web/video_editor_screen_web.dart';
import '../screens/editing/audio_editor_screen.dart';
import '../screens/web/video_preview_screen_web.dart';
import '../screens/creation/audio_preview_screen.dart';
import '../screens/web/video_podcast_detail_screen_web.dart';
import '../screens/web/movie_detail_screen_web.dart';
import '../screens/web/audio_player_full_screen_web.dart';
import '../screens/live/live_stream_start_screen.dart';
import '../screens/web/live_screen_web.dart';
import '../screens/web/landing_screen_web.dart';
import '../screens/artist/artist_profile_screen.dart';
import '../screens/artist/artist_profile_manage_screen.dart';
import '../screens/creation/quote_create_screen_web.dart';
import '../screens/admin/bulk_upload_screen.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'web_navigation.dart';
import 'package:flutter/material.dart';

/// Helper function to create a page with no transition animation
Page<void> _buildPageWithoutTransition(BuildContext context, GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

/// Route configuration for the application
/// Uses go_router for URL-based routing and state persistence
GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/' || 
                         state.matchedLocation.startsWith('/login') ||
                         state.matchedLocation.startsWith('/register');
      
      // Redirect to login if not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return '/';
      }
      
      // Redirect to home if authenticated and on landing page
      if (isAuthenticated && state.matchedLocation == '/') {
        return '/home';
      }
      
      return null; // No redirect needed
    },
    routes: [
      // Landing page (login)
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreenWeb(),
      ),
      
      // Main navigation routes (wrapped in WebNavigationLayout - NO transitions)
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: HomeScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: SearchScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/create',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: CreateScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/community',
        pageBuilder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return _buildPageWithoutTransition(
            context,
            state,
            WebNavigationLayout(
              child: CommunityScreenWeb(
                postId: postId != null ? int.tryParse(postId) : null,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: ProfileScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/podcasts',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: PodcastsScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/movies',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: MoviesScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: AboutScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: AdminDashboardScreen()),
        ),
      ),
      
      // Bulk upload route (admin only)
      GoRoute(
        path: '/bulk-upload',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: BulkUploadScreen()),
        ),
      ),
      
      // Quote creation route
      GoRoute(
        path: '/quote',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: QuoteCreateScreenWeb()),
        ),
      ),
      
      // Meeting routes
      GoRoute(
        path: '/meetings',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: MeetingOptionsScreenWeb()),
        ),
      ),
      
      // Live stream routes
      GoRoute(
        path: '/live-stream/options',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: LiveStreamOptionsScreenWeb()),
        ),
      ),
      GoRoute(
        path: '/live-stream/start',
        builder: (context, state) => const LiveStreamStartScreen(),
      ),
      GoRoute(
        path: '/live-streams',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: LiveScreenWeb()),
        ),
      ),
      
      // Editor routes
      GoRoute(
        path: '/edit/video',
        builder: (context, state) {
          final videoPath = state.uri.queryParameters['path'];
          if (videoPath == null || videoPath.isEmpty) {
            // Return error widget or redirect
            return const Scaffold(
              body: Center(child: Text('Video path is required')),
            );
          }
          return VideoEditorScreenWeb(videoPath: videoPath);
        },
      ),
      GoRoute(
        path: '/edit/audio',
        builder: (context, state) {
          final audioPath = state.uri.queryParameters['path'];
          if (audioPath == null || audioPath.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Audio path is required')),
            );
          }
          return AudioEditorScreen(audioPath: audioPath);
        },
      ),
      
      // Preview routes
      GoRoute(
        path: '/preview/video',
        builder: (context, state) {
          final videoUri = state.uri.queryParameters['uri'];
          final source = state.uri.queryParameters['source'] ?? 'camera';
          final duration = int.tryParse(state.uri.queryParameters['duration'] ?? '0') ?? 0;
          final fileSize = int.tryParse(state.uri.queryParameters['fileSize'] ?? '0') ?? 0;
          
          if (videoUri == null || videoUri.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Video URI is required')),
            );
          }
          return VideoPreviewScreenWeb(
            videoUri: videoUri,
            source: source,
            duration: duration,
            fileSize: fileSize,
          );
        },
      ),
      GoRoute(
        path: '/preview/audio',
        builder: (context, state) {
          final audioUri = state.uri.queryParameters['uri'];
          final source = state.uri.queryParameters['source'] ?? 'recording';
          final duration = int.tryParse(state.uri.queryParameters['duration'] ?? '0') ?? 0;
          final fileSize = int.tryParse(state.uri.queryParameters['fileSize'] ?? '0') ?? 0;
          
          if (audioUri == null || audioUri.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('Audio URI is required')),
            );
          }
          return AudioPreviewScreen(
            audioUri: audioUri,
            source: source,
            duration: duration,
            fileSize: fileSize,
          );
        },
      ),
      
      // Detail routes
      GoRoute(
        path: '/podcast/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _buildPageWithoutTransition(
              context,
              state,
              const Scaffold(body: Center(child: Text('Podcast ID is required'))),
            );
          }
          
          // Create a wrapper widget that loads the podcast
          return _buildPageWithoutTransition(
            context,
            state,
            WebNavigationLayout(
              child: _PodcastDetailLoader(podcastId: int.parse(id)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/movie/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return _buildPageWithoutTransition(
              context,
              state,
              const Scaffold(body: Center(child: Text('Movie ID is required'))),
            );
          }
          return _buildPageWithoutTransition(
            context,
            state,
            WebNavigationLayout(
              child: MovieDetailScreenWeb(movieId: int.parse(id)),
            ),
          );
        },
      ),
      
      // Artist routes - specific paths must come before parameterized paths
      GoRoute(
        path: '/artist/manage',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: ArtistProfileManageScreen()),
        ),
      ),
      GoRoute(
        path: '/artist/:artistId',
        pageBuilder: (context, state) {
          final artistId = state.pathParameters['artistId'];
          if (artistId == null) {
            return _buildPageWithoutTransition(
              context,
              state,
              const Scaffold(body: Center(child: Text('Artist ID is required'))),
            );
          }
          return _buildPageWithoutTransition(
            context,
            state,
            WebNavigationLayout(
              child: ArtistProfileScreen(artistId: int.parse(artistId)),
            ),
          );
        },
      ),
      
      // Player routes (full-screen)
      GoRoute(
        path: '/player/audio/:podcastId',
        builder: (context, state) {
          final podcastId = state.pathParameters['podcastId'];
          if (podcastId == null) {
            return const Scaffold(body: Center(child: Text('Podcast ID is required')));
          }
          return _PodcastPlayerLoader(
            podcastId: int.parse(podcastId),
            isVideo: false,
          );
        },
      ),
      GoRoute(
        path: '/player/video/:podcastId',
        builder: (context, state) {
          final podcastId = state.pathParameters['podcastId'];
          if (podcastId == null) {
            return const Scaffold(body: Center(child: Text('Podcast ID is required')));
          }
          return _PodcastPlayerLoader(
            podcastId: int.parse(podcastId),
            isVideo: true,
          );
        },
      ),
    ],
  );
}

/// Widget to load podcast by ID and display detail screen
class _PodcastDetailLoader extends StatefulWidget {
  final int podcastId;
  
  const _PodcastDetailLoader({required this.podcastId});
  
  @override
  State<_PodcastDetailLoader> createState() => _PodcastDetailLoaderState();
}

class _PodcastDetailLoaderState extends State<_PodcastDetailLoader> {
  bool _isLoading = true;
  String? _error;
  Widget? _content;
  
  @override
  void initState() {
    super.initState();
    _loadPodcast();
  }
  
  Future<void> _loadPodcast() async {
    try {
      final apiService = ApiService();
      final podcast = await apiService.getPodcast(widget.podcastId);
      final item = apiService.podcastToContentItem(podcast);
      
      if (mounted) {
        setState(() {
          _content = VideoPodcastDetailScreenWeb(item: item);
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading podcast: $_error'),
        ),
      );
    }
    
    return _content ?? const SizedBox();
  }
}

/// Widget to load podcast for full-screen player
class _PodcastPlayerLoader extends StatefulWidget {
  final int podcastId;
  final bool isVideo;
  
  const _PodcastPlayerLoader({
    required this.podcastId,
    required this.isVideo,
  });
  
  @override
  State<_PodcastPlayerLoader> createState() => _PodcastPlayerLoaderState();
}

class _PodcastPlayerLoaderState extends State<_PodcastPlayerLoader> {
  bool _isLoading = true;
  String? _error;
  Widget? _content;
  
  @override
  void initState() {
    super.initState();
    _loadPodcast();
  }
  
  Future<void> _loadPodcast() async {
    try {
      final apiService = ApiService();
      final podcast = await apiService.getPodcast(widget.podcastId);
      final item = apiService.podcastToContentItem(podcast);
      
      if (mounted) {
        setState(() {
          if (widget.isVideo) {
            // Navigate to video player
            _content = VideoPodcastDetailScreenWeb(item: item);
          } else {
            // Navigate to audio player - just play the track
            // Since AudioPlayerFullScreenWeb doesn't accept tracks parameter,
            // we'll navigate to the podcast detail which has audio player
            _content = VideoPodcastDetailScreenWeb(item: item);
          }
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
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading podcast: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return _content ?? const SizedBox();
  }
}

