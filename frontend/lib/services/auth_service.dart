import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/platform_helper.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
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
        
        // Store token and user data
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Token and user data stored successfully');
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
    return await _storage.read(key: _tokenKey);
  }
  
  /// Get stored user data
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Check if user is admin
  Future<bool> isAdmin() async {
    final user = await getUser();
    return user?['is_admin'] == true;
  }
  
  /// Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
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
        
        // Store token and user data
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Registration successful and token stored');
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
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      print('🔐 Attempting Google login to: $baseUrl/auth/google-login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
        }),
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
        
        // Store token and user data
        await _storage.write(key: _tokenKey, value: data['access_token']);
        await _storage.write(key: _userKey, value: jsonEncode({
          'id': data['user_id'],
          'username': data['username'],
          'email': data['email'],
          'name': data['name'],
          'is_admin': data['is_admin'],
        }));
        
        print('✅ Google login successful and token stored');
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
  
  /// Get authorization header
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      print('🔑 Auth token retrieved: ${token.substring(0, 20)}...');
      return {'Authorization': 'Bearer $token'};
    }
    print('⚠️ No auth token found');
    return {};
  }

  Future<void> updateStoredUser(Map<String, dynamic> updates) async {
    final current = await getUser() ?? {};
    final merged = {...current, ...updates};
    await _storage.write(key: _userKey, value: jsonEncode(merged));
  }
}

