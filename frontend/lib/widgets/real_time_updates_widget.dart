import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/services/websocket_service.dart';

class RealTimeUpdatesWidget extends ConsumerStatefulWidget {
  const RealTimeUpdatesWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<RealTimeUpdatesWidget> createState() => _RealTimeUpdatesWidgetState();
}

class _RealTimeUpdatesWidgetState extends ConsumerState<RealTimeUpdatesWidget> {
  final List<WebSocketEvent> _recentEvents = [];
  static const int _maxEvents = 10;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize WebSocket connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure WebSocket service is initialized
      ref.read(websocketServiceProvider);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Listen to all WebSocket events
    ref.listen<AsyncValue<dynamic>>(
      websocketEventProvider(WebSocketEventType.cylinderStatusUpdated), 
      (_, state) {
        state.whenData((data) {
          _addEvent(WebSocketEvent(
            type: WebSocketEventType.cylinderStatusUpdated,
            data: data,
          ));
        });
      }
    );
    
    ref.listen<AsyncValue<dynamic>>(
      websocketEventProvider(WebSocketEventType.fillingCompleted), 
      (_, state) {
        state.whenData((data) {
          _addEvent(WebSocketEvent(
            type: WebSocketEventType.fillingCompleted,
            data: data,
          ));
        });
      }
    );
    
    ref.listen<AsyncValue<dynamic>>(
      websocketEventProvider(WebSocketEventType.inspectionCompleted), 
      (_, state) {
        state.whenData((data) {
          _addEvent(WebSocketEvent(
            type: WebSocketEventType.inspectionCompleted,
            data: data,
          ));
        });
      }
    );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Real-time Updates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildConnectionIndicator(),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_recentEvents.isEmpty) 
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent updates'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentEvents.length,
                itemBuilder: (context, index) {
                  final event = _recentEvents[index];
                  return _buildEventTile(event);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionIndicator() {
    // Check connection status with a stream
    return StreamBuilder<WebSocketEvent>(
      stream: ref.read(websocketServiceProvider).eventStream,
      builder: (context, snapshot) {
        final bool isConnected = snapshot.connectionState != ConnectionState.waiting;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green.shade800 : Colors.red.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildEventTile(WebSocketEvent event) {
    IconData icon;
    String title;
    String subtitle = '';
    
    switch (event.type) {
      case WebSocketEventType.cylinderStatusUpdated:
        icon = Icons.update;
        final data = event.data as Map<String, dynamic>;
        title = 'Cylinder Status Updated';
        subtitle = 'ID: ${data['id']} - New Status: ${data['status']}';
        break;
        
      case WebSocketEventType.fillingCompleted:
        icon = Icons.local_gas_station;
        final data = event.data as Map<String, dynamic>;
        title = 'Filling Completed';
        subtitle = 'Cylinder: ${data['cylinderId']}';
        break;
        
      case WebSocketEventType.inspectionCompleted:
        icon = Icons.check_circle;
        final data = event.data as Map<String, dynamic>;
        title = 'Inspection Completed';
        subtitle = 'Cylinder: ${data['cylinderId']} - Result: ${data['result']}';
        break;
        
      default:
        icon = Icons.notifications;
        title = 'System Update';
        break;
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
        child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }
  
  void _addEvent(WebSocketEvent event) {
    setState(() {
      _recentEvents.insert(0, event);
      if (_recentEvents.length > _maxEvents) {
        _recentEvents.removeLast();
      }
    });
  }
}