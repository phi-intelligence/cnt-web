import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/platform_helper.dart';
import 'auth_service.dart';

class DonationService {
  final AuthService _authService = AuthService();
  
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return PlatformHelper.getApiBaseUrl();
  }
  
  /// Process a donation
  Future<Map<String, dynamic>> processDonation({
    required int recipientUserId,
    required double amount,
    String currency = 'USD',
    required String paymentMethod, // 'stripe' or 'paypal'
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/donations'),
        headers: headers,
        body: jsonEncode({
          'recipient_user_id': recipientUserId,
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = response.body;
        try {
          final error = json.decode(errorBody);
          throw Exception(error['detail'] ?? 'Donation failed');
        } catch (_) {
          throw Exception('Donation failed: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      throw Exception('Donation error: $e');
    }
  }
}

