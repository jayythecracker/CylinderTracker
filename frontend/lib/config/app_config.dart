import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // API Configuration
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8000/api'; // Android emulator localhost
        } else {
          return 'http://localhost:8000/api';
        }
      } catch (e) {
        // Fallback to localhost for any other platform
        return 'http://localhost:8000/api';
      }
    }
  }

  // App Configuration
  static const String appName = 'Cylinder Management System';
  static const String appVersion = '1.0.0';
  
  // Design Configuration
  static Color primaryColor = const Color(0xFF2563EB); // Blue
  static Color accentColor = const Color(0xFFEF4444);  // Red
  static Color successColor = const Color(0xFF10B981); // Green
  static Color warningColor = const Color(0xFFF59E0B); // Amber
  static Color errorColor = const Color(0xFFEF4444);   // Red
  static Color lightGrey = const Color(0xFFF3F4F6);   
  static Color darkGrey = const Color(0xFF6B7280);
  
  // Text sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 24.0;
  
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingNormal = 16.0;
  static const double spacingMedium = 24.0;
  static const double spacingLarge = 32.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusNormal = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusFull = 100.0;
  
  // Animations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 350);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // App specific configurations
  static const int fillingLineCapacity = 10; // Minimum number of cylinders per filling line
  
  // Date formats
  static const String dateFormatShort = 'MM/dd/yyyy';
  static const String dateFormatLong = 'MMMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy - HH:mm';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  
  // Role-based access
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleFiller = 'filler';
  static const String roleSeller = 'seller';
  
  // Status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'empty':
        return lightGrey;
      case 'full':
        return successColor;
      case 'error':
        return errorColor;
      case 'inmaintenance':
        return warningColor;
      case 'intransit':
        return Colors.blue.shade300;
      case 'completed':
        return successColor;
      case 'failed':
        return errorColor;
      case 'inprogress':
        return Colors.blue.shade300;
      case 'approved':
        return successColor;
      case 'rejected':
        return errorColor;
      case 'delivered':
        return successColor;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return errorColor;
      case 'paid':
        return successColor;
      case 'partial':
        return warningColor;
      case 'available':
        return successColor;
      case 'outofservice':
        return errorColor;
      case 'maintenance':
        return warningColor;
      default:
        return darkGrey;
    }
  }
}
