import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_router.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences for storage
  final sharedPreferences = await SharedPreferences.getInstance();
  final storageService = StorageService(sharedPreferences);
  
  runApp(
    ProviderScope(
      overrides: [
        // Override the storage service provider with the initialized instance
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const CylinderManagementApp(),
    ),
  );
}

class CylinderManagementApp extends ConsumerWidget {
  const CylinderManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the auth state to handle auto login
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Cylinder Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2E5BFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5BFF),
          primary: const Color(0xFF2E5BFF),
          secondary: const Color(0xFFFF6B2E),
          background: Colors.white,
          error: const Color(0xFFFF3D71),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E5BFF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E5BFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E5BFF)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: authState is AuthStateAuthenticated 
          ? AppRouter.dashboardRoute 
          : AppRouter.loginRoute,
    );
  }
}
