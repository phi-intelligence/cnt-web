import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_service.dart';
import 'logger_service.dart';

/// Service for managing Stripe Connect accounts and onboarding
class StripeConnectService {
  final AuthService _authService = AuthService();
  
  static String get baseUrl {
    return ApiService.baseUrl;
  }
  
  /// Create a Stripe Connect Express account for the current user
  /// Returns the Stripe account ID, or null on failure
  Future<String?> createConnectAccount() async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/stripe-connect/create-account'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['stripe_account_id'] as String?;
      } else {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          LoggerService.e('Error creating Stripe Connect account: ${error['detail']}');
        } catch (_) {
          LoggerService.e('Error creating Stripe Connect account: ${response.statusCode} - $errorBody');
        }
        return null;
      }
    } catch (e) {
      LoggerService.e('Error creating Stripe Connect account: $e');
      return null;
    }
  }
  
  /// Create an onboarding link for Stripe Connect account
  /// Returns the onboarding URL, or null on failure
  Future<String?> createOnboardingLink() async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/stripe-connect/create-onboarding-link'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      } else {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          LoggerService.e('Error creating onboarding link: ${error['detail']}');
        } catch (_) {
          LoggerService.e('Error creating onboarding link: ${response.statusCode} - $errorBody');
        }
        return null;
      }
    } catch (e) {
      LoggerService.e('Error creating onboarding link: $e');
      return null;
    }
  }
  
  /// Get the Stripe Connect account status for the current user
  /// Returns a map with payouts_enabled, charges_enabled, details_submitted, account_exists
  /// or null on failure
  Future<Map<String, dynamic>?> getAccountStatus({int? userId}) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      String url = '$baseUrl/stripe-connect/account-status';
      if (userId != null) {
        url = '$baseUrl/stripe-connect/account-status/$userId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          LoggerService.e('Error getting account status: ${error['detail']}');
        } catch (_) {
          LoggerService.e('Error getting account status: ${response.statusCode} - $errorBody');
        }
        return null;
      }
    } catch (e) {
      LoggerService.e('Error getting account status: $e');
      return null;
    }
  }
  
  /// Get the Stripe Express dashboard login link for the current user
  /// Returns the dashboard URL, or null on failure
  Future<String?> getDashboardLink() async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/stripe-connect/dashboard-link'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      } else {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          LoggerService.e('Error getting dashboard link: ${error['detail']}');
        } catch (_) {
          LoggerService.e('Error getting dashboard link: ${response.statusCode} - $errorBody');
        }
        return null;
      }
    } catch (e) {
      LoggerService.e('Error getting dashboard link: $e');
      return null;
    }
  }
}

