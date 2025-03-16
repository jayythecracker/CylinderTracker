# WebSocket Integration Guide

This document provides a comprehensive guide for implementing and working with real-time WebSocket features in the Cylinder Management System.

## Overview

WebSockets provide real-time, bidirectional communication between the server and clients. In our system, WebSockets are used to broadcast events such as cylinder status changes, filling operations, and inspection results to all connected clients.

## Server Implementation

The WebSocket server is implemented in `backend/server.js` and uses the `ws` library. It shares the same HTTP server as the REST API but listens on a dedicated path (`/ws`).

### Key Components:

1. **WebSocket Server Initialization**:
   ```javascript
   const wss = new WebSocketServer({ server, path: '/ws' });
   ```

2. **Connection Management**:
   ```javascript
   let activeConnections = [];
   
   wss.on('connection', (ws) => {
     // Add to active connections
     activeConnections.push(ws);
     
     // Handle disconnection
     ws.on('close', () => {
       activeConnections = activeConnections.filter(client => client !== ws);
     });
   });
   ```

3. **Broadcasting Function**:
   ```javascript
   function broadcast(data) {
     const message = JSON.stringify(data);
     activeConnections.forEach(client => {
       if (client.readyState === WebSocket.OPEN) {
         client.send(message);
       }
     });
   }
   ```

## Broadcast Utility

The `backend/utils/broadcast.js` file provides utility functions for broadcasting different event types:

```javascript
// Example: Broadcasting a cylinder status update
exports.cylinderStatusUpdated = (data) => {
  broadcast({
    type: 'cylinder_status_updated',
    data
  });
};
```

## Using WebSockets in Backend Code

To broadcast events from your controller or service code:

```javascript
const broadcast = require('../utils/broadcast');

// Inside a controller method after updating a cylinder
async function updateCylinderStatus(req, res) {
  try {
    // Update cylinder in database
    const updatedCylinder = await storage.updateCylinder(id, { status });
    
    // Broadcast the update to all connected clients
    broadcast.cylinderStatusUpdated({
      id: updatedCylinder.id,
      status: updatedCylinder.status,
      notes: req.body.notes,
      updatedBy: req.user.username,
      timestamp: new Date().toISOString()
    });
    
    // Send response
    res.json(updatedCylinder);
  } catch (error) {
    // Error handling
  }
}
```

## Flutter Client Implementation

### 1. Setup WebSocket Connection

The Flutter app uses the `web_socket_channel` package to handle WebSocket connections. The implementation is encapsulated in `frontend/lib/services/websocket_service.dart`.

Key components:

```dart
// Creating the WebSocket connection
if (kIsWeb) {
  _channel = HtmlWebSocketChannel.connect(wsUrl);
} else {
  _channel = IOWebSocketChannel.connect(wsUrl);
}

// Listening for messages
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
  // Error handling omitted for brevity
);
```

### 2. Using WebSockets in Flutter UI

```dart
// Initialize the service with Riverpod
final websocketService = ref.watch(websocketServiceProvider);

// Listen for specific event types
ref.listen<AsyncValue<dynamic>>(
  websocketEventProvider(WebSocketEventType.cylinderStatusUpdated), 
  (_, state) {
    state.whenData((data) {
      // Update UI based on the event
      setState(() {
        cylinder.status = data['status'];
      });
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cylinder status updated to ${data['status']}'))
      );
    });
  }
);
```

## Testing WebSocket Functionality

You can use the provided test utilities to verify WebSocket functionality:

1. **Simple Test Client** (`websocket_test.js`):
   ```bash
   node websocket_test.js
   ```
   This connects to the WebSocket server, sends a simple message, and displays the response.

2. **Interactive Simulator** (`websocket_simulator.js`):
   ```bash
   node websocket_simulator.js
   ```
   This provides an interactive CLI to simulate different event types.

## WebSocket Event Types

| Event Type | Description | Data Payload |
|------------|-------------|------------|
| `cylinder_created` | New cylinder added | Cylinder object with all properties |
| `cylinder_updated` | Cylinder details updated | Updated cylinder object |
| `cylinder_deleted` | Cylinder removed | `{ id: number }` |
| `cylinder_status_updated` | Status changed | `{ id, status, notes, updatedBy, timestamp }` |
| `filling_started` | Filling operation initiated | Filling object with start time |
| `filling_completed` | Filling operation finished | Complete filling object with end time |
| `inspection_completed` | Inspection performed | Inspection object with result |
| `sale_created` | New sale recorded | Sale object with items |
| `sale_status_updated` | Sale status changed | `{ id, status, notes, timestamp }` |

## Best Practices

1. **Connection Management**:
   - Always handle reconnection in the client
   - Check WebSocket readyState before sending messages

2. **Error Handling**:
   - Validate message format on both client and server
   - Implement proper error reporting

3. **Performance**:
   - Keep messages small and focused
   - Don't send large objects over WebSockets

4. **Security**:
   - Don't send sensitive data via WebSockets
   - Consider implementing additional authentication for WebSocket connections

5. **Flutter UI Updates**:
   - Use setState or state management solutions to update UI based on WebSocket events
   - Consider debouncing frequent updates

## Troubleshooting

1. **Connection Issues**:
   - Verify server is running and WebSocket path is correct
   - Check for network/firewall issues

2. **Message Not Received**:
   - Verify connection is still active
   - Check event type spelling
   - Ensure JSON formatting is correct

3. **Flutter Client Issues**:
   - Ensure web_socket_channel dependency is installed
   - Verify correct WebSocket URL construction

## Additional Resources

- [ws library documentation](https://github.com/websockets/ws)
- [web_socket_channel package](https://pub.dev/packages/web_socket_channel)
- [Flutter Riverpod](https://riverpod.dev/) for state management with WebSockets