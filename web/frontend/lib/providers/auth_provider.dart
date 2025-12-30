import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Timer? _tokenExpirationTimer;
  bool _isRefreshing = false; // Prevent concurrent refresh attempts

  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _user?['is_admin'] == true;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    // Start auth check in background - don't block UI
    checkAuthStatus();
    // Start periodic token expiration check
    _startTokenExpirationCheck();
    // Listen for visibility changes (user returns to tab/window)
    _setupVisibilityListener();
  }

  /// Setup listener for when user returns to the app/tab (web)
  void _setupVisibilityListener() {
    if (kIsWeb) {
      html.document.addEventListener('visibilitychange', (event) {
        if (html.document.visibilityState == 'visible') {
          print('🔍 App became visible, checking token...');
          _checkTokenExpiration();
        }
      });
    }
  }

  /// Start periodic check for token expiration (every 5 minutes)
  void _startTokenExpirationCheck() {
    _tokenExpirationTimer?.cancel();
    _tokenExpirationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkTokenExpiration();
    });
  }

  /// Check if token should be refreshed (expires within 5 minutes)
  bool _shouldRefreshToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      // Base64 decode with padding handling
      String normalized = payload;
      switch (payload.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final decoded = base64Decode(normalized);
      final json = jsonDecode(utf8.decode(decoded));
      final exp = json['exp'] as int?;
      if (exp == null) return false;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final timeUntilExpiration = expirationDate.difference(now);

      // Refresh if expires within 5 minutes
      return timeUntilExpiration.inMinutes <= 5;
    } catch (e) {
      return false;
    }
  }

  /// Check if token is expired and refresh if needed
  /// Uses _isRefreshing flag to prevent concurrent refresh attempts
  Future<void> _checkTokenExpiration() async {
    if (!_isAuthenticated || _isRefreshing) return;

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      // Check if access token expires within 5 minutes
      if (_shouldRefreshToken(token)) {
        print('🔄 Access token expires soon, refreshing...');
        _isRefreshing = true;
        final refreshed = await _authService.refreshAccessToken();
        _isRefreshing = false;

        if (!refreshed) {
          // Refresh failed - might be network issue, try again later
          print('⚠️ Token refresh failed, will retry');
          // Don't logout immediately - might be temporary
        } else {
          print('✅ Token proactively refreshed');
        }
      } else if (AuthService.isTokenExpired(token)) {
        // Token already expired - try refresh
        print('🔄 Access token expired, refreshing...');
        _isRefreshing = true;
        final refreshed = await _authService.refreshAccessToken();
        _isRefreshing = false;

        if (!refreshed) {
          // Refresh token also expired/revoked - logout
          print('⚠️ Refresh token expired/revoked, logging out');
          await logout();
          _error = 'Your session has expired. Please log in again.';
          notifyListeners();
        } else {
          print('✅ Expired token successfully refreshed');
        }
      }
    } catch (e) {
      _isRefreshing = false;
      print('Error checking token expiration: $e');
    }
  }

  @override
  void dispose() {
    _tokenExpirationTimer?.cancel();
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    // Don't set loading to true initially - show login screen immediately
    // Only check auth in background

    try {
      // Quick check - if no token exists, immediately show login screen
      final token = await _authService
          .getToken()
          .timeout(const Duration(milliseconds: 300), onTimeout: () => null);

      if (token != null && !AuthService.isTokenExpired(token)) {
        // Access token is valid - user is logged in
        _user = await _authService
            .getUser()
            .timeout(const Duration(milliseconds: 500), onTimeout: () => null);
        _isAuthenticated = _user != null;
        _startTokenExpirationCheck(); // Start auto-refresh timer
        _error = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Access token expired or missing - try refresh token
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        print('🔄 Access token expired, attempting refresh...');
        _isLoading = true;
        notifyListeners();

        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          // Successfully refreshed - user is logged in
          _user = await _authService.getUser().timeout(
              const Duration(milliseconds: 500),
              onTimeout: () => null);
          _isAuthenticated = _user != null;
          _startTokenExpirationCheck();
          print('✅ Auto-login successful via refresh token');
          _error = null;
        } else {
          // Refresh failed - user needs to log in
          print('⚠️ Auto-login failed - refresh token expired/revoked');
          _user = null;
          _isAuthenticated = false;
          await _authService.logout(); // Clear invalid tokens
        }
      } else {
        // No refresh token - user not logged in
        _user = null;
        _isAuthenticated = false;
      }
      _error = null;
    } catch (e) {
      print('Auth check error: $e');
      _error = 'Failed to check auth status: $e';
      _isAuthenticated = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(usernameOrEmail, password);
      _user = {
        'id': data['user_id'],
        'username': data['username'],
        'email': data['email'],
        'name': data['name'],
        'is_admin': data['is_admin'],
      };
      _isAuthenticated = true;
      _error = null;
      _startTokenExpirationCheck(); // Start automatic refresh timer
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tokenExpirationTimer?.cancel();
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _error = null;
    } catch (e) {
      _error = 'Logout error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force logout due to token expiration
  Future<void> logoutDueToExpiration() async {
    await logout();
    _error = 'Your session has expired. Please log in again.';
    notifyListeners();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    return await _authService.getAuthHeaders();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        bio: bio,
      );
      _user = {
        'id': data['user_id'],
        'username': data['username'],
        'email': data['email'],
        'name': data['name'],
        'is_admin': data['is_admin'],
      };
      _isAuthenticated = true;
      _error = null;
      _startTokenExpirationCheck(); // Start automatic refresh timer
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> googleLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get Google authentication result (may be id_token or access_token)
      final authResult = await _googleAuthService.signInWithGoogle();

      if (authResult == null) {
        _error = 'Google sign-in cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Send to backend with token type info
      final data = await _authService.googleLogin(
        authResult['token']!,
        tokenType: authResult['token_type'],
        email: authResult['email'],
        displayName: authResult['display_name'],
        photoUrl: authResult['photo_url'],
      );
      _user = {
        'id': data['user_id'],
        'username': data['username'],
        'email': data['email'],
        'name': data['name'],
        'is_admin': data['is_admin'],
      };
      _isAuthenticated = true;
      _error = null;
      _startTokenExpirationCheck(); // Start automatic refresh timer
      return true;
    } catch (e) {
      String errorMsg = e.toString();
      // Clean up the error message for display
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      }
      _error = errorMsg;
      _isAuthenticated = false;
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      return await _authService.checkUsername(username);
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  /// Send OTP to email
  Future<bool> sendOTP(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.sendOTP(email);
      _error = null;
      return result['success'] == true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String email, String otpCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(email, otpCode);
      if (result['success'] == true) {
        _error = null;
        return true;
      } else {
        _error = result['message'] ?? 'Verification failed';
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register with OTP verification
  Future<bool> registerWithOTP({
    required String email,
    required String otpCode,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.registerWithOTP(
        email: email,
        otpCode: otpCode,
        password: password,
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        bio: bio,
      );
      _user = {
        'id': data['user_id'],
        'username': data['username'],
        'email': data['email'],
        'name': data['name'],
        'is_admin': data['is_admin'],
      };
      _isAuthenticated = true;
      _error = null;
      _startTokenExpirationCheck(); // Start automatic refresh timer
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _user = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCachedUser(Map<String, dynamic> updates) async {
    Map<String, dynamic>? baseUser = _user;
    if (baseUser == null) {
      baseUser = await _authService.getUser();
    }

    _user = {
      ...?baseUser,
      ...updates,
    };

    await _authService.updateStoredUser(_user!);
    notifyListeners();
  }
}
