import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cylinder_management/services/api_service.dart';
import 'package:cylinder_management/services/websocket_service.dart';
import 'package:cylinder_management/services/websocket_manager.dart';

/// A provider that makes all services available throughout the app
class ServicesProvider extends StatefulWidget {
  final Widget child;
  
  const ServicesProvider({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<ServicesProvider> createState() => _ServicesProviderState();
  
  /// Helper method to access the API service from anywhere in the widget tree
  static ApiService api(BuildContext context, {bool listen = false}) {
    return Provider.of<ApiService>(context, listen: listen);
  }
  
  /// Helper method to access the WebSocket service from anywhere
  static WebSocketService websocket(BuildContext context, {bool listen = false}) {
    return Provider.of<WebSocketService>(context, listen: listen);
  }
  
  /// Helper method to access the WebSocketManager from anywhere
  static WebSocketManager websocketManager(BuildContext context, {bool listen = false}) {
    return Provider.of<WebSocketManager>(context, listen: listen);
  }
}

class _ServicesProviderState extends State<ServicesProvider> {
  late ApiService _apiService;
  late WebSocketService _webSocketService;
  late WebSocketManager _webSocketManager;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _apiService = ApiService();
    _webSocketService = WebSocketService();
    _webSocketManager = WebSocketManager(_webSocketService);
    
    // Connect to WebSocket server when the app starts
    _webSocketManager.connect();
  }
  
  @override
  void dispose() {
    // Clean up resources
    _webSocketManager.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Provide all services to the widget tree
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: _apiService),
        ChangeNotifierProvider<WebSocketService>.value(value: _webSocketService),
        Provider<WebSocketManager>.value(value: _webSocketManager),
      ],
      child: widget.child,
    );
  }
}