import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../services/qr_scanner_service.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/scan_qr_widget.dart';
import 'cylinder_form_screen.dart';

class CylinderListScreen extends ConsumerStatefulWidget {
  const CylinderListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CylinderListScreen> createState() => _CylinderListScreenState();
}

class _CylinderListScreenState extends ConsumerState<CylinderListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedGasType;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _loadCylinders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCylinders() async {
    await ref.read(cylindersProvider.notifier).getCylinders(
      filters: {
        'status': _selectedStatus,
        'gasType': _selectedGasType,
        'size': _selectedSize,
        'search': _searchController.text.isEmpty ? null : _searchController.text,
        'page': 1,
      },
    );
  }

  Future<void> _refreshCylinders() async {
    // Reset page to 1 and refresh
    ref.read(cylinderFilterProvider.notifier).state = {
      ...ref.read(cylinderFilterProvider),
      'page': 1,
    };
    await _loadCylinders();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedGasType = null;
      _selectedSize = null;
    });
    _refreshCylinders();
  }
  
  Future<void> _scanQRCode() async {
    try {
      final qrScannerService = QRScannerService();
      final scannedCode = await QRScannerService.scanQRCodeFullScreen(context);
      
      if (scannedCode != null) {
        try {
          final cylinder = await qrScannerService.getCylinderByQRCode(scannedCode);
          if (mounted) {
            _showCylinderDetails(cylinder);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to find cylinder: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan QR code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final cylindersAsync = ref.watch(cylindersProvider);
    final paginationInfo = ref.watch(cylinderPaginationProvider);
    
    // Check if user has admin or manager access for edit/create operations
    final hasAdminOrManagerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cylinders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCylinders,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: hasAdminOrManagerAccess
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CylinderFormScreen(),
                  ),
                ).then((_) => _loadCylinders());
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search cylinders',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshCylinders();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _refreshCylinders(),
            ),
          ),
          
          // Active filters display
          if (_selectedStatus != null || _selectedGasType != null || _selectedSize != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text('Filters:'),
                  const SizedBox(width: 8),
                  if (_selectedStatus != null)
                    Chip(
                      label: Text(_selectedStatus!),
                      onDeleted: () {
                        setState(() {
                          _selectedStatus = null;
                        });
                        _refreshCylinders();
                      },
                    ),
                  const SizedBox(width: 4),
                  if (_selectedGasType != null)
                    Chip(
                      label: Text(_selectedGasType!),
                      onDeleted: () {
                        setState(() {
                          _selectedGasType = null;
                        });
                        _refreshCylinders();
                      },
                    ),
                  const SizedBox(width: 4),
                  if (_selectedSize != null)
                    Chip(
                      label: Text(_selectedSize!),
                      onDeleted: () {
                        setState(() {
                          _selectedSize = null;
                        });
                        _refreshCylinders();
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          // Cylinders list
          Expanded(
            child: cylindersAsync.when(
              data: (cylinders) => _buildCylinderList(
                cylinders,
                paginationInfo,
                hasAdminOrManagerAccess,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCylinderList(
    List<Cylinder> cylinders,
    Map<String, dynamic> paginationInfo,
    bool hasAdminOrManagerAccess,
  ) {
    if (cylinders.isEmpty) {
      return const Center(
        child: Text('No cylinders found'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCylinders,
            child: ListView.builder(
              itemCount: cylinders.length,
              itemBuilder: (context, index) {
                final cylinder = cylinders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(cylinder.status),
                      child: const Icon(
                        Icons.propane_tank,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'SN: ${cylinder.serialNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Size: ${cylinder.size} | Type: ${cylinder.gasType}'),
                        Text('Factory: ${cylinder.factory?.name ?? "Unknown"}'),
                        Text('Status: ${cylinder.status}'),
                      ],
                    ),
                    trailing: hasAdminOrManagerAccess
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              ref.read(selectedCylinderProvider.notifier).state = cylinder;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CylinderFormScreen(cylinderId: cylinder.id),
                                ),
                              ).then((_) => _loadCylinders());
                            },
                          )
                        : null,
                    onTap: () => _showCylinderDetails(cylinder),
                  ),
                );
              },
            ),
          ),
        ),
        // Pagination controls
        if (paginationInfo['totalPages'] > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: paginationInfo['currentPage'] > 1
                      ? () {
                          ref.read(cylinderFilterProvider.notifier).state = {
                            ...ref.read(cylinderFilterProvider),
                            'page': paginationInfo['currentPage'] - 1,
                          };
                          _loadCylinders();
                        }
                      : null,
                ),
                Text(
                  '${paginationInfo['currentPage']} of ${paginationInfo['totalPages']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: paginationInfo['currentPage'] < paginationInfo['totalPages']
                      ? () {
                          ref.read(cylinderFilterProvider.notifier).state = {
                            ...ref.read(cylinderFilterProvider),
                            'page': paginationInfo['currentPage'] + 1,
                          };
                          _loadCylinders();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Empty':
        return Colors.grey;
      case 'Full':
        return Colors.green;
      case 'In Filling':
        return Colors.blue;
      case 'In Inspection':
        return Colors.orange;
      case 'Error':
        return Colors.red;
      case 'In Delivery':
        return Colors.purple;
      case 'Maintenance':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showCylinderDetails(Cylinder cylinder) {
    final currentUser = ref.read(authProvider).value;
    final hasAdminOrManagerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager'],
    );
    final hasFillerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'filler'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cylinder: ${cylinder.serialNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Serial Number', cylinder.serialNumber),
              _buildDetailItem('QR Code', cylinder.qrCode),
              _buildDetailItem('Size', cylinder.size),
              _buildDetailItem('Gas Type', cylinder.gasType),
              _buildDetailItem('Working Pressure', '${cylinder.workingPressure} bar'),
              _buildDetailItem('Design Pressure', '${cylinder.designPressure} bar'),
              _buildDetailItem('Status', cylinder.status),
              _buildDetailItem('Factory', cylinder.factory?.name ?? 'Unknown'),
              _buildDetailItem('Production Date', cylinder.productionDate.toString().substring(0, 10)),
              if (cylinder.importDate != null)
                _buildDetailItem('Import Date', cylinder.importDate!.toString().substring(0, 10)),
              if (cylinder.lastFilledDate != null)
                _buildDetailItem('Last Filled', cylinder.lastFilledDate!.toString().substring(0, 16)),
              if (cylinder.lastInspectionDate != null)
                _buildDetailItem('Last Inspection', cylinder.lastInspectionDate!.toString().substring(0, 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (hasFillerAccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showChangeStatusDialog(cylinder);
              },
              child: const Text('Change Status'),
            ),
          if (hasAdminOrManagerAccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(selectedCylinderProvider.notifier).state = cylinder;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CylinderFormScreen(cylinderId: cylinder.id),
                  ),
                ).then((_) => _loadCylinders());
              },
              child: const Text('Edit'),
            ),
          if (cylinder.qrCode.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showQRCodeDialog(cylinder);
              },
              child: const Text('Show QR'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(Cylinder cylinder) {
    String selectedStatus = cylinder.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Cylinder Status'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Status: ${cylinder.status}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'New Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final status in ['Empty', 'Full', 'Error', 'Maintenance'])
                      DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(cylindersProvider.notifier).updateCylinderStatus(
                      cylinder.id,
                      selectedStatus,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cylinder status updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _refreshCylinders();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showQRCodeDialog(Cylinder cylinder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code for ${cylinder.serialNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScanQRWidget(
              data: cylinder.qrCode,
              size: 200,
            ),
            const SizedBox(height: 16),
            Text(cylinder.qrCode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Create temporary variables to hold filter selections
    String? tempStatus = _selectedStatus;
    String? tempGasType = _selectedGasType;
    String? tempSize = _selectedSize;

    // Get unique values for filters
    final cylinders = ref.read(cylindersProvider).value ?? [];
    final sizes = <String>{};
    for (final cylinder in cylinders) {
      sizes.add(cylinder.size);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Cylinders'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: tempStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      for (final status in [
                        'Empty',
                        'Full',
                        'In Filling',
                        'In Inspection',
                        'Error',
                        'In Delivery',
                        'Maintenance'
                      ])
                        DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempGasType,
                    decoration: const InputDecoration(
                      labelText: 'Gas Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Gas Types'),
                      ),
                      for (final type in ['Medical', 'Industrial'])
                        DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempGasType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempSize,
                    decoration: const InputDecoration(
                      labelText: 'Size',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Sizes'),
                      ),
                      for (final size in sizes)
                        DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempSize = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedStatus = tempStatus;
                    _selectedGasType = tempGasType;
                    _selectedSize = tempSize;
                  });
                  _refreshCylinders();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
