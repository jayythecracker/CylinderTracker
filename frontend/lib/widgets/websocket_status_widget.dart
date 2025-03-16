import 'package:flutter/material.dart';
import 'package:cylinder_management/services/websocket_service.dart';
import 'package:cylinder_management/services/websocket_manager.dart';
import 'package:cylinder_management/providers/services_provider.dart';

/// A widget that displays the WebSocket connection status and recent events
class WebSocketStatusWidget extends StatefulWidget {
  const WebSocketStatusWidget({Key? key}) : super(key: key);

  @override
  State<WebSocketStatusWidget> createState() => _WebSocketStatusWidgetState();
}

class _WebSocketStatusWidgetState extends State<WebSocketStatusWidget> {
  final List<String> _events = [];
  bool _isConnected = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Get references to services
    final websocketService = ServicesProvider.websocket(context);
    final websocketManager = ServicesProvider.websocketManager(context);
    
    // Update state when the WebSocket connection status changes
    websocketService.addListener(_updateConnectionStatus);
    
    // Set initial connection status
    _isConnected = websocketService.isConnected;
    _errorMessage = websocketService.errorMessage;
    
    // Listen for cylinder events
    _setupEventListeners(websocketManager);
  }
  
  @override
  void dispose() {
    // Clean up listeners
    ServicesProvider.websocket(context).removeListener(_updateConnectionStatus);
    super.dispose();
  }
  
  void _updateConnectionStatus() {
    setState(() {
      final websocketService = ServicesProvider.websocket(context);
      _isConnected = websocketService.isConnected;
      _errorMessage = websocketService.errorMessage;
    });
  }
  
  void _setupEventListeners(WebSocketManager manager) {
    // Listen for cylinder status updates
    manager.on(WebSocketManager.cylinderStatusUpdated, (data) {
      _addEvent('Cylinder #${data['id']} status updated to ${data['status']}');
    });
    
    // Listen for filling operations
    manager.on(WebSocketManager.fillingStarted, (data) {
      _addEvent('Filling started for cylinder #${data.cylinderId}');
    });
    
    manager.on(WebSocketManager.fillingCompleted, (data) {
      _addEvent('Filling completed for cylinder #${data.cylinderId}');
    });
    
    // Listen for inspections
    manager.on(WebSocketManager.inspectionCompleted, (data) {
      _addEvent('Inspection completed for cylinder #${data.cylinderId}: ${data.result}');
    });
    
    // Listen for sales
    manager.on(WebSocketManager.saleCreated, (data) {
      _addEvent('New sale #${data.id} created for customer #${data.customerId}');
    });
    
    manager.on(WebSocketManager.saleStatusUpdated, (data) {
      _addEvent('Sale #${data['id']} status updated to ${data['status']}');
    });
  }
  
  void _addEvent(String event) {
    setState(() {
      _events.insert(0, '${DateTime.now().toString().substring(11, 19)} - $event');
      // Keep only the last 10 events
      if (_events.length > 10) {
        _events.removeLast();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (_isConnected) {
                      ServicesProvider.websocketManager(context).disconnect();
                    } else {
                      ServicesProvider.websocketManager(context).connect();
                    }
                  },
                  child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Recent Events:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_events.isEmpty)
              const Text('No events yet', style: TextStyle(fontStyle: FontStyle.italic))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _events.map((event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(event),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}