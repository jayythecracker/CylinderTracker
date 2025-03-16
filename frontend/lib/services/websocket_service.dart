import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:cylinder_management/config/app_config.dart';

// Provider for the WebSocket service
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

// Event types for WebSocket messages
enum WebSocketEventType {
  cylinderCreated,
  cylinderUpdated,
  cylinderDeleted,
  cylinderStatusUpdated,
  fillingStarted,
  fillingCompleted,
  inspectionCompleted,
  saleCreated,
  saleStatusUpdated,
  custom,
  error,
  connection,
}

// WebSocket event class
class WebSocketEvent {
  final WebSocketEventType type;
  final dynamic data;

  WebSocketEvent({required this.type, this.data});

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    WebSocketEventType eventType;
    
    switch (json['type']) {
      case 'cylinder_created':
        eventType = WebSocketEventType.cylinderCreated;
        break;
      case 'cylinder_updated':
        eventType = WebSocketEventType.cylinderUpdated;
        break;
      case 'cylinder_deleted':
        eventType = WebSocketEventType.cylinderDeleted;
        break;
      case 'cylinder_status_updated':
        eventType = WebSocketEventType.cylinderStatusUpdated;
        break;
      case 'filling_started':
        eventType = WebSocketEventType.fillingStarted;
        break;
      case 'filling_completed':
        eventType = WebSocketEventType.fillingCompleted;
        break;
      case 'inspection_completed':
        eventType = WebSocketEventType.inspectionCompleted;
        break;
      case 'sale_created':
        eventType = WebSocketEventType.saleCreated;
        break;
      case 'sale_status_updated':
        eventType = WebSocketEventType.saleStatusUpdated;
        break;
      case 'connection':
        eventType = WebSocketEventType.connection;
        break;
      case 'error':
        eventType = WebSocketEventType.error;
        break;
      default:
        eventType = WebSocketEventType.custom;
    }

    return WebSocketEvent(
      type: eventType,
      data: json['data'] ?? json['message'],
    );
  }
}

// WebSocket service for real-time updates
class WebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  
  // Stream that emits WebSocket events to listeners
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  
  bool _isConnected = false;
  Timer? _reconnectTimer;
  final int _reconnectInterval = 5000; // 5 seconds
  
  // Constructor
  WebSocketService() {
    connect();
  }
  
  // Connect to the WebSocket server
  void connect() {
    if (_isConnected) return;
    
    try {
      final wsUrl = _getWebSocketUrl();
      
      if (kIsWeb) {
        _channel = HtmlWebSocketChannel.connect(wsUrl);
      } else {
        _channel = IOWebSocketChannel.connect(wsUrl);
      }
      
      _isConnected = true;
      _listen();
      
      // Cancel any pending reconnection attempts
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      
    } catch (e) {
      _isConnected = false;
      debugPrint('WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }
  
  // Listen for WebSocket messages
  void _listen() {
    _channel?.stream.listen(
      (dynamic message) {
        try {
          final Map<String, dynamic> jsonData = 
              message is String ? json.decode(message) : message;
          
          final event = WebSocketEvent.fromJson(jsonData);
          _eventController.add(event);
          
        } catch (e) {
          debugPrint('Error parsing WebSocket message: $e');
        }
      },
      onDone: () {
        _isConnected = false;
        debugPrint('WebSocket connection closed');
        _scheduleReconnect();
      },
      onError: (error) {
        _isConnected = false;
        debugPrint('WebSocket error: $error');
        _scheduleReconnect();
      },
    );
  }
  
  // Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectInterval), () {
      _reconnectTimer = null;
      connect();
    });
  }
  
  // Close the WebSocket connection
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  // Send a message to the WebSocket server
  void send(Map<String, dynamic> data) {
    if (!_isConnected) {
      connect();
    }
    
    try {
      _channel?.sink.add(json.encode(data));
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }
  
  // Construct the WebSocket URL based on the current environment
  String _getWebSocketUrl() {
    final baseUrl = AppConfig.apiBaseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss://' : 'ws://';
    
    // Remove http/https protocol
    final hostPart = baseUrl.replaceFirst(RegExp(r'https?://'), '');
    
    // Combine with WebSocket protocol and path
    return '$wsProtocol$hostPart/ws';
  }
  
  // Dispose of resources
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

// Helper provider for specific WebSocket event types
final websocketEventProvider = StreamProvider.family<dynamic, WebSocketEventType>(
  (ref, eventType) {
    final service = ref.watch(websocketServiceProvider);
    
    return service.eventStream
      .where((event) => event.type == eventType)
      .map((event) => event.data);
  }
);