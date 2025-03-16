import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/services/auth_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({required this.success, this.data, this.message, this.error});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'],
      error: json['error'],
    );
  }
}

class ApiService {
  final AuthService _authService = AuthService();
  
  // Create headers with authorization token if available
  Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    String? token = await _authService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Handle API response and errors
  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(responseBody);
      
      // Check if the response has a success field
      if (jsonData.containsKey('success')) {
        if (jsonData['success']) {
          // Successful response
          return ApiResponse.fromJson(jsonData, fromJson);
        } else {
          // API returned an error
          return ApiResponse(
            success: false,
            message: jsonData['message'] ?? 'Unknown error',
            error: jsonData['error'],
          );
        }
      } else {
        // Unexpected response format
        return ApiResponse(
          success: false,
          message: 'Unexpected response format',
          error: responseBody,
        );
      }
    } catch (e) {
      // Failed to parse response
      return ApiResponse(
        success: false,
        message: 'Failed to parse response',
        error: e.toString(),
      );
    }
  }

  // Handle API error based on status code
  ApiResponse<T> _handleError<T>(http.Response response) {
    String message;
    
    switch (response.statusCode) {
      case 400:
        message = 'Bad request';
        break;
      case 401:
        message = 'Unauthorized. Please login again.';
        // Force logout if unauthorized
        _authService.logout();
        break;
      case 403:
        message = 'Forbidden. You do not have permission to access this resource.';
        break;
      case 404:
        message = 'Resource not found';
        break;
      case 500:
        message = 'Internal server error';
        break;
      default:
        message = 'An error occurred: ${response.statusCode}';
    }

    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final jsonData = json.decode(responseBody);
      if (jsonData.containsKey('message')) {
        message = jsonData['message'];
      }
    } catch (_) {
      // Ignore parsing errors for error responses
    }

    return ApiResponse(
      success: false,
      message: message,
      error: 'Error ${response.statusCode}',
    );
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Build URL with query parameters
      Uri url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }
      
      // Get headers with auth token
      final headers = await _getHeaders();
      
      // Log request in debug mode
      if (kDebugMode) {
        print('GET $url');
        print('Headers: $headers');
      }
      
      // Make request
      final response = await http.get(url, headers: headers);
      
      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      // Handle network or other errors
      return ApiResponse(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();
      
      // Log request in debug mode
      if (kDebugMode) {
        print('POST $url');
        print('Headers: $headers');
        print('Body: $body');
      }
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();
      
      // Log request in debug mode
      if (kDebugMode) {
        print('PUT $url');
        print('Headers: $headers');
        print('Body: $body');
      }
      
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();
      
      // Log request in debug mode
      if (kDebugMode) {
        print('PATCH $url');
        print('Headers: $headers');
        print('Body: $body');
      }
      
      final response = await http.patch(
        url,
        headers: headers,
        body: json.encode(body),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final headers = await _getHeaders();
      
      // Log request in debug mode
      if (kDebugMode) {
        print('DELETE $url');
        print('Headers: $headers');
      }
      
      final response = await http.delete(
        url,
        headers: headers,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
