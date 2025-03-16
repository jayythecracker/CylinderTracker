import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/filling_line.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/screens/filling/filling_line_screen.dart';
import 'package:cylinder_management/screens/filling/filling_history_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final fillingLinesProvider = FutureProvider<List<FillingLine>>((ref) async {
  try {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final url = Uri.parse('${AppConfig.baseUrl}/fillings/lines');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await ref.read(authProvider.notifier)._authService.getToken()}',
      },
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        final List<dynamic> linesData = jsonData['data'];
        return linesData.map((line) => FillingLine.fromJson(line)).toList();
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to fetch filling lines');
      }
    } else {
      throw Exception('Failed to fetch filling lines: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching filling lines: $e');
  }
});

class FillingScreen extends ConsumerStatefulWidget {
  const FillingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FillingScreen> createState() => _FillingScreenState();
}

class _FillingScreenState extends ConsumerState<FillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillingLines = ref.watch(fillingLinesProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppConfig.primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(
                  icon: Icon(Icons.local_gas_station),
                  text: 'Filling Lines',
                ),
                Tab(
                  icon: Icon(Icons.history),
                  text: 'Filling History',
                ),
              ],
            ),
          ),
          
          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Filling Lines Tab
                _buildFillingLinesTab(fillingLines),
                
                // Filling History Tab
                const FillingHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                _showCreateLineDialog(context);
              },
              backgroundColor: AppConfig.accentColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFillingLinesTab(AsyncValue<List<FillingLine>> fillingLines) {
    return fillingLines.when(
      data: (lines) {
        if (lines.isEmpty) {
          return _buildEmptyState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            return ref.refresh(fillingLinesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              return _buildFillingLineCard(context, line);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading filling lines',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.refresh(fillingLinesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillingLineCard(BuildContext context, FillingLine line) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FillingLineScreen(lineId: line.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line header with status indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: line.isActive
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      line.isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Line ${line.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    color: Colors.green,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FillingLineScreen(lineId: line.id),
                        ),
                      );
                    },
                    tooltip: 'Start Filling',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Line details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(
                    'Capacity',
                    '${line.capacity} cylinders',
                    Icons.view_module,
                  ),
                  _buildStatColumn(
                    'Current Load',
                    '${line.currentCylinders} cylinders',
                    Icons.apps,
                  ),
                  _buildStatColumn(
                    'Type',
                    line.type,
                    Icons.category,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filling Progress: ${line.isActive && line.currentCylinders > 0 ? '${line.progressPercentage.toInt()}%' : 'Not Started'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: line.isActive && line.currentCylinders > 0
                        ? line.progressPercentage / 100
                        : 0,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      line.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              
              if (line.currentCylinders > 0) ...[
                const SizedBox(height: 16),
                
                // Time details if active
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        'Started',
                        line.startTime != null
                            ? _formatTime(line.startTime!)
                            : 'N/A',
                        Icons.play_circle_outline,
                      ),
                    ),
                    Expanded(
                      child: _buildTimeInfo(
                        'Est. Completion',
                        line.estimatedEndTime != null
                            ? _formatTime(line.estimatedEndTime!)
                            : 'N/A',
                        Icons.timer,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppConfig.primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String title, String time, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_gas_station_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Filling Lines Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new filling line to start',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateLineDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Filling Line'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateLineDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    int capacity = 10;
    String type = 'Industrial';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Filling Line'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Capacity field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    hintText: 'Number of cylinders',
                    prefixIcon: Icon(Icons.view_module),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '10',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter capacity';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1) {
                      return 'Enter a valid capacity';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    capacity = int.parse(value!);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Type dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  value: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'Industrial',
                      child: Text('Industrial'),
                    ),
                    DropdownMenuItem(
                      value: 'Medical',
                      child: Text('Medical'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      type = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  
                  _createFillingLine(context, capacity, type);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFillingLine(
    BuildContext context,
    int capacity,
    String type,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/fillings/lines');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ref.read(authProvider.notifier)._authService.getToken()}',
        },
        body: json.encode({
          'capacity': capacity,
          'type': type,
        }),
      );
      
      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        if (jsonData['success']) {
          ref.refresh(fillingLinesProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filling line created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonData['message'] ?? 'Failed to create filling line'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create filling line: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating filling line: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      // Same day, show only time
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // Different day, show date and time
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}