import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/models/filling.dart';
import 'package:cylinder_management/models/inspection.dart';
import 'package:cylinder_management/providers/cylinder_provider.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/widgets/loading_indicator.dart';
import 'package:cylinder_management/widgets/error_display.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CylinderDetailScreen extends ConsumerStatefulWidget {
  final int cylinderId;

  const CylinderDetailScreen({
    Key? key,
    required this.cylinderId,
  }) : super(key: key);

  @override
  ConsumerState<CylinderDetailScreen> createState() => _CylinderDetailScreenState();
}

class _CylinderDetailScreenState extends ConsumerState<CylinderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _historyData;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch cylinder details
    Future.microtask(() {
      ref.read(cylinderDetailsProvider(widget.cylinderId).notifier).fetchCylinderDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_historyData != null || _isLoadingHistory) return;
    
    setState(() {
      _isLoadingHistory = true;
    });
    
    try {
      final data = await ref.read(cylinderDetailsProvider(widget.cylinderId).notifier).fetchCylinderHistory();
      setState(() {
        _historyData = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cylinderData = ref.watch(cylinderDetailsProvider(widget.cylinderId));
    final user = ref.watch(authProvider).value;
    final bool canEdit = user != null && (user.isAdmin || user.isManager);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cylinder Details'),
        backgroundColor: AppConfig.primaryColor,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                cylinderData.whenData((data) {
                  if (data != null && data['cylinder'] != null) {
                    _showEditDialog(data['cylinder']);
                  }
                });
              },
            ),
        ],
      ),
      body: cylinderData.when(
        data: (data) {
          if (data == null || data['cylinder'] == null) {
            return const Center(
              child: Text('Cylinder not found'),
            );
          }
          
          final cylinder = data['cylinder'] as Cylinder;
          final lastFilling = data['lastFilling'] != null ? Filling.fromJson(data['lastFilling']) : null;
          final lastInspection = data['lastInspection'] != null ? Inspection.fromJson(data['lastInspection']) : null;
          
          return Column(
            children: [
              // Header with cylinder info and status
              _buildCylinderHeader(cylinder),
              
              // Tab bar
              Container(
                color: AppConfig.primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Recent Activity'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(cylinder),
                    _buildRecentActivityTab(cylinder, lastFilling, lastInspection),
                    _buildHistoryTab(cylinder),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: error.toString(),
          onRetry: () {
            ref.refresh(cylinderDetailsProvider(widget.cylinderId));
          },
        ),
      ),
    );
  }

  Widget _buildCylinderHeader(Cylinder cylinder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.getStatusColor(cylinder.status).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppConfig.getStatusColor(cylinder.status),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppConfig.getStatusColor(cylinder.status),
            child: Icon(
              _getStatusIcon(cylinder.status),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cylinder.serialNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(
                      cylinder.type,
                      Icons.category_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      cylinder.size,
                      Icons.straighten_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Factory: '),
                    Text(
                      cylinder.factory?.name ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppConfig.getStatusColor(cylinder.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  cylinder.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('Show QR'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => _showQRCode(cylinder),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Cylinder cylinder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Serial Number:', cylinder.serialNumber),
                  _buildInfoRow('Type:', cylinder.type),
                  _buildInfoRow('Size:', cylinder.size),
                  _buildInfoRow('Status:', cylinder.status),
                  if (cylinder.originalNumber != null && cylinder.originalNumber!.isNotEmpty)
                    _buildInfoRow('Original Number:', cylinder.originalNumber!),
                ],
              ),
            ),
          ),
          
          // Technical Specs Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Technical Specifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Working Pressure:', '${cylinder.workingPressure} bar'),
                  _buildInfoRow('Design Pressure:', '${cylinder.designPressure} bar'),
                  _buildInfoRow('Production Date:', DateFormat('MMM dd, yyyy').format(cylinder.productionDate)),
                  if (cylinder.importDate != null)
                    _buildInfoRow('Import Date:', DateFormat('MMM dd, yyyy').format(cylinder.importDate!)),
                ],
              ),
            ),
          ),
          
          // Last Activity Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (cylinder.lastFilled != null)
                    _buildInfoRow('Last Filled:', DateFormat('MMM dd, yyyy').format(cylinder.lastFilled!))
                  else
                    _buildInfoRow('Last Filled:', 'Never'),
                  
                  if (cylinder.lastInspected != null)
                    _buildInfoRow('Last Inspected:', DateFormat('MMM dd, yyyy').format(cylinder.lastInspected!))
                  else
                    _buildInfoRow('Last Inspected:', 'Never'),
                  
                  _buildInfoRow('Created Date:', DateFormat('MMM dd, yyyy').format(cylinder.createdAt)),
                  _buildInfoRow('Updated Date:', DateFormat('MMM dd, yyyy').format(cylinder.updatedAt)),
                ],
              ),
            ),
          ),
          
          // Notes Card (if any)
          if (cylinder.notes != null && cylinder.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      cylinder.notes!,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTab(Cylinder cylinder, Filling? lastFilling, Inspection? lastInspection) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Filling Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_gas_station,
                        color: AppConfig.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Latest Filling',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (lastFilling != null) ...[
                    _buildInfoRow('Date:', DateFormat('MMM dd, yyyy').format(lastFilling.startTime)),
                    _buildInfoRow('Status:', lastFilling.status),
                    _buildInfoRow('Line Number:', lastFilling.lineNumber.toString()),
                    _buildInfoRow('Initial Pressure:', '${lastFilling.initialPressure} bar'),
                    if (lastFilling.finalPressure != null)
                      _buildInfoRow('Final Pressure:', '${lastFilling.finalPressure} bar'),
                    _buildInfoRow('Target Pressure:', '${lastFilling.targetPressure} bar'),
                    _buildInfoRow('Gas Type:', lastFilling.gasType),
                    if (lastFilling.startedBy != null)
                      _buildInfoRow('Started By:', lastFilling.startedBy!.name),
                    if (lastFilling.endedBy != null)
                      _buildInfoRow('Ended By:', lastFilling.endedBy!.name),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No filling records available'),
                    ),
                ],
              ),
            ),
          ),
          
          // Recent Inspection Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: lastInspection?.result == 'Approved' 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Latest Inspection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (lastInspection != null) ...[
                    _buildInfoRow('Date:', DateFormat('MMM dd, yyyy').format(lastInspection.inspectionDate)),
                    _buildInfoRow('Result:', lastInspection.result),
                    _buildInfoRow('Pressure Check:', '${lastInspection.pressureCheck} bar'),
                    _buildInfoRow('Visual Check:', lastInspection.visualCheck ? 'Passed' : 'Failed'),
                    _buildInfoRow('Valve Check:', lastInspection.valveCheck ? 'Passed' : 'Failed'),
                    if (lastInspection.rejectionReason != null && lastInspection.rejectionReason!.isNotEmpty)
                      _buildInfoRow('Rejection Reason:', lastInspection.rejectionReason!),
                    if (lastInspection.inspectedBy != null)
                      _buildInfoRow('Inspected By:', lastInspection.inspectedBy!.name),
                  ] else
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No inspection records available'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(Cylinder cylinder) {
    // Load history data when tab is selected
    _loadHistory();
    
    if (_isLoadingHistory) {
      return const Center(child: LoadingIndicator());
    }
    
    if (_historyData == null) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Load History'),
          onPressed: _loadHistory,
        ),
      );
    }
    
    final fillings = _historyData!['history']['fillings'] as List<dynamic>;
    final inspections = _historyData!['history']['inspections'] as List<dynamic>;
    
    if (fillings.isEmpty && inspections.isEmpty) {
      return const Center(
        child: Text('No history records available'),
      );
    }
    
    // Combine and sort history items by date (newest first)
    final historyItems = <Map<String, dynamic>>[];
    
    for (final filling in fillings) {
      historyItems.add({
        'type': 'filling',
        'data': Filling.fromJson(filling),
        'date': DateTime.parse(filling['startTime']),
      });
    }
    
    for (final inspection in inspections) {
      historyItems.add({
        'type': 'inspection',
        'data': Inspection.fromJson(inspection),
        'date': DateTime.parse(inspection['inspectionDate']),
      });
    }
    
    historyItems.sort((a, b) => b['date'].compareTo(a['date']));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        final item = historyItems[index];
        final isLast = index == historyItems.length - 1;
        
        if (item['type'] == 'filling') {
          return _buildFillingHistoryItem(item['data'], isLast);
        } else {
          return _buildInspectionHistoryItem(item['data'], isLast);
        }
      },
    );
  }

  Widget _buildFillingHistoryItem(Filling filling, bool isLast) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: filling.status == 'Completed' ? Colors.green : 
                           filling.status == 'Failed' ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 70,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filling',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(filling.startTime),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow('Status:', filling.status),
                      _buildInfoRow('Line:', filling.lineNumber.toString()),
                      _buildInfoRow('Gas:', filling.gasType),
                      _buildInfoRow('Initial Pressure:', '${filling.initialPressure} bar'),
                      if (filling.finalPressure != null)
                        _buildInfoRow('Final Pressure:', '${filling.finalPressure} bar'),
                      if (filling.endTime != null)
                        _buildInfoRow('Duration:', filling.durationFormatted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInspectionHistoryItem(Inspection inspection, bool isLast) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: inspection.result == 'Approved' ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 70,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Inspection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(inspection.inspectionDate),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow('Result:', inspection.result),
                      _buildInfoRow('Pressure:', '${inspection.pressureCheck} bar'),
                      _buildInfoRow('Visual Check:', inspection.visualCheck ? 'Passed' : 'Failed'),
                      _buildInfoRow('Valve Check:', inspection.valveCheck ? 'Passed' : 'Failed'),
                      if (inspection.rejectionReason != null && inspection.rejectionReason!.isNotEmpty)
                        _buildInfoRow('Reason:', inspection.rejectionReason!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(Cylinder cylinder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cylinder QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: cylinder.qrCode ?? 'CYL-${cylinder.serialNumber}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Serial: ${cylinder.serialNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Type: ${cylinder.type}',
            ),
            Text(
              'Size: ${cylinder.size}',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Cylinder cylinder) {
    // Create edit dialog similar to the one in cylinders_screen.dart
    // This is a simplified version that should be expanded
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cylinder'),
        content: const Text('Editing functionality should be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'empty':
        return Icons.battery_0_bar;
      case 'full':
        return Icons.battery_full;
      case 'error':
        return Icons.error_outline;
      case 'inmaintenance':
        return Icons.build;
      case 'intransit':
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }
}
