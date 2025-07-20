// core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl =
      'http://your-api-url.com/api'; // Replace with your actual API URL

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await StorageService.getToken();
    return {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> handleResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        ...data,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'An error occurred',
        'statusCode': response.statusCode,
      };
    }
  }
}
