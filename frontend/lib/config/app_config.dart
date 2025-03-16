import 'package:flutter/foundation.dart';

/// Configuration class for environment-specific app settings
class AppConfig {
  /// The base URL for the API without trailing slash
  static String get apiBaseUrl {
    // In production, this would be loaded from environment variables
    // or a configuration file, based on the build environment
    if (kReleaseMode) {
      return 'https://api.cylindermanagement.com';
    } else if (kIsWeb) {
      // When running in web mode (dev or test), use the current origin
      // This allows the app to work seamlessly with the development server
      return '';  // Empty string means it will use relative URLs (same origin)
    } else {
      // For mobile development
      return 'http://10.0.2.2:5000';  // Android emulator loopback to host
    }
  }
  
  /// The base URL for WebSocket connections
  static String get wsBaseUrl {
    if (kReleaseMode) {
      return 'wss://api.cylindermanagement.com/ws';
    } else if (kIsWeb) {
      final protocol = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$protocol://${Uri.base.host}:${Uri.base.port}/ws';
    } else {
      return 'ws://10.0.2.2:5000/ws';  // Android emulator loopback to host
    }
  }

  /// Default pagination limit for API requests
  static const int defaultPaginationLimit = 20;

  /// Timeout duration for API requests in seconds
  static const int apiTimeoutSeconds = 15;

  /// Maximum number of retry attempts for API requests
  static const int maxApiRetries = 3;

  /// Interval for WebSocket reconnection attempts in milliseconds
  static const int wsReconnectInterval = 5000;

  /// Maximum number of real-time events to show in the UI
  static const int maxRecentEvents = 50;

  /// Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableQrCodeScanning = true;
  static const bool enablePushNotifications = false;
  static const bool enableAnalytics = false;
}