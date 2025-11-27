import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/web_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';
import 'register_screen_web.dart';

/// Beautiful landing page with hybrid hero section and integrated login form
/// Features: Hero section with value proposition, feature showcase, and integrated login
class LandingScreenWeb extends StatefulWidget {
  const LandingScreenWeb({super.key});

  @override
  State<LandingScreenWeb> createState() => _LandingScreenWebState();
}

class _LandingScreenWebState extends State<LandingScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameOrEmailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        // All users (including admins) go to normal navigation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WebNavigationLayout(),
          ),
        );
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLogin();

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const WebNavigationLayout(),
          ),
        );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: isMobile
          ? _buildMobileLayout()
          : isTablet
              ? _buildTabletLayout()
              : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundTertiary,
              ],
            ),
          ),
        ),
        // Logo background image - positioned on left side only, filling entire section
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: MediaQuery.of(context).size.width * 0.6, // 60% width (left panel)
          child: Opacity(
            opacity: 0.6,
            child: Image.asset(
              'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Main content
        Row(
          children: [
            // Left Panel - Hero Section with Features (60%)
            Expanded(
              flex: 6,
              child: _buildHeroSection(),
            ),
            // Right Panel - Login Section (40%)
            Expanded(
              flex: 4,
              child: _buildLoginSection(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundTertiary,
              ],
            ),
          ),
        ),
        // Logo background image - positioned on top section (hero area)
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.5, // Top 50% (hero section)
          child: Center(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Main content
        Column(
          children: [
            // Hero Section (50% height)
            Expanded(
              flex: 1,
              child: _buildHeroSection(),
            ),
            // Login Section (50% height)
            Expanded(
              flex: 1,
              child: _buildLoginSection(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundTertiary,
              ],
            ),
          ),
        ),
        // Logo background image - positioned behind hero section only
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: MediaQuery.of(context).size.height * 0.5, // Top half (hero section area)
          child: Center(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Main content
        SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(),
              const SizedBox(height: AppSpacing.extraLarge),
              // Login Section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: _buildLoginCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width >= 1024
            ? AppSpacing.xxl
            : AppSpacing.extraLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature Cards - Bottom Section
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      _FeatureItem(
        icon: Icons.podcasts,
        title: 'Audio & Video Podcasts',
        description: 'Create and share your spiritual content',
        color: AppColors.primaryMain,
      ),
      _FeatureItem(
        icon: Icons.video_call,
        title: 'Meetings',
        description: 'Join or host live meetings and discussions',
        color: AppColors.accentMain,
      ),
      _FeatureItem(
        icon: Icons.people,
        title: 'Community',
        description: 'Connect and share with fellow believers',
        color: AppColors.warmBrown,
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (isMobile) {
      return Column(
        children: features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: _buildFeatureCard(feature),
        )).toList(),
      );
    } else if (isTablet) {
      return Row(
        children: features.map((feature) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: feature != features.last ? AppSpacing.medium : 0,
            ),
            child: _buildFeatureCard(feature),
          ),
        )).toList(),
      );
    } else {
      return Row(
        children: features.map((feature) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: feature != features.last ? AppSpacing.large : 0,
            ),
            child: _buildFeatureCard(feature),
          ),
        )).toList(),
      );
    }
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return SectionContainer(
      padding: const EdgeInsets.all(AppSpacing.large),
      backgroundColor: AppColors.cardBackground,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            feature.title,
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            feature.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection() {
    return Container(
      color: AppColors.backgroundPrimary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Welcome Message - Above Login
              Text(
                'Welcome to',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Christ New Tabernacle',
                style: AppTypography.heroTitle.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Your spiritual media platform for podcasts, meetings, and community',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              
              // Login Card
              _buildLoginCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? double.infinity : 450,
      ),
      child: SectionContainer(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        backgroundColor: AppColors.cardBackground,
        showShadow: true,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Sign In',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Welcome back to your spiritual community',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Username/Email Field
              TextFormField(
                controller: _usernameOrEmailController,
                keyboardType: TextInputType.text,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Username or Email',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.warmBrown,
                  ),
                  hintText: 'Enter username or email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username or email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.large),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.warmBrown,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.medium,
                  ),
                  backgroundColor: AppColors.warmBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              // Google Sign-In temporarily disabled
              // Uncomment below to enable Google Sign-In
              /*
              const SizedBox(height: AppSpacing.large),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderPrimary)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                    ),
                    child: Text(
                      'OR',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.borderPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.large),

              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.g_mobiledata,
                    size: 18,
                    color: Color(0xFF4285F4), // Google Blue
                  ),
                ),
                label: Text(
                  'Sign in with Google',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.medium,
                  ),
                  side: BorderSide(color: AppColors.borderPrimary),
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              */

              const SizedBox(height: AppSpacing.large),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreenWeb(),
                        ),
                      );
                    },
                    child: Text(
                      'Register',
                      style: AppTypography.body.copyWith(
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
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

