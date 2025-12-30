import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive_utils.dart';
import 'landing_screen_web.dart';

/// Web Register Screen - Redesigned to match Landing Page Hero Section
/// Features full-screen jesus.png background with gradient overlay
/// Pill-shaped inputs and buttons following the hero section design
class RegisterScreenWeb extends StatefulWidget {
  final String? prefilledEmail;

  const RegisterScreenWeb({super.key, this.prefilledEmail});

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
  
  // OTP Flow State
  bool _isOTPSent = false;
  bool _isOTPVerified = false;
  final _otpController = TextEditingController();
  bool _isSendingOTP = false;
  bool _isVerifyingOTP = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    // Prefill email if provided
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
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _generateUsernamePreview() {
    // Clear username if both fields are empty
    if (_emailController.text.isEmpty && _nameController.text.isEmpty) {
      setState(() {
        _generatedUsername = null;
      });
      return;
    }

    // Prioritize email for username generation
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

    // If OTP not sent yet, send OTP first
    if (!_isOTPSent) {
      await _sendOTP();
      return;
    }

    // If OTP sent but not verified, verify OTP first
    if (_isOTPSent && !_isOTPVerified) {
      await _verifyOTP();
      return;
    }

    // If OTP verified, proceed with registration
    if (_isOTPVerified) {
      await _completeRegistration();
    }
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isSendingOTP = true;
      _otpError = null;
    });

    try {
      final authService = AuthService();
      await authService.sendOTP(_emailController.text.trim());
      
      setState(() {
        _isOTPSent = true;
        _isSendingOTP = false;
        _resendCountdown = 60; // 60 seconds countdown
      });

      // Start resend countdown timer
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_resendCountdown > 0) {
              _resendCountdown--;
            } else {
              timer.cancel();
            }
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification code sent to ${_emailController.text.trim()}'),
          backgroundColor: AppColors.successMain,
        ),
      );
    } catch (e) {
      setState(() {
        _isSendingOTP = false;
        _otpError = e.toString().replaceAll('Exception: ', '');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_otpError ?? 'Failed to send verification code'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() {
        _otpError = 'Please enter a 6-digit verification code';
      });
      return;
    }

    setState(() {
      _isVerifyingOTP = true;
      _otpError = null;
    });

    try {
      final authService = AuthService();
      final result = await authService.verifyOTP(
        _emailController.text.trim(),
        _otpController.text.trim(),
      );

      if (result['verified'] == true) {
        setState(() {
          _isOTPVerified = true;
          _isVerifyingOTP = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );

        // Automatically proceed to registration
        await _completeRegistration();
      } else {
        setState(() {
          _isVerifyingOTP = false;
          _otpError = result['message'] ?? 'Invalid verification code';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifyingOTP = false;
        _otpError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerWithOTP(
      email: _emailController.text.trim(),
      otpCode: _otpController.text.trim(),
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

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0) return;
    
    await _sendOTP();
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
                    left: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : (isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3),
                    right: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : (isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2),
                    top: ResponsiveUtils.isSmallMobile(context) ? 60 : (isMobile ? 80 : 100),
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
                        SizedBox(height: AppSpacing.extraLarge * 1.5),
                        
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
                        
                        // OTP Verification Section
                        if (_isOTPSent) ...[
                          SizedBox(height: AppSpacing.large),
                          Container(
                            padding: EdgeInsets.all(AppSpacing.large),
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warmBrown.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      color: AppColors.warmBrown,
                                      size: 20,
                                    ),
                                    SizedBox(width: AppSpacing.small),
                                    Expanded(
                                      child: Text(
                                        'Verification code sent to',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primaryDark.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.tiny),
                                Text(
                                  _emailController.text.trim(),
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.warmBrown,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.medium),
                                _buildPillTextField(
                                  controller: _otpController,
                                  hintText: 'Enter 6-digit code',
                                  icon: Icons.lock_outline,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  isMobile: isMobile,
                                  validator: (value) {
                                    if (_isOTPSent && !_isOTPVerified) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter verification code';
                                      }
                                      if (value.length != 6) {
                                        return 'Code must be 6 digits';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                if (_otpError != null) ...[
                                  SizedBox(height: AppSpacing.small),
                                  Text(
                                    _otpError!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.errorMain,
                                    ),
                                  ),
                                ],
                                SizedBox(height: AppSpacing.medium),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPillButton(
                                        label: _isVerifyingOTP 
                                            ? 'Verifying...' 
                                            : (_isOTPVerified ? 'Verified ✓' : 'Verify Code'),
                                        onPressed: _isVerifyingOTP || _isOTPVerified 
                                            ? null 
                                            : _handleRegister,
                                        isOutlined: false,
                                        isLoading: _isVerifyingOTP,
                                      ),
                                    ),
                                    if (!_isOTPVerified) ...[
                                      SizedBox(width: AppSpacing.medium),
                                      TextButton(
                                        onPressed: _resendCountdown > 0 ? null : _resendOTP,
                                        child: Text(
                                          _resendCountdown > 0
                                              ? 'Resend in ${_resendCountdown}s'
                                              : 'Resend Code',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: _resendCountdown > 0
                                                ? AppColors.textSecondary
                                                : AppColors.warmBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        SizedBox(height: AppSpacing.large),
                        
                        // Optional Fields Expandable (only show if OTP not sent or OTP verified)
                        if (!_isOTPSent || _isOTPVerified)
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
                                label: _isOTPSent 
                                    ? (_isOTPVerified ? 'Create Account' : (_isSendingOTP ? 'Sending...' : 'Send Verification Code'))
                                    : 'Create Account',
                                onPressed: (_isLoading || _isSendingOTP) ? null : _handleRegister,
                                isOutlined: false,
                                isLoading: _isLoading || _isSendingOTP,
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
                                label: _isOTPSent 
                                    ? (_isOTPVerified ? 'Create Account' : (_isSendingOTP ? 'Sending...' : 'Send Verification Code'))
                                    : 'Create Account',
                                onPressed: (_isLoading || _isSendingOTP) ? null : _handleRegister,
                                isOutlined: false,
                                isLoading: _isLoading || _isSendingOTP,
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
          left: isMobile 
              ? (ResponsiveUtils.isSmallMobile(context) ? AppSpacing.medium : AppSpacing.large) 
              : AppSpacing.extraLarge * 3,
          right: AppSpacing.extraLarge,
          top: AppSpacing.large,
          bottom: AppSpacing.large,
        ),
        child: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/CNT-LOGO.png',
              width: isMobile ? 28 : 32,
              height: isMobile ? 28 : 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.church,
                  color: AppColors.warmBrown,
                  size: isMobile ? 28 : 32,
                );
              },
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
    int? maxLength,
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
        maxLength: maxLength,
        onChanged: onChanged,
        validator: validator,
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
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
          filled: false,
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
                overflow: TextOverflow.visible,
              ),
      ),
    );
  }
}