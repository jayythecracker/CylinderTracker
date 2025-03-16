import '../models/user.dart';
import 'storage_service.dart';
import 'package:dio/dio.dart';

class LoginResult {
  final User user;
  final String token;

  LoginResult({required this.user, required this.token});
}

// Auth Service for handling authentication
class AuthService {
  final StorageService _storageService;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  AuthService(this._storageService);

  // Login user
  Future<LoginResult> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      final user = User.fromJson(response.data['user']);

      // Save token to storage
      await _storageService.saveToken(token);

      return LoginResult(user: user, token: token);
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      
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

  // Get current user
  Future<User> getCurrentUser() async {
    try {
      final token = await _storageService.getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      String errorMessage = 'Failed to get user data';
      
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          // Token expired or invalid
          await _storageService.deleteToken();
          throw Exception('Session expired. Please login again.');
        }
        
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        }
      }
      
      throw Exception(errorMessage);
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await _storageService.getToken();
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      await _dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      String errorMessage = 'Failed to change password';
      
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        }
      }
      
      throw Exception(errorMessage);
    }
  }

  // Logout user
  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  // Get token from storage
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }
}
