import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/music_provider.dart';
import '../providers/community_provider.dart';
import '../providers/audio_player_provider.dart';
import '../providers/search_provider.dart';
import '../providers/user_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/support_provider.dart';
import '../providers/documents_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/artist_provider.dart';
import '../providers/event_provider.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import 'app_routes.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    super.initState();
    print('✅ AppRouter initState');
    // Initialize WebSocket connection asynchronously after first frame
    // This prevents blocking the build method and handles errors gracefully
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeWebSocket();
      _initializeStripe();
    });
  }

  void _initializeWebSocket() async {
    try {
      print('✅ AppRouter: Initializing WebSocket...');
      await WebSocketService().connect();
      print('✅ AppRouter: WebSocket connected');
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      // WebSocket connection is non-critical for app functionality
      print('❌ AppRouter: WebSocket connection failed (non-critical): $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _initializeStripe() async {
    try {
      // Stripe publishable key will be set when creating payment intent
      // For now, we'll initialize with empty key and update it later
      // The key will be fetched from backend when creating payment intent
      if (AppConfig.stripePublishableKey.isNotEmpty) {
        Stripe.publishableKey = AppConfig.stripePublishableKey;
        Stripe.merchantIdentifier = 'merchant.com.cnt.media';
        print('✅ AppRouter: Stripe SDK initialized with publishable key');
      } else {
        print('ℹ️  AppRouter: Stripe publishable key not set, will be fetched from backend');
      }
    } catch (e, stackTrace) {
      print('❌ AppRouter: Stripe initialization failed (non-critical): $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('✅ AppRouter: Building navigation...');
    // Always use web navigation - no platform detection needed
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerState()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => DocumentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ArtistProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Create GoRouter instance
          final router = createAppRouter(authProvider);
          
          return MaterialApp.router(
            title: 'CNT Media Platform',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

