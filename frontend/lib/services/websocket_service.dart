import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import platform-specific implementation
import 'package:cylinder_management/services/websocket/websocket_impl.dart'
    if (dart.library.html) 'package:cylinder_management/services/websocket/websocket_web.dart'
    if (dart.library.io) 'package:cylinder_management/services/websocket/websocket_io.dart';

typedef MessageCallback = void Function(String message);

/// A service that handles the WebSocket connection to the server.
class WebSocketService extends ChangeNotifier {
  final String _baseUrl;
  final Duration _reconnectInterval;
  final int _maxReconnectAttempts;
  
  IWebSocket? _webSocket;
  bool _isConnected = false;
  String? _errorMessage;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  final List<MessageCallback> _messageListeners = [];
  final List<String> _messageQueue = [];

  WebSocketService({
    required String baseUrl,
    Duration reconnectInterval = const Duration(seconds: 5),
    int maxReconnectAttempts = 10,
  })  : _baseUrl = baseUrl,
        _reconnectInterval = reconnectInterval,
        _maxReconnectAttempts = maxReconnectAttempts;

  /// Connect to the WebSocket server
  void connect() {
    if (_webSocket != null && _isConnected) {
      if (kDebugMode) {
        print('WebSocket already connected');
      }
      return;
    }
    
    try {
      if (kDebugMode) {
        print('Connecting to WebSocket server at $_baseUrl');
      }
      
      _webSocket = createWebSocket(_baseUrl);
      _webSocket!.onOpen = _onOpen;
      _webSocket!.onMessage = _onMessage;
      _webSocket!.onClose = _onClose;
      _webSocket!.onError = _onError;
      _webSocket!.connect();
    } catch (e) {
      _errorMessage = 'Failed to connect to WebSocket server: $e';
      if (kDebugMode) {
        print(_errorMessage);
      }
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _cancelReconnect();
    if (_webSocket != null) {
      _webSocket!.close();
      _webSocket = null;
    }
    _setConnectionState(false);
  }

  /// Add a message listener
  void addMessageListener(MessageCallback callback) {
    _messageListeners.add(callback);
  }

  /// Remove a message listener
  void removeMessageListener(MessageCallback callback) {
    _messageListeners.remove(callback);
  }

  /// Send a message to the server
  void send(String message) {
    if (_isConnected && _webSocket != null) {
      _webSocket!.send(message);
    } else {
      // Queue the message to be sent when connection is established
      _messageQueue.add(message);
    }
  }

  /// Get the current connection state
  bool get isConnected => _isConnected;

  /// Get the current error message (if any)
  String? get errorMessage => _errorMessage;

  void _onOpen() {
    _setConnectionState(true);
    _errorMessage = null;
    _reconnectAttempts = 0;
    
    // Send any queued messages
    if (_messageQueue.isNotEmpty) {
      for (final message in _messageQueue) {
        _webSocket!.send(message);
      }
      _messageQueue.clear();
    }
    
    if (kDebugMode) {
      print('WebSocket connection established');
    }
  }

  void _onMessage(String message) {
    for (final listener in _messageListeners) {
      listener(message);
    }
  }

  void _onClose() {
    _setConnectionState(false);
    if (kDebugMode) {
      print('WebSocket connection closed');
    }
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    _errorMessage = 'WebSocket error: $error';
    if (kDebugMode) {
      print(_errorMessage);
    }
    // We don't change connection state here as the onClose callback will be called
  }

  void _setConnectionState(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  void _scheduleReconnect() {
    _cancelReconnect();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      if (kDebugMode) {
        print('Scheduling reconnect attempt $_reconnectAttempts of $_maxReconnectAttempts in ${_reconnectInterval.inSeconds} seconds');
      }
      
      _reconnectTimer = Timer(_reconnectInterval, () {
        if (kDebugMode) {
          print('Attempting to reconnect...');
        }
        connect();
      });
    } else {
      _errorMessage = 'Failed to connect after $_maxReconnectAttempts attempts';
      if (kDebugMode) {
        print(_errorMessage);
      }
    }
  }

  void _cancelReconnect() {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageListeners.clear();
    super.dispose();
  }
}