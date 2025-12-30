import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'register_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Image at the top
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/cnt-dove-logo.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            // Login Form Container with pill-shaped top
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.extraLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLarge * 2),
                    topRight: Radius.circular(AppSpacing.radiusLarge * 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // Title Text at top of box
                      Text(
                        'Christ New Tabernacle',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.warmBrown,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.extraLarge),
                      // Username/Email Field
                      TextFormField(
                            controller: _usernameOrEmailController,
                            keyboardType: TextInputType.text,
                            style: AppTypography.body,
                            decoration: InputDecoration(
                              labelText: 'Username or Email',
                              labelStyle: AppTypography.label.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppColors.primaryMain,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundPrimary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.primaryMain,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.errorMain,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.errorMain,
                                  width: 2,
                                ),
                              ),
                              hintText: 'Enter username or email',
                              hintStyle: AppTypography.body.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.large,
                                vertical: AppSpacing.medium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username or email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.large),
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTypography.body,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: AppTypography.label.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryMain,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundPrimary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.borderPrimary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.primaryMain,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.errorMain,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                borderSide: BorderSide(
                                  color: AppColors.errorMain,
                                  width: 2,
                                ),
                              ),
                              hintText: 'Enter your password',
                              hintStyle: AppTypography.body.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.large,
                                vertical: AppSpacing.medium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSpacing.extraLarge),
                          // Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warmBrown,
                                  foregroundColor: AppColors.textInverse,
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.medium,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  ),
                                  elevation: 4,
                                ),
                                child: authProvider.isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.textInverse,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: AppTypography.button.copyWith(
                                          color: AppColors.textInverse,
                                        ),
                                      ),
                              );
                            },
                          ),
                      SizedBox(height: AppSpacing.large),
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.small,
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primaryMain,
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
}
