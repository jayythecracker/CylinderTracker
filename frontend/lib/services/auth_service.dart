import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/user.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Login user
  Future<User?> login(String email, String password) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success']) {
          // Save token and user data
          await _storage.write(
            key: AppConfig.tokenKey,
            value: jsonData['data']['token'],
          );
          
          await _storage.write(
            key: AppConfig.userKey,
            value: json.encode(jsonData['data']['user']),
          );
          
          // Return user
          return User.fromJson(jsonData['data']['user']);
        } else {
          throw Exception(jsonData['message'] ?? 'Login failed');
        }
      } else {
        // Attempt to parse error message
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Login failed: ${response.statusCode}');
        } catch (e) {
          throw Exception('Login failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
  
  // Get the current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      // Check if token exists
      final token = await getToken();
      if (token == null) {
        return null;
      }
      
      // Try to get user from secure storage first
      final userData = await _storage.read(key: AppConfig.userKey);
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      
      // If user data doesn't exist, fetch from API
      final url = Uri.parse('${AppConfig.baseUrl}/auth/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success']) {
          // Save user data
          await _storage.write(
            key: AppConfig.userKey,
            value: json.encode(jsonData['data']['user']),
          );
          
          // Return user
          return User.fromJson(jsonData['data']['user']);
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.tokenKey);
  }
  
  // Logout user
  Future<void> logout() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }
  
  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final url = Uri.parse('${AppConfig.baseUrl}/auth/update-password');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else {
        // Attempt to parse error message
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Password update failed: ${response.statusCode}');
        } catch (e) {
          throw Exception('Password update failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Password update error: $e');
    }
  }
  
  // Register user (admin only)
  Future<User?> registerUser(Map<String, dynamic> userData) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      final url = Uri.parse('${AppConfig.baseUrl}/auth/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );
      
      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success']) {
          // Return user
          return User.fromJson(jsonData['data']['user']);
        } else {
          throw Exception(jsonData['message'] ?? 'Registration failed');
        }
      } else {
        // Attempt to parse error message
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Registration failed: ${response.statusCode}');
        } catch (e) {
          throw Exception('Registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }
}
