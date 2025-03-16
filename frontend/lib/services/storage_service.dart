import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Storage Service for local storage
class StorageService {
  final SharedPreferences _prefs;
  
  // Keys for storage
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  StorageService(this._prefs);

  // Save auth token
  Future<void> saveToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  // Delete auth token
  Future<void> deleteToken() async {
    await _prefs.remove(tokenKey);
    await _prefs.remove(userKey);
  }

  // Save string data
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  // Get string data
  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Save int data
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  // Get int data
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Save bool data
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  // Get bool data
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Remove data by key
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // Clear all data
  Future<void> clear() async {
    await _prefs.clear();
  }
}

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'StorageService must be initialized and overridden in main.dart',
  );
});
