// lib/services/api_proxy.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiProxy {
  // Your Railway backend URL
  static const String baseUrl = 'https://yourapp-production.up.railway.app';
  
  // Replace with your actual Railway URL
  // You'll find it in Railway dashboard after deployment
  
  // Generic method to call through proxy
  static Future<dynamic> proxyCall({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/proxy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'endpoint': endpoint,
          'method': method,
          'data': data,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Proxy call failed: ${response.statusCode}');
      }
    } catch (e) {
      print('API Proxy Error: $e');
      rethrow;
    }
  }
  
  // Specific API methods (examples)
  static Future<Map<String, dynamic>> getWeather(String city) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/weather'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'city': city}),
    );
    
    return jsonDecode(response.body);
  }
  
  // Example: Process payment
  static Future<Map<String, dynamic>> processPayment(
    double amount, String token) async {
    
    final result = await proxyCall(
      endpoint: 'https://api.stripe.com/v1/charges',
      method: 'POST',
      data: {
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': 'usd',
        'source': token,
      },
    );
    
    return result;
  }
}