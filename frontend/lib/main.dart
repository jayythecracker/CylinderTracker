import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app with ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: CylinderManagementApp(),
    ),
  );
}
