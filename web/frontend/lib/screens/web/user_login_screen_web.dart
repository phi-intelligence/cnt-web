import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import 'register_screen_web.dart';

class UserLoginScreenWeb extends StatefulWidget {
  const UserLoginScreenWeb({super.key});

  @override
  State<UserLoginScreenWeb> createState() => _UserLoginScreenWebState();
}

class _UserLoginScreenWebState extends State<UserLoginScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController(text: 'samuel@christtabernacle.com');
  final _passwordController = TextEditingController(text: 'user123');
  bool _obscurePassword = true;

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameOrEmailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        // All users (including admins) go to normal navigation
        // Admin dashboard is accessible from profile or navigation menu
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

  @override
  Widget build(BuildContext context) {
    // Add responsive check
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallMobile ? 12.0 : 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 450,
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallMobile ? AppSpacing.medium : AppSpacing.extraLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Image.asset(
                        'assets/images/CNT-LOGO.png',
                        width: isSmallMobile ? 48 : 64,
                        height: isSmallMobile ? 48 : 64,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.church,
                            size: isSmallMobile ? 48 : 64,
                            color: AppColors.primaryMain,
                          );
                        },
                      ),
                      SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                      
                      // Title
                      Text(
                        'Welcome Back',
                        style: AppTypography.heading1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: isSmallMobile ? 24 : null, // Scale down title
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Sign in to continue',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallMobile ? AppSpacing.large : AppSpacing.extraLarge),
                      
                      // Username or Email Field
                      TextFormField(
                        controller: _usernameOrEmailController,
                        keyboardType: TextInputType.text,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          labelText: 'Username or Email',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.person, color: AppColors.primaryMain),
                          hintText: 'Enter username or email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundSecondary,
                          // Adjust styling for small mobile
                          contentPadding: isSmallMobile ? EdgeInsets.symmetric(horizontal: 12, vertical: 12) : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username or email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.lock, color: AppColors.primaryMain),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundSecondary,
                          contentPadding: isSmallMobile ? EdgeInsets.symmetric(horizontal: 12, vertical: 12) : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isSmallMobile ? AppSpacing.large : AppSpacing.extraLarge),
                      
                      // Login Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: AppTypography.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),
                      SizedBox(height: isSmallMobile ? AppSpacing.medium : AppSpacing.large),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Don\'t have an account? ',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isSmallMobile ? 14 : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreenWeb(),
                                ),
                              );
                            },
                            child: Text(
                              'Register',
                              style: AppTypography.body.copyWith(
                                color: AppColors.primaryMain,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallMobile ? 14 : null,
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
        ),
      ),
    );
  }
}

