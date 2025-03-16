import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cylinder_management/app.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load environment variables if needed
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Continue even if .env file is not found
    debugPrint("No .env file found. Using default or environment variables.");
  }

  // Run the app wrapped with ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: CylinderManagementApp(),
    ),
  );
}
