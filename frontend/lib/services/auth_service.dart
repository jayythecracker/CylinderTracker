import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  
  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  // Login user
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final token = response['token'];
      final user = User.fromJson(response['user']);
      
      // Save token and user to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, token);
      await prefs.setString(AppConfig.userKey, json.encode(user.toJson()));
      
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get current user from shared preferences
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.userKey);
      
      if (userJson == null) return null;
      
      return User.fromJson(json.decode(userJson));
    } catch (e) {
      return null;
    }
  }
  
  // Get user profile from API
  Future<User> getUserProfile() async {
    try {
      final response = await _apiService.get(AppConfig.profileEndpoint);
      final user = User.fromJson(response['user']);
      
      // Update user in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userKey, json.encode(user.toJson()));
      
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user profile
  Future<User> updateProfile(String name, String? contactNumber, String? address) async {
    try {
      final response = await _apiService.put(
        AppConfig.profileEndpoint,
        data: {
          'name': name,
          'contactNumber': contactNumber,
          'address': address,
        },
      );
      
      final user = User.fromJson(response['user']);
      
      // Update user in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userKey, json.encode(user.toJson()));
      
      return user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiService.put(
        AppConfig.changePasswordEndpoint,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.tokenKey);
      await prefs.remove(AppConfig.userKey);
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      return token != null;
    } catch (e) {
      return false;
    }
  }
}
