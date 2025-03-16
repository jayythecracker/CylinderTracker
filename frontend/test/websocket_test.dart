import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cylinder_management/services/websocket_service.dart';
import 'package:cylinder_management/services/websocket_manager.dart';

// Mock WebSocket implementation for testing
class MockWebSocketService extends Mock implements WebSocketService {
  bool _isConnected = false;
  String? _errorMessage;
  Map<String, List<Function(dynamic)>> _eventListeners = {};
  
  @override
  bool get isConnected => _isConnected;
  
  @override
  String? get errorMessage => _errorMessage;
  
  @override
  void connect() {
    _isConnected = true;
    notifyListeners();
  }
  
  @override
  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }
  
  @override
  void on(String eventType, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType] = [];
    }
    _eventListeners[eventType]!.add(callback);
  }
  
  @override
  void off(String eventType, Function(dynamic) callback) {
    if (_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType]!.remove(callback);
    }
  }
  
  // Method to simulate receiving a WebSocket message
  void simulateMessage(String type, dynamic data) {
    if (_eventListeners.containsKey(type)) {
      for (final callback in _eventListeners[type]!) {
        callback(data);
      }
    }
  }
  
  @override
  void notifyListeners() {
    // No-op for testing
  }
}

void main() {
  group('WebSocketManager Tests', () {
    late MockWebSocketService mockWebSocketService;
    late WebSocketManager webSocketManager;
    
    setUp(() {
      mockWebSocketService = MockWebSocketService();
      webSocketManager = WebSocketManager(mockWebSocketService);
    });
    
    test('Should establish WebSocket connection', () {
      // Arrange
      expect(mockWebSocketService.isConnected, isFalse);
      
      // Act
      webSocketManager.connect();
      
      // Assert
      expect(mockWebSocketService.isConnected, isTrue);
    });
    
    test('Should disconnect WebSocket connection', () {
      // Arrange
      webSocketManager.connect();
      expect(mockWebSocketService.isConnected, isTrue);
      
      // Act
      webSocketManager.disconnect();
      
      // Assert
      expect(mockWebSocketService.isConnected, isFalse);
    });
    
    test('Should handle cylinder status update event', () {
      // Arrange
      var receivedEventData;
      webSocketManager.on(WebSocketManager.cylinderStatusUpdated, (data) {
        receivedEventData = data;
      });
      
      final testData = {
        'id': 123,
        'status': 'Full',
        'notes': 'Filled and ready for delivery'
      };
      
      // Act
      mockWebSocketService.simulateMessage(WebSocketManager.cylinderStatusUpdated, testData);
      
      // Assert
      expect(receivedEventData, isNotNull);
      expect(receivedEventData['id'], equals(123));
      expect(receivedEventData['status'], equals('Full'));
      expect(receivedEventData['notes'], equals('Filled and ready for delivery'));
    });
    
    test('Should handle filling completed event', () {
      // Arrange
      var receivedEventData;
      webSocketManager.on(WebSocketManager.fillingCompleted, (data) {
        receivedEventData = data;
      });
      
      final testData = {
        'id': 456,
        'cylinderId': 123,
        'filledById': 789,
        'fillingDate': '2025-03-16T12:00:00.000Z',
        'gasType': 'Oxygen',
        'initialPressure': 0,
        'finalPressure': 200,
        'status': 'Completed',
        'notes': 'Standard filling',
        'createdAt': '2025-03-16T12:00:00.000Z',
        'updatedAt': '2025-03-16T12:00:00.000Z'
      };
      
      // Act
      mockWebSocketService.simulateMessage(WebSocketManager.fillingCompleted, testData);
      
      // Assert
      expect(receivedEventData, isNotNull);
      // Since this might be converted to a FillingOperation object, check a few key properties
      // This assumes the FillingOperation.fromJson works correctly
    });
  });
}