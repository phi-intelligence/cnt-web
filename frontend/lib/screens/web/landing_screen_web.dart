import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/web_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
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


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(isMobile, isTablet),
            _buildFeaturesSection(isMobile, isTablet),
            _buildLoginSection(isMobile, isTablet),
          ],
        ),
      ),
    );
  }


  Widget _buildHeroSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isMobile ? 500 : isTablet ? 600 : 700,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.primaryDark.withOpacity(0.7),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark.withOpacity(0.6),
              AppColors.warmBrown.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.large : AppSpacing.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    color: AppColors.accentMain.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(
                      color: AppColors.accentMain.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.church,
                    size: isMobile ? 64 : isTablet ? 80 : 100,
                    color: AppColors.accentMain,
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                Text(
                  'Welcome to Christ New Tabernacle',
                  style: AppTypography.heroTitle.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 32 : isTablet ? 42 : 56,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 700,
                  ),
                  child: Text(
                    'A place of hope, meaning, and purpose. Experience God\'s word through engaging podcasts, Bible stories, music, and spiritual guidance. Join our community of believers in Christ.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textInverse.withOpacity(0.95),
                      height: 1.6,
                      fontSize: isMobile ? 16 : 18,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreenWeb(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentMain,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.extraLarge * 2,
                      vertical: AppSpacing.large,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    'JOIN OUR COMMUNITY',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile, bool isTablet) {
    final features = [
      _FeatureItem(
        icon: Icons.podcasts,
        title: 'Audio & Video Podcasts',
        description: 'Create, share, and listen to inspiring spiritual content',
        color: AppColors.primaryMain,
      ),
      _FeatureItem(
        icon: Icons.music_note,
        title: 'Christian Music',
        description: 'Access a library of worship songs and gospel music',
        color: AppColors.accentMain,
      ),
      _FeatureItem(
        icon: Icons.book,
        title: 'Bible Stories',
        description: 'Read and explore Bible stories and teachings',
        color: AppColors.warmBrown,
      ),
      _FeatureItem(
        icon: Icons.video_call,
        title: 'Live Meetings',
        description: 'Join or host live meetings and discussions',
        color: AppColors.primaryMain,
      ),
      _FeatureItem(
        icon: Icons.radio,
        title: 'Live Streaming',
        description: 'Watch and participate in live broadcasts',
        color: AppColors.accentMain,
      ),
      _FeatureItem(
        icon: Icons.people,
        title: 'Community',
        description: 'Connect and share with fellow believers',
        color: AppColors.warmBrown,
      ),
      _FeatureItem(
        icon: Icons.favorite,
        title: 'Prayer',
        description: 'Join prayer sessions and spiritual support',
        color: AppColors.primaryMain,
      ),
      _FeatureItem(
        icon: Icons.create,
        title: 'Content Creation',
        description: 'Create and share your own spiritual content',
        color: AppColors.accentMain,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.large : AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundSecondary,
            AppColors.backgroundPrimary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.extraLarge,
              vertical: AppSpacing.medium,
            ),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              'Platform Features',
              style: AppTypography.heading1.copyWith(
                color: AppColors.warmBrown,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Everything you need for your spiritual journey in one place',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.extraLarge),
          isMobile
              ? Column(
                  children: features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _buildFeatureCard(feature),
                  )).toList(),
                )
              : isTablet
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.medium,
                        mainAxisSpacing: AppSpacing.medium,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        return _buildFeatureCard(features[index]);
                      },
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: AppSpacing.large,
                        mainAxisSpacing: AppSpacing.large,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: features.length,
                      itemBuilder: (context, index) {
                        return _buildFeatureCard(features[index]);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: feature.color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  feature.color.withOpacity(0.2),
                  feature.color.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: feature.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            feature.title,
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            feature.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSection(bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.large : AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
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
      child: isMobile
          ? _buildLoginCard(isMobile)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildLogoSection(),
                ),
                const SizedBox(width: AppSpacing.extraLarge * 2),
                Expanded(
                  flex: 1,
                  child: _buildLoginCard(isMobile),
                ),
              ],
            ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.church,
                    size: 80,
                    color: AppColors.warmBrown,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.extraLarge),
        Text(
          'Christ New Tabernacle',
          style: AppTypography.heading1.copyWith(
            color: AppColors.warmBrown,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          'Christian Media Platform',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: AppTypography.heading2.copyWith(
                color: AppColors.warmBrown,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Sign in to continue your spiritual journey',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.extraLarge),
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
                elevation: 3,
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
                      style: AppTypography.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.large),
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

