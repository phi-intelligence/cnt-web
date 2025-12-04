import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'landing_screen_web.dart';

/// Web Register Screen - Redesigned to match Landing Page Hero Section
/// Features full-screen jesus.png background with gradient overlay
/// Pill-shaped inputs and buttons following the hero section design
class RegisterScreenWeb extends StatefulWidget {
  final String? prefilledEmail;
  
  const RegisterScreenWeb({
    super.key,
    this.prefilledEmail,
  });

  @override
  State<RegisterScreenWeb> createState() => _RegisterScreenWebState();
}

class _RegisterScreenWebState extends State<RegisterScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _selectedDateOfBirth;
  String? _generatedUsername;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if provided from landing page
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
      _generateUsernamePreview();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _generateUsernamePreview() {
    if (_emailController.text.isNotEmpty) {
      final email = _emailController.text.trim();
      if (email.contains('@')) {
        final username = email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
        setState(() {
          _generatedUsername = username;
        });
      }
    } else if (_nameController.text.isNotEmpty) {
      final name = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
      setState(() {
        _generatedUsername = name;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.warmBrown,
              onPrimary: Colors.white,
              surface: AppColors.backgroundSecondary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (authProvider.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isGoogleLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLogin();

    setState(() => _isGoogleLoading = false);

    if (mounted) {
      if (success) {
        if (authProvider.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Google sign-up failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: double.infinity,
        height: screenHeight,
        child: Stack(
          children: [
            // Background: Full image - positioned to the right
            Positioned(
              top: isMobile ? -30 : 0,
              bottom: isMobile ? null : 0,
              right: isMobile ? -screenWidth * 0.4 : -50,
              height: isMobile ? screenHeight * 0.6 : null,
              width: isMobile ? screenWidth * 1.3 : screenWidth * 0.65,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/jesus.png'),
                    fit: isMobile ? BoxFit.contain : BoxFit.cover,
                    alignment: isMobile ? Alignment.topRight : Alignment.centerRight,
                  ),
                ),
              ),
            ),
            
            // Gradient overlay from left - for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isMobile
                        ? [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.98),
                            const Color(0xFFF5F0E8).withOpacity(0.85),
                            const Color(0xFFF5F0E8).withOpacity(0.4),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.99),
                            const Color(0xFFF5F0E8).withOpacity(0.95),
                            const Color(0xFFF5F0E8).withOpacity(0.7),
                            const Color(0xFFF5F0E8).withOpacity(0.3),
                            Colors.transparent,
                          ],
                    stops: isMobile
                        ? const [0.0, 0.2, 0.4, 0.6, 0.8]
                        : const [0.0, 0.25, 0.4, 0.5, 0.6, 0.75],
                  ),
                ),
              ),
            ),
            
            // Header with logo
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(isMobile),
            ),
            
            // Form content on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: isMobile ? screenWidth : (isTablet ? screenWidth * 0.65 : screenWidth * 0.55),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                    right: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                    top: isMobile ? 80 : 100,
                    bottom: AppSpacing.extraLarge,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Create Account',
                          style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 28 : (isTablet ? 36 : 42),
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: AppSpacing.medium),
                        
                        // Subtitle
                        Text(
                          'Join Christ New Tabernacle\nand start your spiritual journey',
                          style: AppTypography.getResponsiveBody(context).copyWith(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: AppSpacing.extraLarge),
                        
                        // Google Sign Up Button
                        _buildGoogleSignupButton(isMobile),
                        
                        SizedBox(height: AppSpacing.large),
                        
                        // Divider with "or"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.warmBrown.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                              child: Text(
                                'or continue with email',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryDark.withOpacity(0.5),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.warmBrown.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: AppSpacing.large),
                        
                        // Form Fields
                        _buildPillTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          icon: Icons.person_outline,
                          onChanged: (_) => _generateUsernamePreview(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        SizedBox(height: AppSpacing.medium),
                        
                        _buildPillTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _generateUsernamePreview(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        SizedBox(height: AppSpacing.medium),
                        
                        _buildPillTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.warmBrown.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          isMobile: isMobile,
                        ),
                        SizedBox(height: AppSpacing.medium),
                        
                        _buildPillTextField(
                          controller: _phoneController,
                          hintText: 'Phone (optional)',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          isMobile: isMobile,
                        ),
                        
                        // Username preview
                        if (_generatedUsername != null) ...[
                          SizedBox(height: AppSpacing.medium),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.large,
                              vertical: AppSpacing.small + 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warmBrown.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.alternate_email,
                                  color: AppColors.warmBrown,
                                  size: 16,
                                ),
                                SizedBox(width: AppSpacing.small),
                                Text(
                                  'Username: $_generatedUsername',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warmBrown,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        SizedBox(height: AppSpacing.large),
                        
                        // Optional Fields Expandable
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Additional Information (Optional)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryDark.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          iconColor: AppColors.warmBrown,
                          collapsedIconColor: AppColors.warmBrown.withOpacity(0.6),
                          children: [
                            SizedBox(height: AppSpacing.small),
                            // Date of Birth
                            _buildPillDatePicker(isMobile: isMobile),
                            SizedBox(height: AppSpacing.medium),
                            // Bio
                            _buildPillTextField(
                              controller: _bioController,
                              hintText: 'Tell us about yourself...',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              isMobile: isMobile,
                            ),
                            SizedBox(height: AppSpacing.medium),
                          ],
                        ),
                        
                        SizedBox(height: AppSpacing.extraLarge),
                        
                        // Buttons Row
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPillButton(
                                label: 'Create Account',
                                onPressed: _isLoading ? null : _handleRegister,
                                isOutlined: false,
                                isLoading: _isLoading,
                              ),
                              SizedBox(height: AppSpacing.medium),
                              _buildPillButton(
                                label: 'Back to Login',
                                onPressed: () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const LandingScreenWeb()),
                                ),
                                isOutlined: true,
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: AppSpacing.medium,
                            runSpacing: AppSpacing.medium,
                            children: [
                              _buildPillButton(
                                label: 'Back to Login',
                                onPressed: () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const LandingScreenWeb()),
                                ),
                                isOutlined: true,
                                width: 180,
                              ),
                              _buildPillButton(
                                label: 'Create Account',
                                onPressed: _isLoading ? null : _handleRegister,
                                isOutlined: false,
                                isLoading: _isLoading,
                                width: 200,
                              ),
                            ],
                          ),
                        
                        SizedBox(height: AppSpacing.extraLarge),
                        
                        // Login link
                        Row(
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryDark.withOpacity(0.6),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LandingScreenWeb()),
                              ),
                              child: Text(
                                'Sign In',
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
            ),
          ],
        ),
      ),
    );
  }

  /// Header with logo - matching landing page
  Widget _buildHeader(bool isMobile) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
          right: AppSpacing.extraLarge,
          top: AppSpacing.large,
          bottom: AppSpacing.large,
        ),
        child: Row(
          children: [
            // Logo
            Icon(
              Icons.church,
              color: AppColors.warmBrown,
              size: isMobile ? 28 : 32,
            ),
            SizedBox(width: AppSpacing.small),
            Text(
              'Christ New Tabernacle',
              style: AppTypography.heading3.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill-shaped text field matching hero section design
  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    required bool isMobile,
  }) {
    final maxWidth = isMobile ? double.infinity : 450.0;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 30),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        style: AppTypography.body.copyWith(
          color: AppColors.primaryDark,
          fontSize: isMobile ? 14 : 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.primaryDark.withOpacity(0.4),
            fontSize: isMobile ? 14 : 15,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: AppSpacing.large, right: AppSpacing.small),
            child: Icon(
              icon,
              color: AppColors.warmBrown.withOpacity(0.7),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: maxLines > 1 ? AppSpacing.medium : AppSpacing.medium + 4,
          ),
          errorStyle: TextStyle(
            color: AppColors.errorMain,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Pill-shaped date picker
  Widget _buildPillDatePicker({required bool isMobile}) {
    final maxWidth = isMobile ? double.infinity : 450.0;
    
    return GestureDetector(
      onTap: _selectDateOfBirth,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.warmBrown.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium + 4,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.warmBrown.withOpacity(0.7),
              size: 20,
            ),
            SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Text(
                _selectedDateOfBirth == null
                    ? 'Date of Birth (optional)'
                    : DateFormat('MMMM d, yyyy').format(_selectedDateOfBirth!),
                style: AppTypography.body.copyWith(
                  color: _selectedDateOfBirth == null
                      ? AppColors.primaryDark.withOpacity(0.4)
                      : AppColors.primaryDark,
                  fontSize: isMobile ? 14 : 15,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.warmBrown.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill-shaped button matching hero section design
  Widget _buildPillButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isOutlined,
    double? width,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: width,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppColors.warmBrown,
          foregroundColor: isOutlined ? AppColors.warmBrown : Colors.white,
          elevation: isOutlined ? 0 : 3,
          shadowColor: AppColors.warmBrown.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: isOutlined
                ? BorderSide(color: AppColors.warmBrown, width: 2)
                : BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.extraLarge + 8,
            vertical: AppSpacing.medium,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined ? AppColors.warmBrown : Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: AppTypography.button.copyWith(
                  color: isOutlined ? AppColors.warmBrown : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  /// Google Sign Up button - pill shaped to match design
  Widget _buildGoogleSignupButton(bool isMobile) {
    final maxWidth = isMobile ? double.infinity : 450.0;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      height: 52,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignup,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDark,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          side: BorderSide(
            color: AppColors.warmBrown.withOpacity(0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.extraLarge,
            vertical: AppSpacing.medium,
          ),
        ),
        child: _isGoogleLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 22,
                    width: 22,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.g_mobiledata,
                      size: 26,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                  SizedBox(width: AppSpacing.medium),
                  Text(
                    'Sign up with Google',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}