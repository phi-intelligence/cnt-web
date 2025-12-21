import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_helper.dart';
import 'web_storage_service.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  /// Write to storage (uses WebStorageService on web, FlutterSecureStorage on mobile)
  static Future<void> _write({required String key, required String value}) async {
    if (kIsWeb) {
      await WebStorageService.write(key: key, value: value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }
  
  /// Read from storage (uses WebStorageService on web, FlutterSecureStorage on mobile)
  static Future<String?> _read({required String key}) async {
    if (kIsWeb) {
      return await WebStorageService.read(key: key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }
  
  /// Delete from storage (uses WebStorageService on web, FlutterSecureStorage on mobile)
  static Future<void> _delete({required String key}) async {
    if (kIsWeb) {
      await WebStorageService.delete(key: key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
  
  /// Set "Remember Me" preference (web only)
  static void setRememberMe(bool value) {
    WebStorageService.setRememberMe(value);
  }
  
  /// Get "Remember Me" preference (web only)
  static bool get rememberMeEnabled => WebStorageService.rememberMeEnabled;
  
  static String get baseUrl {
    // Check for dart-define first (for USB-connected devices)
    const envUrl = String.fromEnvironment('API_BASE');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to PlatformHelper
    return PlatformHelper.getApiBaseUrl();
  }
  
  /// Login with username or email and password
  Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    try {
      print('🔐 Attempting login to: $baseUrl/auth/login');
      print('👤 Username/Email: $usernameOrEmail');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username_or_email': usernameOrEmail,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network connection and ensure the backend is running at $baseUrl');
        },
      );
      
      print('📡 Login response status: ${response.statusCode}');
      print('📄 Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store token, refresh token, and user data
        await _write(key: _tokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        await _write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Token, refresh token, and user data stored successfully');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Login failed with status ${response.statusCode}: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Login failed');
        } catch (_) {
          throw Exception('Login failed: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      print('💥 Login exception: $e');
      if (e.toString().contains('timeout')) {
        throw e; // Re-throw timeout as-is
      }
      throw Exception('Login error: $e');
    }
  }
  
  /// Get stored authentication token
  Future<String?> getToken() async {
    return await _read(key: _tokenKey);
  }
  
  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _read(key: _refreshTokenKey);
  }
  
  /// Get stored user data
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Check if JWT token is expired
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
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
      final Map<String, dynamic> json = jsonDecode(utf8.decode(decoded));
      
      final exp = json['exp'] as int?;
      if (exp == null) return true;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final isExpired = DateTime.now().isAfter(expirationDate);
      
      if (isExpired) {
        print('⚠️ Token expired. Expiration: ${expirationDate.toIso8601String()}, Now: ${DateTime.now().toIso8601String()}');
      }
      
      return isExpired;
    } catch (e) {
      print('⚠️ Error checking token expiration: $e');
      return true; // If we can't decode, assume expired
    }
  }
  
  /// Check if stored token is expired
  Future<bool> isStoredTokenExpired() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return true;
    return isTokenExpired(token);
  }
  
  /// Check if user is authenticated (and token is not expired)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    return !isTokenExpired(token);
  }
  
  /// Check if user is admin
  Future<bool> isAdmin() async {
    final user = await getUser();
    return user?['is_admin'] == true;
  }
  
  /// Logout
  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      
      // Revoke refresh token on backend
      if (refreshToken != null) {
        try {
          await http.post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Continue even if logout request fails
          print('Logout request failed: $e');
        }
      }
      
      // Clear local storage
      await _delete(key: _tokenKey);
      await _delete(key: _refreshTokenKey);
      await _delete(key: _userKey);
      
      // On web, also clear the specific web storage
      if (kIsWeb) {
        await WebStorageService.clearAuthData();
      }
      
      print('✅ Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      // Still clear local storage even if backend call fails
      await _delete(key: _tokenKey);
      await _delete(key: _refreshTokenKey);
      await _delete(key: _userKey);
    }
  }
  
  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    try {
      print('📝 Attempting registration to: $baseUrl/auth/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
          if (bio != null) 'bio': bio,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network connection.');
        },
      );
      
      print('📡 Registration response status: ${response.statusCode}');
      print('📄 Registration response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store token, refresh token, and user data
        await _write(key: _tokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        await _write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Registration successful and tokens stored');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Registration failed with status ${response.statusCode}: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Registration failed');
        } catch (_) {
          throw Exception('Registration failed: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      print('💥 Registration exception: $e');
      throw Exception('Registration error: $e');
    }
  }
  
  /// Login with Google
  /// Supports both id_token and access_token (fallback for web)
  Future<Map<String, dynamic>> googleLogin(
    String token, {
    String? tokenType,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      print('🔐 Attempting Google login to: $baseUrl/auth/google-login');
      print('🔑 Token type: ${tokenType ?? 'id_token'}');
      
      // Build request body based on token type
      final Map<String, dynamic> body = {};
      
      if (tokenType == 'access_token') {
        // Use access token with user info from Google SDK
        body['access_token'] = token;
        body['token_type'] = 'access_token';
        if (email != null) body['email'] = email;
        if (displayName != null) body['name'] = displayName;
        if (photoUrl != null) body['picture'] = photoUrl;
      } else {
        // Default: use id_token
        body['id_token'] = token;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network connection.');
        },
      );
      
      print('📡 Google login response status: ${response.statusCode}');
      print('📄 Google login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store token, refresh token, and user data
        await _write(key: _tokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        await _write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Google login successful and tokens stored');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Google login failed with status ${response.statusCode}: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Google login failed');
        } catch (_) {
          throw Exception('Google login failed: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      print('💥 Google login exception: $e');
      throw Exception('Google login error: $e');
    }
  }
  
  /// Check if username is available
  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check username availability');
      }
    } catch (e) {
      print('💥 Username check exception: $e');
      throw Exception('Username check error: $e');
    }
  }
  
  /// Send OTP to email for verification
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      print('📧 Sending OTP to: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );
      
      print('📡 Send OTP response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ OTP sent successfully');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Send OTP failed: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Failed to send verification code');
        } catch (_) {
          throw Exception('Failed to send verification code');
        }
      }
    } catch (e) {
      print('💥 Send OTP exception: $e');
      rethrow;
    }
  }
  
  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP(String email, String otpCode) async {
    try {
      print('🔐 Verifying OTP for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp_code': otpCode,
        }),
      ).timeout(const Duration(seconds: 15));
      
      print('📡 Verify OTP response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ OTP verification result: ${data['success']}');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Verify OTP failed: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Verification failed');
        } catch (_) {
          throw Exception('Verification failed');
        }
      }
    } catch (e) {
      print('💥 Verify OTP exception: $e');
      rethrow;
    }
  }
  
  /// Register with OTP verification
  Future<Map<String, dynamic>> registerWithOTP({
    required String email,
    required String otpCode,
    required String password,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? bio,
  }) async {
    try {
      print('📝 Registering with OTP to: $baseUrl/auth/register-with-otp');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp_code': otpCode,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
          if (bio != null) 'bio': bio,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network connection.');
        },
      );
      
      print('📡 Register with OTP response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Store token, refresh token, and user data
        await _write(key: _tokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        await _write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Registration with OTP successful and tokens stored');
        return data;
      } else {
        final errorBody = response.body;
        print('❌ Register with OTP failed: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          throw Exception(error['detail'] ?? 'Registration failed');
        } catch (_) {
          throw Exception('Registration failed');
        }
      }
    } catch (e) {
      print('💥 Register with OTP exception: $e');
      rethrow;
    }
  }
  
  /// Refresh the current access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token available');
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _write(key: _tokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        print('✅ Access token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${response.statusCode}');
        // Refresh token might be expired/revoked - clear storage
        if (response.statusCode == 401) {
          await logout();
        }
        return false;
      }
    } catch (e) {
      print('💥 Token refresh error: $e');
      return false;
    }
  }
  
  /// Get authorization header (checks token expiration)
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      print('⚠️ No auth token found');
      return {};
    }
    
    // Check if token is expired
    if (isTokenExpired(token)) {
      print('⚠️ Token is expired, clearing stored token');
      await logout(); // Clear expired token
      return {};
    }
    
    print('🔑 Auth token retrieved: ${token.substring(0, 20)}...');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> updateStoredUser(Map<String, dynamic> updates) async {
    final current = await getUser() ?? {};
    final merged = {...current, ...updates};
    await _write(key: _userKey, value: jsonEncode(merged));
  }
}

