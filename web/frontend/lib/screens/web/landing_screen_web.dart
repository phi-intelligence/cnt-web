import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/api_models.dart';
import '../../models/content_item.dart';
import 'register_screen_web.dart';

/// Modern landing page following Living Scriptures design structure
/// Sections: Hero, Content Carousels, Features, Testimonials, Devices, Footer
class LandingScreenWeb extends StatefulWidget {
  const LandingScreenWeb({super.key});

  @override
  State<LandingScreenWeb> createState() => _LandingScreenWebState();
}

class _LandingScreenWebState extends State<LandingScreenWeb> {
  final _loginFormKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isLoadingContent = true;
  bool _rememberMe = false; // Netflix-style: default to session-only login
  
  List<ContentItem> _featuredMovies = [];
  List<ContentItem> _featuredPodcasts = [];

  @override
  void initState() {
    super.initState();
    _fetchFeaturedContent();
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeaturedContent() async {
    try {
      final apiService = ApiService();
      
      // Fetch featured movies
      final movies = await apiService.getFeaturedMovies(limit: 6);
      // Fetch approved podcasts
      final podcasts = await apiService.getPodcasts(
        limit: 6,
        status: 'approved',
        newestFirst: true,
      );

      if (mounted) {
        setState(() {
          _featuredMovies = movies.map((m) => apiService.movieToContentItem(m)).toList();
          _featuredPodcasts = podcasts.map((p) => apiService.podcastToContentItem(p)).toList();
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      print('Error fetching featured content: $e');
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  Future<void> _handleGetStarted() async {
    // Navigate directly to register page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreenWeb(),
      ),
    );
  }

  void _handleSignIn() {
    _showLoginDialog();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    // Set remember me preference before login (affects where tokens are stored)
    AuthService.setRememberMe(_rememberMe);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameOrEmailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin(BuildContext dialogContext) async {
    setState(() => _isLoading = true);
    
    // Auto-enable "Remember Me" for Google OAuth logins
    // Google users expect to stay logged in across browser sessions
    AuthService.setRememberMe(true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLogin();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Safely pop the dialog - it might already be dismissed
        try {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        } catch (e) {
          print('⚠️ Dialog already dismissed: $e');
        }
        if (authProvider.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Google sign-in failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            _buildMoviesShowcaseSection(),
            _buildPlatformAvailabilitySection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Hero section with header, headline, and CTA
  /// Hero section with header, headline, and CTA
  Widget _buildHeroSection() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Use ResponsiveUtils for breakpoints
    final isSmallMobile = screenWidth < 375;
    final isMobile = screenWidth < 640;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;
    
    return Container(
      width: double.infinity,
      height: screenHeight, // Full screen height
      child: Stack(
        children: [
          // Background: Full image - responsive, positioned more to the right
          Positioned(
            top: isMobile ? (isSmallMobile ? -30 : -50) : 0, 
            bottom: isMobile ? null : 0,
            // Adjust position for small screens to ensure face isn't covered
            right: isMobile 
                ? (isSmallMobile ? -screenWidth * 0.45 : -screenWidth * 0.3) 
                : -100, 
            height: isMobile ? screenHeight * (isSmallMobile ? 0.6 : 0.7) : null,
            width: isMobile 
                ? (isSmallMobile ? screenWidth * 1.5 : screenWidth * 1.2) 
                : screenWidth * 0.75,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/landing.png'),
                  fit: isMobile ? BoxFit.contain : BoxFit.cover,
                  alignment: isMobile ? Alignment.topRight : Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Gradient overlay from left - responsive
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isMobile
                      ? [
                          const Color(0xFFF5F0E8),
                          const Color(0xFFF5F0E8).withOpacity(0.95),
                          const Color(0xFFF5F0E8).withOpacity(0.7), // Increased opacity for readability
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFF5F0E8),
                          const Color(0xFFF5F0E8).withOpacity(0.98),
                          const Color(0xFFF5F0E8).withOpacity(0.85),
                          const Color(0xFFF5F0E8).withOpacity(0.3),
                          Colors.transparent,
                        ],
                  stops: isMobile
                      ? const [0.0, 0.4, 0.7, 1.0] // Pushed stops further to cover text area
                      : const [0.0, 0.25, 0.4, 0.5, 0.65],
                ),
              ),
            ),
          ),
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(isMobile, isSmallMobile),
          ),
          // Hero content on the left
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: isMobile ? screenWidth : screenWidth * 0.55,
            child: Center(
              child: Container(
                padding: EdgeInsets.only(
                  left: isMobile 
                      ? (isSmallMobile ? AppSpacing.medium : AppSpacing.large) 
                      : AppSpacing.extraLarge * 3,
                  right: isMobile 
                      ? (isSmallMobile ? AppSpacing.medium : AppSpacing.large) 
                      : AppSpacing.extraLarge,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main headline
                    Text(
                      'Christ New Tabernacle',
                      style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        // Dynamic font size scaling
                        fontSize: isSmallMobile 
                            ? 28 
                            : (isMobile ? 36 : (isTablet ? 48 : 56)),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.extraLarge),
                    
                    // Subtitle
                    Text(
                      'Uplifting movies, podcasts, and sermons.\nAlways ad free.',
                      style: AppTypography.getResponsiveBody(context).copyWith(
                        color: AppColors.primaryDark.withOpacity(0.8),
                        fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? AppSpacing.small : AppSpacing.medium),
                    Text(
                      'Watch Anywhere. Cancel Anytime.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primaryDark.withOpacity(0.6),
                        fontSize: isSmallMobile ? 12 : (isMobile ? 14 : 15),
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? AppSpacing.large : AppSpacing.extraLarge * 1.5),
                    
                    // Email signup
                    _buildEmailSignup(isMobile, isTablet, isSmallMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header with logo only
  Widget _buildHeader(bool isMobile, bool isSmallMobile) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: isMobile 
              ? (isSmallMobile ? AppSpacing.medium : AppSpacing.large) 
              : AppSpacing.extraLarge * 3,
          right: AppSpacing.extraLarge,
          top: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
          bottom: AppSpacing.large,
        ),
        child: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/CNT-LOGO.png',
              width: isSmallMobile ? 24 : (isMobile ? 28 : 32),
              height: isSmallMobile ? 24 : (isMobile ? 28 : 32),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.church,
                  color: AppColors.warmBrown,
                  size: isSmallMobile ? 24 : (isMobile ? 28 : 32),
                );
              },
            ),
            SizedBox(width: AppSpacing.small),
            Text(
              'Christ New Tabernacle',
              style: AppTypography.heading3.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Email signup form with LOG IN and Get Started buttons
  Widget _buildEmailSignup(bool isMobile, bool isTablet, bool isSmallMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buttons row
          isSmallMobile 
          ? Column(
              children: [
                // LOG IN button - outlined pill
                Container(
                  width: double.infinity,
                  child: _buildPillButton(
                    label: 'LOG IN',
                    onPressed: _handleSignIn,
                    isOutlined: true,
                    isSmallMobile: true,
                  ),
                ),
                SizedBox(height: AppSpacing.medium),
                // Get Started button - filled pill
                Container(
                  width: double.infinity,
                  child: _buildPillButton(
                    label: 'Get Started',
                    onPressed: _handleGetStarted,
                    isOutlined: false,
                    isSmallMobile: true,
                  ),
                ),
              ],
            )
          : Row(
            children: [
              // LOG IN button - outlined pill
              Expanded(
                child: _buildPillButton(
                  label: 'LOG IN',
                  onPressed: _handleSignIn,
                  isOutlined: true,
                ),
              ),
              SizedBox(width: AppSpacing.medium),
              // Get Started button - filled pill
              Expanded(
                child: _buildPillButton(
                  label: 'Get Started',
                  onPressed: _handleGetStarted,
                  isOutlined: false,
                ),
              ),
            ],
          ),
          // Feature circles row
          SizedBox(height: AppSpacing.extraLarge),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureCircle(Icons.chat_bubble_outline, 'Community', isMobile: true, isSmallMobile: isSmallMobile),
                SizedBox(width: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                _buildFeatureCircle(Icons.graphic_eq, 'Voice', isMobile: true, isSmallMobile: isSmallMobile),
                SizedBox(width: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                _buildFeatureCircle(Icons.videocam_outlined, 'Live', isMobile: true, isSmallMobile: isSmallMobile),
                SizedBox(width: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                _buildFeatureCircle(Icons.music_note, 'Music', isMobile: true, isSmallMobile: isSmallMobile),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons row
        Row(
          children: [
            // LOG IN button - outlined pill
            _buildPillButton(
              label: 'LOG IN',
              onPressed: _handleSignIn,
              isOutlined: true,
              width: 140,
            ),
            SizedBox(width: AppSpacing.medium),
            // Get Started button - filled pill
            _buildPillButton(
              label: 'Get Started',
              onPressed: _handleGetStarted,
              isOutlined: false,
              width: 160,
            ),
          ],
        ),
        // Feature circles row
        SizedBox(height: AppSpacing.extraLarge),
        Row(
          children: [
            _buildFeatureCircle(Icons.chat_bubble_outline, 'Community'),
            SizedBox(width: AppSpacing.extraLarge),
            _buildFeatureCircle(Icons.graphic_eq, 'Voice'),
            SizedBox(width: AppSpacing.extraLarge),
            _buildFeatureCircle(Icons.videocam_outlined, 'Live'),
            SizedBox(width: AppSpacing.extraLarge),
            _buildFeatureCircle(Icons.music_note, 'Music'),
          ],
        ),
      ],
    );
  }

  /// Feature circle button for hero section
  Widget _buildFeatureCircle(IconData icon, String label, {bool isMobile = false, bool isSmallMobile = false}) {
    final size = isSmallMobile ? 60.0 : (isMobile ? 72.0 : 96.0);
    final iconSize = isSmallMobile ? 24.0 : (isMobile ? 32.0 : 42.0);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.warmBrown,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ],
    );
  }

  /// Custom pill button with brown colors
  Widget _buildPillButton({
    required String label,
    required VoidCallback onPressed,
    required bool isOutlined,
    double? width,
    bool isSmallMobile = false,
  }) {
    final height = isSmallMobile ? 42.0 : 50.0;
    final fontSize = isSmallMobile ? 13.0 : 15.0;
    
    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppColors.warmBrown,
          foregroundColor: isOutlined ? AppColors.warmBrown : Colors.white,
          elevation: isOutlined ? 0 : 2,
          shadowColor: AppColors.warmBrown.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
            side: isOutlined
                ? BorderSide(color: AppColors.warmBrown, width: 2)
                : BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? AppSpacing.large : AppSpacing.extraLarge,
            vertical: isSmallMobile ? AppSpacing.small : AppSpacing.medium,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.button.copyWith(
            color: isOutlined ? AppColors.warmBrown : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  /// Movies showcase section with Jesus image on left and movies on right
  Widget _buildMoviesShowcaseSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Container(
      width: double.infinity,
      height: isMobile ? null : screenHeight * 0.85,
      constraints: isMobile ? null : BoxConstraints(minHeight: 600),
      child: isMobile
          ? _buildMoviesShowcaseMobile()
          : _buildMoviesShowcaseDesktop(screenWidth, isTablet),
    );
  }

  Widget _buildMoviesShowcaseMobile() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B7355),
            AppColors.warmBrown,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        children: [
          // Image section with gradient overlay
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 350,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/jesus-walking.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              // Bottom gradient fade
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.warmBrown.withOpacity(0.8),
                        AppColors.warmBrown,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Movies section
          Padding(
            padding: EdgeInsets.all(AppSpacing.extraLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Movies',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                SizedBox(height: AppSpacing.small),
                Text(
                  'Faith-filled films for the whole family',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textInverse.withOpacity(0.85),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: AppSpacing.extraLarge),
                _buildMovieCards(isMobile: true),
                SizedBox(height: AppSpacing.extraLarge),
                Center(
                  child: _buildShowcaseButton(
                    label: 'Browse All Movies',
                    onPressed: () {},
                    isMobile: true,
                  ),
                ),
                SizedBox(height: AppSpacing.large),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesShowcaseDesktop(double screenWidth, bool isTablet) {
    return Stack(
      children: [
        // Full background gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFFD4C4A8), // Light warm beige for image area
                  const Color(0xFFC4B090),
                  AppColors.warmBrown.withOpacity(0.95),
                  AppColors.primaryDark,
                ],
                stops: const [0.0, 0.35, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Content row
        Row(
          children: [
            // Left side - Jesus walking image with gradient blend
            Expanded(
              flex: isTablet ? 4 : 5,
              child: Stack(
                children: [
                  // Image - show full image including head
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/jesus-walking.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  // Right edge gradient to blend into content
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            AppColors.warmBrown.withOpacity(0.7),
                            AppColors.warmBrown.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right side - gradient with movies
            Expanded(
              flex: isTablet ? 6 : 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.warmBrown.withOpacity(0.95),
                      AppColors.warmBrown,
                      AppColors.primaryDark.withOpacity(0.95),
                      AppColors.primaryDark,
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? AppSpacing.extraLarge : AppSpacing.extraLarge * 2.5,
                    vertical: AppSpacing.extraLarge * 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.large,
                          vertical: AppSpacing.small,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentMain.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentMain.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          'WATCH NOW',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accentMain,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.large),
                      Text(
                        'Featured Movies',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 36 : 48,
                        ),
                      ),
                      SizedBox(height: AppSpacing.medium),
                      Text(
                        'Faith-filled films for the whole family.\nWatch inspiring stories of faith and hope.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textInverse.withOpacity(0.9),
                          fontSize: isTablet ? 16 : 18,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: AppSpacing.extraLarge * 1.5),
                      _buildMovieCards(isMobile: false),
                      SizedBox(height: AppSpacing.extraLarge * 1.5),
                      _buildShowcaseButton(
                        label: 'Browse All Movies',
                        onPressed: () {
                          // Navigate to movies
                        },
                        isMobile: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Platform availability section - showcases web and mobile availability
  /// Split layout: gradient with text on left, image on right
  /// Same height as featured movies section
  Widget _buildPlatformAvailabilitySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    if (isMobile) {
      return _buildPlatformAvailabilityMobile(screenHeight);
    }
    
    return Container(
      width: double.infinity,
      height: screenHeight * 0.85,
      constraints: BoxConstraints(minHeight: 600),
      child: Row(
        children: [
          // Left side - gradient with text (30%)
          Expanded(
            flex: isTablet ? 3 : 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primaryDark.withOpacity(0.95),
                    AppColors.warmBrown.withOpacity(0.9),
                    AppColors.warmBrown.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppSpacing.extraLarge : AppSpacing.extraLarge * 2.5,
                  vertical: AppSpacing.extraLarge * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available in Web and Mobile',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.backgroundPrimary,
                        fontSize: isTablet ? 32 : 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side - image (70%)
          Expanded(
            flex: isTablet ? 7 : 7,
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/christnew.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.mutedMain,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                color: AppColors.textSecondary,
                                size: 48,
                              ),
                              SizedBox(height: AppSpacing.medium),
                              Text(
                                'Image not available',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Left edge gradient to blend into content
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.warmBrown.withOpacity(0.7),
                          AppColors.warmBrown.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformAvailabilityMobile(double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.warmBrown,
          ],
        ),
      ),
      child: Column(
        children: [
          // Text section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.extraLarge * 1.5),
            child: Text(
              'Available in Web and Mobile',
              style: AppTypography.heading2.copyWith(
                color: AppColors.backgroundPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Image section
          Container(
            width: double.infinity,
            height: 300,
            child: Image.asset(
              'assets/images/christnew.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.mutedMain,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                        SizedBox(height: AppSpacing.medium),
                        Text(
                          'Image not available',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Styled button for showcase sections
  Widget _buildShowcaseButton({
    required String label,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Container(
      height: isMobile ? 48 : 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppColors.accentMain,
            AppColors.accentMain.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentMain.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.extraLarge : AppSpacing.extraLarge * 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            SizedBox(width: AppSpacing.small),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCards({required bool isMobile}) {
    // Get first 2 movies from featured movies, or use placeholders
    final moviesToShow = _featuredMovies.take(2).toList();

    if (_isLoadingContent) {
      return Row(
        children: [
          _buildMovieCardPlaceholder(isMobile),
          SizedBox(width: AppSpacing.large),
          _buildMovieCardPlaceholder(isMobile),
        ],
      );
    }

    if (moviesToShow.isEmpty) {
      return Row(
        children: [
          _buildMovieCardPlaceholder(isMobile),
          SizedBox(width: AppSpacing.large),
          _buildMovieCardPlaceholder(isMobile),
        ],
      );
    }

    return Row(
      children: moviesToShow.asMap().entries.map((entry) {
        final index = entry.key;
        final movie = entry.value;
        return Padding(
          padding: EdgeInsets.only(right: index < moviesToShow.length - 1 ? AppSpacing.large : 0),
          child: _buildMovieCard(movie, isMobile),
        );
      }).toList(),
    );
  }

  Widget _buildMovieCard(ContentItem movie, bool isMobile) {
    final cardWidth = isMobile ? 140.0 : 180.0;
    final cardHeight = isMobile ? 200.0 : 260.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Movie thumbnail
            movie.coverImage != null
                ? Image.network(
                    movie.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.warmBrown.withOpacity(0.3),
                        child: Icon(
                          Icons.movie,
                          color: AppColors.textInverse.withOpacity(0.5),
                          size: 48,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    child: Icon(
                      Icons.movie,
                      color: AppColors.textInverse.withOpacity(0.5),
                      size: 48,
                    ),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Movie title
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                movie.title,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Play icon
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: isMobile ? 16 : 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCardPlaceholder(bool isMobile) {
    final cardWidth = isMobile ? 140.0 : 180.0;
    final cardHeight = isMobile ? 200.0 : 260.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.warmBrown.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.movie,
          color: AppColors.textInverse.withOpacity(0.5),
          size: 48,
        ),
      ),
    );
  }

  /// Content carousel section
  Widget _buildContentCarousel({
    required String title,
    required String subtitle,
    required List<ContentItem> items,
    required bool isLoading,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.extraLarge * 1.5,
      ),
      color: AppColors.backgroundPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.small),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.extraLarge),
          
          // Content cards
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.extraLarge),
                child: CircularProgressIndicator(),
              ),
            )
          else if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.extraLarge),
                child: Text(
                  'Content coming soon',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: isMobile ? 200 : 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildContentCard(items[index], isMobile);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Individual content card
  Widget _buildContentCard(ContentItem item, bool isMobile) {
    final cardWidth = isMobile ? 160.0 : 220.0;
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            item.coverImage != null && item.coverImage!.isNotEmpty
                ? Image.network(
                    ApiService().getMediaUrl(item.coverImage!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.warmBrown,
                        child: Icon(
                          item.isMovie ? Icons.movie : Icons.mic,
                          color: AppColors.textInverse,
                          size: 48,
                        ),
                      );
                    },
                  )
                : Container(
                    color: AppColors.warmBrown,
                    child: Icon(
                      item.isMovie ? Icons.movie : Icons.mic,
                      color: AppColors.textInverse,
                      size: 48,
                    ),
                  ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
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
            ),
            // Title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  item.title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Tap handler
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (item.isMovie) {
                    context.go('/movie/${item.id}');
                  } else {
                    context.go('/podcast/${item.id}');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Features section
  Widget _buildFeaturesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    final features = [
      {
        'icon': Icons.family_restroom,
        'title': 'Family Centered',
        'description': 'Inspiring & uplifting content for all ages',
      },
      {
        'icon': Icons.block,
        'title': '100% Ad Free',
        'description': 'No ads anywhere, ever',
      },
      {
        'icon': Icons.menu_book,
        'title': 'Bible Study',
        'description': 'Read and study Scripture in-app',
      },
      {
        'icon': Icons.groups,
        'title': 'Community',
        'description': 'Connect with fellow believers',
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.extraLarge * 2,
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
      ),
      color: AppColors.mutedMain,
      child: Column(
        children: [
          Text(
            'Why Families Love CNT',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.extraLarge * 2),
          Wrap(
            spacing: AppSpacing.extraLarge,
            runSpacing: AppSpacing.extraLarge,
            alignment: WrapAlignment.center,
            children: features.map((feature) {
              return Container(
                width: isMobile ? (screenWidth - 64) / 2 : 220,
                padding: EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        size: isMobile ? 32 : 40,
                        color: AppColors.warmBrown,
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium),
                    Text(
                      feature['title'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.small),
                    Text(
                      feature['description'] as String,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.extraLarge * 2),
          StyledPillButton(
            label: 'Try Free',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RegisterScreenWeb(),
                ),
              );
            },
            width: isMobile ? double.infinity : 200,
          ),
        ],
      ),
    );
  }

  /// Devices section - placeholder for screenshots
  Widget _buildDevicesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.extraLarge * 2,
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.warmBrown.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Available on Web & Mobile',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.medium),
          Text(
            'Watch on your browser or download our mobile app',
            style: AppTypography.body.copyWith(
              color: AppColors.textInverse.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.extraLarge * 2),
          
          // Device icons placeholder - will be replaced with screenshots
          Wrap(
            spacing: AppSpacing.extraLarge * 2,
            runSpacing: AppSpacing.extraLarge,
            alignment: WrapAlignment.center,
            children: [
              _buildDeviceCard(
                icon: Icons.computer,
                label: 'Web Browser',
                subtitle: 'Chrome, Safari, Firefox',
                isMobile: isMobile,
              ),
              _buildDeviceCard(
                icon: Icons.phone_android,
                label: 'Mobile App',
                subtitle: 'iOS & Android',
                isMobile: isMobile,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.extraLarge * 2),
          StyledPillButton(
            label: 'Start Watching Now',
            onPressed: _handleSignIn,
            width: isMobile ? double.infinity : 250,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width - 64) / 2 : 200,
      padding: EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isMobile ? 48 : 64,
            color: AppColors.textInverse,
          ),
          SizedBox(height: AppSpacing.medium),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.small),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textInverse.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Footer section
  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.extraLarge,
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
      ),
      color: AppColors.primaryDark,
      child: Column(
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/CNT-LOGO.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.church,
                    color: AppColors.accentMain,
                    size: 28,
                  );
                },
              ),
              SizedBox(width: AppSpacing.small),
              Text(
                'Christ New Tabernacle',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.medium),
          Text(
            'A place of hope, meaning, and purpose.',
            style: AppTypography.body.copyWith(
              color: AppColors.textInverse.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.extraLarge),
          Divider(color: AppColors.textInverse.withOpacity(0.2)),
          SizedBox(height: AppSpacing.large),
          Text(
            '© ${DateTime.now().year} Christ New Tabernacle. All rights reserved.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textInverse.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Login modal dialog
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(AppSpacing.extraLarge),
          child: Form(
            key: _loginFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome Back',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.warmBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.extraLarge),
                
                // Email field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.warmBrown.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _usernameOrEmailController,
                    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Email or Username',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.warmBrown),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.all(AppSpacing.medium),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.large),
                
                // Password field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.warmBrown.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.warmBrown),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.all(AppSpacing.medium),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.medium),
                
                // Remember Me checkbox - Netflix style session handling
                StatefulBuilder(
                  builder: (context, setDialogState) => Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setDialogState(() {
                              _rememberMe = value ?? false;
                            });
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.warmBrown,
                          side: BorderSide(
                            color: AppColors.warmBrown.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.small),
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            _rememberMe = !_rememberMe;
                          });
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Text(
                          'Remember me',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Spacer(),
                      Tooltip(
                        message: 'When unchecked, you will be logged out when the browser closes',
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.large),
                
                // Login button
                StyledPillButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _handleLogin,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
                SizedBox(height: AppSpacing.large),
                
                // Divider with OR
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.borderPrimary,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                      child: Text(
                        'OR',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.borderPrimary,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.large),
                
                // Google Sign-In Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _handleGoogleLogin(dialogContext),
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: AppTypography.button.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.medium + 2,
                      horizontal: AppSpacing.large,
                    ),
                    side: BorderSide(color: AppColors.borderPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.large),
                
                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreenWeb(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Register',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warmBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
