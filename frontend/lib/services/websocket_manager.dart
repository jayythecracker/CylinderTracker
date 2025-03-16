import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cylinder_management/models/filling_operation.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/inspection.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/services/websocket_service.dart';

typedef WebSocketEventCallback = void Function(dynamic data);

/// A class to manage WebSocket event listeners and handle parsing of specific event types
class WebSocketManager {
  // Event type constants
  static const String cylinderCreated = 'cylinder_created';
  static const String cylinderUpdated = 'cylinder_updated';
  static const String cylinderDeleted = 'cylinder_deleted';
  static const String cylinderStatusUpdated = 'cylinder_status_updated';
  
  static const String fillingStarted = 'filling_started';
  static const String fillingCompleted = 'filling_completed';
  
  static const String inspectionCompleted = 'inspection_completed';
  
  static const String saleCreated = 'sale_created';
  static const String saleStatusUpdated = 'sale_status_updated';
  
  final WebSocketService _webSocketService;
  final Map<String, List<WebSocketEventCallback>> _eventListeners = {};

  WebSocketManager(this._webSocketService) {
    _webSocketService.addMessageListener(_handleMessage);
  }

  // Connect to the WebSocket server
  void connect() {
    _webSocketService.connect();
  }
  
  // Disconnect from the WebSocket server
  void disconnect() {
    _webSocketService.disconnect();
  }
  
  // Check if connected to the WebSocket server
  bool get isConnected => _webSocketService.isConnected;

  /// Add a listener for a specific event type
  void on(String eventType, WebSocketEventCallback callback) {
    _eventListeners[eventType] ??= [];
    _eventListeners[eventType]!.add(callback);
  }

  /// Remove a listener for a specific event type
  void off(String eventType, WebSocketEventCallback callback) {
    if (_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType]!.remove(callback);
      if (_eventListeners[eventType]!.isEmpty) {
        _eventListeners.remove(eventType);
      }
    }
  }

  /// Handle incoming WebSocket messages and dispatch to the appropriate listeners
  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      final payload = data['data'];
      
      if (type != null && _eventListeners.containsKey(type)) {
        // Parse the payload based on the event type
        final parsedPayload = _parsePayload(type, payload);
        
        // Notify all listeners for this event type
        for (final callback in _eventListeners[type]!) {
          callback(parsedPayload);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling WebSocket message: $e');
      }
    }
  }

  /// Parse the payload based on the event type
  dynamic _parsePayload(String type, dynamic payload) {
    switch (type) {
      case cylinderCreated:
      case cylinderUpdated:
        return Cylinder.fromJson(payload);
        
      case cylinderDeleted:
      case cylinderStatusUpdated:
        // These events have simple payloads, no need to parse
        return payload;
        
      case fillingStarted:
      case fillingCompleted:
        return FillingOperation.fromJson(payload);
        
      case inspectionCompleted:
        return Inspection.fromJson(payload);
        
      case saleCreated:
        return Sale.fromJson(payload);
        
      case saleStatusUpdated:
        // This event has a simple payload, no need to parse
        return payload;
        
      default:
        // For unknown event types, return the raw payload
        return payload;
    }
  }
  
  /// Send a message to the WebSocket server
  void send(String type, dynamic data) {
    if (!_webSocketService.isConnected) {
      if (kDebugMode) {
        print('Cannot send message: WebSocket is not connected');
      }
      return;
    }
    
    final message = jsonEncode({
      'type': type,
      'data': data,
    });
    
    _webSocketService.send(message);
  }
  
  /// Clean up resources when the manager is no longer needed
  void dispose() {
    _webSocketService.removeMessageListener(_handleMessage);
    _eventListeners.clear();
  }
}