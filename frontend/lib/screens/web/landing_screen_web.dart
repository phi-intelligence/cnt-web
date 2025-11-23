import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/web_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'register_screen_web.dart';

/// Beautiful landing page with split-screen layout (image + login box)
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
    return Row(
      children: [
        // Left Panel - Image Section (60%)
        Expanded(
          flex: 6,
          child: _buildImageSection(),
        ),
        // Right Panel - Login Section (40%)
        Expanded(
          flex: 4,
          child: _buildLoginSection(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Image Section (50% height)
        Expanded(
          flex: 1,
          child: _buildImageSection(),
        ),
        // Login Section (50% height)
        Expanded(
          flex: 1,
          child: _buildLoginSection(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Full-screen background image
        Positioned.fill(
          child: _buildImageSection(),
        ),
        // Login card overlay
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.asset(
          'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // Gradient Overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        // Welcome Content (desktop/tablet only)
        if (MediaQuery.of(context).size.width >= 768)
          Positioned(
            left: MediaQuery.of(context).size.width >= 1024 ? 48 : 24,
            right: MediaQuery.of(context).size.width >= 1024 ? null : 24,
            bottom: MediaQuery.of(context).size.width >= 1024 ? 48 : 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Christ New Tabernacle',
                  style: AppTypography.heading1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Welcome to your spiritual media platform',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    shadows: [
                      const Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 8,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Container(
      color: AppColors.backgroundPrimary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: _buildLoginCard(),
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
      child: Card(
        elevation: isMobile ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isMobile ? 0.98 : 1.0),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Icon(
                  Icons.church,
                  size: isMobile ? 56 : 64,
                  color: AppColors.warmBrown,
                ),
                const SizedBox(height: AppSpacing.large),

                // Title
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
                  'Sign in to your account',
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
                    color: Colors.black,
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
                    color: Colors.black,
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
      ),
    );
  }
}

