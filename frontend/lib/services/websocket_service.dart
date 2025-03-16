import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A service to handle WebSocket connections and events for real-time updates
class WebSocketService with ChangeNotifier {
  WebSocket? _socket;
  bool _isConnected = false;
  String? _errorMessage;
  
  // Event listeners map to store callbacks for different event types
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  
  // Getter for connection status
  bool get isConnected => _isConnected;
  
  // Getter for error message
  String? get errorMessage => _errorMessage;
  
  /// Connect to the WebSocket server
  void connect() {
    try {
      final protocol = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      final wsUrl = '$protocol://${Uri.base.host}:${Uri.base.port}/ws';
      
      // Close existing connection if any
      _socket?.close();
      
      _socket = WebSocket(wsUrl);
      _socket!.onOpen.listen((_) {
        _isConnected = true;
        _errorMessage = null;
        notifyListeners();
        if (kDebugMode) {
          print('WebSocket connected');
        }
      });
      
      _socket!.onMessage.listen((event) {
        try {
          final data = jsonDecode(event.data);
          final type = data['type'] as String;
          final payload = data['data'];
          
          // Notify all listeners for this event type
          _notifyListeners(type, payload);
          
          if (kDebugMode) {
            print('WebSocket received: $type - $payload');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing WebSocket message: $e');
          }
        }
      });
      
      _socket!.onClose.listen((event) {
        _isConnected = false;
        notifyListeners();
        if (kDebugMode) {
          print('WebSocket closed: ${event.code} - ${event.reason}');
        }
      });
      
      _socket!.onError.listen((error) {
        _isConnected = false;
        _errorMessage = error.toString();
        notifyListeners();
        if (kDebugMode) {
          print('WebSocket error: $error');
        }
      });
    } catch (e) {
      _isConnected = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) {
        print('Error connecting to WebSocket: $e');
      }
    }
  }
  
  /// Send a message to the WebSocket server
  void send(String type, dynamic data) {
    if (_isConnected && _socket != null) {
      final message = jsonEncode({
        'type': type,
        'data': data,
      });
      _socket!.send(message);
      if (kDebugMode) {
        print('WebSocket sent: $message');
      }
    } else {
      if (kDebugMode) {
        print('Cannot send message, WebSocket not connected');
      }
    }
  }
  
  /// Register a listener for a specific event type
  void on(String eventType, Function(dynamic) callback) {
    if (!_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType] = [];
    }
    _eventListeners[eventType]!.add(callback);
  }
  
  /// Remove a listener for a specific event type
  void off(String eventType, Function(dynamic) callback) {
    if (_eventListeners.containsKey(eventType)) {
      _eventListeners[eventType]!.remove(callback);
    }
  }
  
  /// Notify all listeners for a specific event type
  void _notifyListeners(String eventType, dynamic data) {
    if (_eventListeners.containsKey(eventType)) {
      for (final callback in _eventListeners[eventType]!) {
        callback(data);
      }
    }
  }
  
  /// Disconnect from the WebSocket server
  void disconnect() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }
  
  /// Reconnect to the WebSocket server
  void reconnect() {
    disconnect();
    connect();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Basic WebSocket client implementation
class WebSocket {
  final String url;
  WebSocketImpl _ws;
  
  WebSocket(this.url) : _ws = kIsWeb ? WebSocketWeb(url) : WebSocketIO(url);
  
  Stream<WebSocketOpenEvent> get onOpen => _ws.onOpen;
  Stream<WebSocketMessageEvent> get onMessage => _ws.onMessage;
  Stream<WebSocketCloseEvent> get onClose => _ws.onClose;
  Stream<WebSocketErrorEvent> get onError => _ws.onError;
  
  void send(String data) => _ws.send(data);
  void close([int? code, String? reason]) => _ws.close(code, reason);
}

/// Events for WebSocket
class WebSocketOpenEvent {}

class WebSocketMessageEvent {
  final dynamic data;
  WebSocketMessageEvent(this.data);
}

class WebSocketCloseEvent {
  final int? code;
  final String? reason;
  WebSocketCloseEvent(this.code, this.reason);
}

class WebSocketErrorEvent {
  final dynamic error;
  WebSocketErrorEvent(this.error);
  
  @override
  String toString() => error.toString();
}

/// Interface for WebSocket implementation
abstract class WebSocketImpl {
  Stream<WebSocketOpenEvent> get onOpen;
  Stream<WebSocketMessageEvent> get onMessage;
  Stream<WebSocketCloseEvent> get onClose;
  Stream<WebSocketErrorEvent> get onError;
  
  void send(String data);
  void close([int? code, String? reason]);
}

/// Web-specific WebSocket implementation
class WebSocketWeb implements WebSocketImpl {
  final String url;
  dynamic _webSocket;
  
  final _onOpenController = StreamController<WebSocketOpenEvent>.broadcast();
  final _onMessageController = StreamController<WebSocketMessageEvent>.broadcast();
  final _onCloseController = StreamController<WebSocketCloseEvent>.broadcast();
  final _onErrorController = StreamController<WebSocketErrorEvent>.broadcast();
  
  WebSocketWeb(this.url) {
    if (kIsWeb) {
      try {
        // Import dart:html in web mode
        // ignore: undefined_function
        _webSocket = WebSocketHtml(url);
        
        // Set up event listeners
        _webSocket.onOpen.listen((_) {
          _onOpenController.add(WebSocketOpenEvent());
        });
        
        _webSocket.onMessage.listen((event) {
          _onMessageController.add(WebSocketMessageEvent(event.data));
        });
        
        _webSocket.onClose.listen((event) {
          _onCloseController.add(WebSocketCloseEvent(event.code, event.reason));
        });
        
        _webSocket.onError.listen((event) {
          _onErrorController.add(WebSocketErrorEvent(event));
        });
      } catch (e) {
        _onErrorController.add(WebSocketErrorEvent(e));
      }
    }
  }
  
  @override
  Stream<WebSocketOpenEvent> get onOpen => _onOpenController.stream;
  
  @override
  Stream<WebSocketMessageEvent> get onMessage => _onMessageController.stream;
  
  @override
  Stream<WebSocketCloseEvent> get onClose => _onCloseController.stream;
  
  @override
  Stream<WebSocketErrorEvent> get onError => _onErrorController.stream;
  
  @override
  void send(String data) {
    if (_webSocket != null) {
      _webSocket.send(data);
    }
  }
  
  @override
  void close([int? code, String? reason]) {
    if (_webSocket != null) {
      _webSocket.close(code, reason);
    }
    
    _onOpenController.close();
    _onMessageController.close();
    _onCloseController.close();
    _onErrorController.close();
  }
}

/// IO-specific WebSocket implementation
class WebSocketIO implements WebSocketImpl {
  final String url;
  dynamic _webSocket;
  
  final _onOpenController = StreamController<WebSocketOpenEvent>.broadcast();
  final _onMessageController = StreamController<WebSocketMessageEvent>.broadcast();
  final _onCloseController = StreamController<WebSocketCloseEvent>.broadcast();
  final _onErrorController = StreamController<WebSocketErrorEvent>.broadcast();
  
  WebSocketIO(this.url) {
    if (!kIsWeb) {
      try {
        // Import dart:io in native mode
        // This will be done at runtime, not compile time
        WebSocket.connect(url).then((socket) {
          _webSocket = socket;
          
          _onOpenController.add(WebSocketOpenEvent());
          
          _webSocket.listen(
            (data) {
              _onMessageController.add(WebSocketMessageEvent(data));
            },
            onDone: () {
              _onCloseController.add(WebSocketCloseEvent(null, null));
            },
            onError: (error) {
              _onErrorController.add(WebSocketErrorEvent(error));
            },
          );
        }).catchError((error) {
          _onErrorController.add(WebSocketErrorEvent(error));
        });
      } catch (e) {
        _onErrorController.add(WebSocketErrorEvent(e));
      }
    }
  }
  
  @override
  Stream<WebSocketOpenEvent> get onOpen => _onOpenController.stream;
  
  @override
  Stream<WebSocketMessageEvent> get onMessage => _onMessageController.stream;
  
  @override
  Stream<WebSocketCloseEvent> get onClose => _onCloseController.stream;
  
  @override
  Stream<WebSocketErrorEvent> get onError => _onErrorController.stream;
  
  @override
  void send(String data) {
    if (_webSocket != null) {
      _webSocket.add(data);
    }
  }
  
  @override
  void close([int? code, String? reason]) {
    if (_webSocket != null) {
      _webSocket.close(code, reason);
    }
    
    _onOpenController.close();
    _onMessageController.close();
    _onCloseController.close();
    _onErrorController.close();
  }
}

// Stub class for conditional import resolution
class WebSocketHtml {
  final String url;
  
  WebSocketHtml(this.url); 
  
  Stream get onOpen => throw UnimplementedError();
  Stream get onMessage => throw UnimplementedError();
  Stream get onClose => throw UnimplementedError();
  Stream get onError => throw UnimplementedError();
  
  void send(String data) {}
  void close([int? code, String? reason]) {}
}

// Stream controllers for event handling
class StreamController<T> {
  List<Function(T)> _listeners = [];
  
  StreamController.broadcast();
  
  Stream<T> get stream => Stream<T>.fromListeners(_listeners);
  
  void add(T event) {
    for (var listener in _listeners) {
      listener(event);
    }
  }
  
  void close() {
    _listeners.clear();
  }
}

// Simple Stream implementation
class Stream<T> {
  final List<Function(T)> _listeners;
  
  Stream.fromListeners(this._listeners);
  
  StreamSubscription<T> listen(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _listeners.add(onData);
    return StreamSubscription<T>(() {
      _listeners.remove(onData);
    });
  }
}

// Simple StreamSubscription implementation
class StreamSubscription<T> {
  final Function _cancel;
  
  StreamSubscription(this._cancel);
  
  void cancel() {
    _cancel();
  }
}