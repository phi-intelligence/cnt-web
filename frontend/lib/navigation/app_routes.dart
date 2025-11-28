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
import '../providers/auth_provider.dart';

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
      
      // Main navigation routes (wrapped in WebNavigationLayout)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreenWeb(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreenWeb(),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreateScreenWeb(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return CommunityScreenWeb(
            postId: postId != null ? int.tryParse(postId) : null,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreenWeb(),
      ),
      GoRoute(
        path: '/podcasts',
        builder: (context, state) => const PodcastsScreenWeb(),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MoviesScreenWeb(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreenWeb(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      
      // Meeting routes
      GoRoute(
        path: '/meetings',
        builder: (context, state) => const MeetingOptionsScreenWeb(),
      ),
      
      // Live stream routes
      GoRoute(
        path: '/live-stream/options',
        builder: (context, state) => const LiveStreamOptionsScreenWeb(),
      ),
      GoRoute(
        path: '/live-stream/start',
        builder: (context, state) => const LiveStreamStartScreen(),
      ),
      GoRoute(
        path: '/live-streams',
        builder: (context, state) => const LiveScreenWeb(),
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
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return const Scaffold(body: Center(child: Text('Podcast ID is required')));
          }
          return VideoPodcastDetailScreenWeb(podcastId: int.parse(id));
        },
      ),
      GoRoute(
        path: '/movie/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null) {
            return const Scaffold(body: Center(child: Text('Movie ID is required')));
          }
          return MovieDetailScreenWeb(movieId: int.parse(id));
        },
      ),
    ],
  );
}

