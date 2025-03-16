import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

// API Service class to handle HTTP requests
class ApiService {
  late final Dio _dio;
  final StorageService _storageService;
  final String baseUrl = 'http://localhost:8000/api'; // Base URL for API requests

  ApiService(this._storageService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage
        final token = await _storageService.getToken();
        
        // If token exists, add it to request headers
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          _storageService.deleteToken();
        }
        
        return handler.next(error);
      },
    ));
  }

  // GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // POST request
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // PUT request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // PATCH request
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // DELETE request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Error handling
  void _handleError(DioException e) {
    String errorMessage = 'An error occurred';
    
    if (e.response != null) {
      // Server responded with an error
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else {
        errorMessage = 'Server error: ${e.response!.statusCode}';
      }
    } else if (e.type == DioExceptionType.connectionTimeout || 
               e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection. Please check your network.';
    }
    
    throw Exception(errorMessage);
  }
}

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(storageService);
});
