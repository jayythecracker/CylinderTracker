import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  final http.Client _client;
  
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  
  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }
  
  // Common headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }
  
  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: error['message'] ?? 'Unknown error occurred',
      );
    }
  }
  
  // GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final headers = await _getHeaders();
    
    String url = endpoint;
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url = '$endpoint?$queryString';
    }
    
    final response = await _client.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }
  
  // POST request
  Future<dynamic> post(String endpoint, {required Map<String, dynamic> data}) async {
    final headers = await _getHeaders();
    final response = await _client.post(
      Uri.parse(endpoint),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // PUT request
  Future<dynamic> put(String endpoint, {required Map<String, dynamic> data}) async {
    final headers = await _getHeaders();
    final response = await _client.put(
      Uri.parse(endpoint),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }
  
  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await _client.delete(
      Uri.parse(endpoint),
      headers: headers,
    );
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({required this.statusCode, required this.message});
  
  @override
  String toString() => 'ApiException: $statusCode - $message';
}
