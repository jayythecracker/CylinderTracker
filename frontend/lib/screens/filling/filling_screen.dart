import 'package:flutter/material.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/filling_operation.dart';
import 'package:cylinder_management/widgets/websocket_status_widget.dart';
import 'package:cylinder_management/providers/services_provider.dart';
import 'package:cylinder_management/services/websocket_manager.dart';

class FillingScreen extends StatefulWidget {
  const FillingScreen({Key? key}) : super(key: key);

  @override
  State<FillingScreen> createState() => _FillingScreenState();
}

class _FillingScreenState extends State<FillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // List of active filling operations
  final List<FillingOperation> _activeFillings = [];
  
  // List of recent filling operations
  final List<FillingOperation> _recentFillings = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupWebSocketListeners();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Set up WebSocket listeners for real-time updates
  void _setupWebSocketListeners() {
    final webSocketManager = ServicesProvider.websocketManager(context);
    
    // Listen for filling started
    webSocketManager.on(WebSocketManager.fillingStarted, (filling) {
      setState(() {
        _activeFillings.add(filling);
      });
    });
    
    // Listen for filling completed
    webSocketManager.on(WebSocketManager.fillingCompleted, (filling) {
      setState(() {
        // Remove from active fillings if present
        _activeFillings.removeWhere((f) => f.id == filling.id);
        
        // Add to recent fillings
        _recentFillings.insert(0, filling);
        
        // Keep only the 20 most recent ones
        if (_recentFillings.length > 20) {
          _recentFillings.removeLast();
        }
      });
    });
  }
  
  // Load initial data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Fetch active filling operations
      final apiService = ServicesProvider.api(context);
      
      // TODO: Replace with actual API calls once implemented
      // final activeFillingResponse = await apiService.getFillingOperations(status: 'InProgress');
      // final recentFillingResponse = await apiService.getFillingOperations(limit: 20);
      
      // For now, use sample data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _activeFillings.clear();
        _recentFillings.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load filling operations: $e';
        _isLoading = false;
      });
    }
  }
  
  // Start a new filling operation
  Future<void> _startFilling(Cylinder cylinder) async {
    // TODO: Implement start filling API call
  }
  
  // Complete an active filling operation
  Future<void> _completeFilling(FillingOperation filling, double finalPressure) async {
    // TODO: Implement complete filling API call
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filling Operations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Fillings'),
            Tab(text: 'Recent Fillings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // WebSocket status widget at the top
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WebSocketStatusWidget(),
                    ),
                    
                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Active fillings tab
                          _activeFillings.isEmpty
                              ? const Center(child: Text('No active filling operations'))
                              : ListView.builder(
                                  itemCount: _activeFillings.length,
                                  itemBuilder: (context, index) => _buildFillingCard(
                                    _activeFillings[index],
                                    isActive: true,
                                  ),
                                ),
                          
                          // Recent fillings tab
                          _recentFillings.isEmpty
                              ? const Center(child: Text('No recent filling operations'))
                              : ListView.builder(
                                  itemCount: _recentFillings.length,
                                  itemBuilder: (context, index) => _buildFillingCard(
                                    _recentFillings[index],
                                    isActive: false,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to start a new filling operation
          _showStartFillingDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'Start New Filling',
      ),
    );
  }
  
  // Build a card for a filling operation
  Widget _buildFillingCard(FillingOperation filling, {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filling #${filling.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'In Progress' : 'Completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cylinder: #${filling.cylinderId}'),
            Text('Gas Type: ${filling.gasType}'),
            Text('Filled By: User #${filling.filledById}'),
            Text('Date: ${_formatDate(filling.fillingDate)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Initial Pressure'),
                      Text(
                        '${filling.initialPressure} bar',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Final Pressure'),
                      Text(
                        filling.finalPressure != null
                            ? '${filling.finalPressure} bar'
                            : 'Pending',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: filling.finalPressure != null
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (filling.notes != null && filling.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${filling.notes}'),
            ],
            if (isActive) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Show dialog to complete the filling operation
                  _showCompleteFillingDialog(filling);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text('Complete Filling'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Format a date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Show dialog to start a new filling operation
  void _showStartFillingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Filling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Implement form for starting new filling
            const Text('Form for starting new filling operation will be implemented here.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement start filling logic
              Navigator.of(context).pop();
            },
            child: const Text('Start Filling'),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to complete a filling operation
  void _showCompleteFillingDialog(FillingOperation filling) {
    final finalPressureController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Filling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cylinder: #${filling.cylinderId}'),
            const SizedBox(height: 16),
            TextField(
              controller: finalPressureController,
              decoration: const InputDecoration(
                labelText: 'Final Pressure (bar)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement complete filling logic
              final finalPressure = double.tryParse(finalPressureController.text);
              
              if (finalPressure == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid final pressure'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              
              // Complete the filling operation
              _completeFilling(filling, finalPressure);
            },
            child: const Text('Complete Filling'),
          ),
        ],
      ),
    );
  }
}