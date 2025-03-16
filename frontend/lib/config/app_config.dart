import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Configuration class for environment-specific app settings
class AppConfig {
  /// App version
  static const String appVersion = '1.0.0';

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

  /// App theme colors
  static final MaterialColor primaryColor = MaterialColor(
    0xFF1976D2, // Blue 700
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  static final Color accentColor = Colors.orange[800]!;
  static final Color errorColor = Colors.red[700]!;
  static final Color successColor = Colors.green[600]!;
  static final Color warningColor = Colors.amber[700]!;

  /// API endpoints
  static const String authEndpoint = '/api/auth';
  static const String factoriesEndpoint = '/api/factories';
  static const String cylindersEndpoint = '/api/cylinders';
  static const String customersEndpoint = '/api/customers';
  static const String fillingsEndpoint = '/api/fillings';
  static const String inspectionsEndpoint = '/api/inspections';
  static const String salesEndpoint = '/api/sales';
  static const String reportsEndpoint = '/api/reports';

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