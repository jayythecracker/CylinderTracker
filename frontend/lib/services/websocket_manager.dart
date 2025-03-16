import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/filling_operation.dart';
import 'package:cylinder_management/models/inspection.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/services/websocket_service.dart';
import 'package:flutter/foundation.dart';

/// WebSocketManager is responsible for handling domain-specific WebSocket events
/// and translating them into application events
class WebSocketManager {
  final WebSocketService _webSocketService;
  
  // Event callbacks
  final Map<String, List<Function(dynamic)>> _eventCallbacks = {};

  // Common event types in the system
  static const String cylinderCreated = 'cylinder_created';
  static const String cylinderUpdated = 'cylinder_updated';
  static const String cylinderDeleted = 'cylinder_deleted';
  static const String cylinderStatusUpdated = 'cylinder_status_updated';
  static const String fillingStarted = 'filling_started';
  static const String fillingCompleted = 'filling_completed';
  static const String inspectionCompleted = 'inspection_completed';
  static const String saleCreated = 'sale_created';
  static const String saleStatusUpdated = 'sale_status_updated';
  
  WebSocketManager(this._webSocketService) {
    _setupEventHandlers();
  }
  
  /// Connect to the WebSocket server
  void connect() {
    _webSocketService.connect();
  }
  
  /// Register event handlers for specific WebSocket events
  void _setupEventHandlers() {
    // Cylinder events
    _webSocketService.on(cylinderCreated, _handleCylinderCreated);
    _webSocketService.on(cylinderUpdated, _handleCylinderUpdated);
    _webSocketService.on(cylinderDeleted, _handleCylinderDeleted);
    _webSocketService.on(cylinderStatusUpdated, _handleCylinderStatusUpdated);
    
    // Filling operation events
    _webSocketService.on(fillingStarted, _handleFillingStarted);
    _webSocketService.on(fillingCompleted, _handleFillingCompleted);
    
    // Inspection events
    _webSocketService.on(inspectionCompleted, _handleInspectionCompleted);
    
    // Sale events
    _webSocketService.on(saleCreated, _handleSaleCreated);
    _webSocketService.on(saleStatusUpdated, _handleSaleStatusUpdated);
  }
  
  /// Register a callback for a specific event type
  void on(String eventType, Function(dynamic) callback) {
    if (!_eventCallbacks.containsKey(eventType)) {
      _eventCallbacks[eventType] = [];
    }
    _eventCallbacks[eventType]!.add(callback);
  }
  
  /// Unregister a callback for a specific event type
  void off(String eventType, Function(dynamic) callback) {
    if (_eventCallbacks.containsKey(eventType)) {
      _eventCallbacks[eventType]!.remove(callback);
    }
  }
  
  /// Trigger event callbacks for a specific event type
  void _trigger(String eventType, dynamic data) {
    if (_eventCallbacks.containsKey(eventType)) {
      for (final callback in _eventCallbacks[eventType]!) {
        callback(data);
      }
    }
  }
  
  // Event handler methods
  
  void _handleCylinderCreated(dynamic data) {
    try {
      final cylinder = Cylinder.fromJson(data);
      _trigger(cylinderCreated, cylinder);
      if (kDebugMode) {
        print('Cylinder created: ${cylinder.serialNumber}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling cylinder_created event: $e');
      }
    }
  }
  
  void _handleCylinderUpdated(dynamic data) {
    try {
      final cylinder = Cylinder.fromJson(data);
      _trigger(cylinderUpdated, cylinder);
      if (kDebugMode) {
        print('Cylinder updated: ${cylinder.serialNumber}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling cylinder_updated event: $e');
      }
    }
  }
  
  void _handleCylinderDeleted(dynamic data) {
    try {
      final cylinderId = data['id'];
      _trigger(cylinderDeleted, cylinderId);
      if (kDebugMode) {
        print('Cylinder deleted: $cylinderId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling cylinder_deleted event: $e');
      }
    }
  }
  
  void _handleCylinderStatusUpdated(dynamic data) {
    try {
      final cylinderId = data['id'];
      final status = data['status'];
      final notes = data['notes'];
      
      _trigger(cylinderStatusUpdated, {
        'id': cylinderId,
        'status': status,
        'notes': notes,
      });
      
      if (kDebugMode) {
        print('Cylinder status updated: Cylinder #$cylinderId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling cylinder_status_updated event: $e');
      }
    }
  }
  
  void _handleFillingStarted(dynamic data) {
    try {
      final filling = FillingOperation.fromJson(data);
      _trigger(fillingStarted, filling);
      if (kDebugMode) {
        print('Filling started: Cylinder #${filling.cylinderId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling filling_started event: $e');
      }
    }
  }
  
  void _handleFillingCompleted(dynamic data) {
    try {
      final filling = FillingOperation.fromJson(data);
      _trigger(fillingCompleted, filling);
      if (kDebugMode) {
        print('Filling completed: Cylinder #${filling.cylinderId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling filling_completed event: $e');
      }
    }
  }
  
  void _handleInspectionCompleted(dynamic data) {
    try {
      final inspection = Inspection.fromJson(data);
      _trigger(inspectionCompleted, inspection);
      if (kDebugMode) {
        print('Inspection completed: Cylinder #${inspection.cylinderId}, Result: ${inspection.result}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling inspection_completed event: $e');
      }
    }
  }
  
  void _handleSaleCreated(dynamic data) {
    try {
      final sale = Sale.fromJson(data);
      _trigger(saleCreated, sale);
      if (kDebugMode) {
        print('Sale created: #${sale.id}, Customer: ${sale.customerId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling sale_created event: $e');
      }
    }
  }
  
  void _handleSaleStatusUpdated(dynamic data) {
    try {
      final saleId = data['id'];
      final status = data['status'];
      final notes = data['notes'];
      
      _trigger(saleStatusUpdated, {
        'id': saleId,
        'status': status,
        'notes': notes,
      });
      
      if (kDebugMode) {
        print('Sale status updated: Sale #$saleId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling sale_status_updated event: $e');
      }
    }
  }
  
  /// Disconnect from the WebSocket server
  void disconnect() {
    _webSocketService.disconnect();
  }
  
  /// Reconnect to the WebSocket server
  void reconnect() {
    _webSocketService.reconnect();
  }
  
  /// Get connection status
  bool get isConnected => _webSocketService.isConnected;
  
  /// Get error message
  String? get errorMessage => _webSocketService.errorMessage;
}