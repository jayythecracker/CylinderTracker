import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cylinder.dart';
import '../../models/inspection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../services/qr_scanner_service.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import 'inspection_history_screen.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  final List<Cylinder> _selectedCylinders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<int, bool> _cylinderSelectionMap = {};
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadCylinders();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCylinders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load cylinders that need inspection
      // Either full or empty cylinders are eligible for inspection
      await ref.read(cylindersProvider.notifier).getCylinders(
        filters: {
          'status': 'Full,Empty', // Multiple values separated by comma
          'search': _searchQuery.isEmpty ? null : _searchQuery,
          'page': 1,
          'limit': 50
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cylinders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleCylinderSelection(Cylinder cylinder) {
    setState(() {
      final isSelected = _cylinderSelectionMap[cylinder.id] ?? false;
      _cylinderSelectionMap[cylinder.id] = !isSelected;
      
      if (!isSelected) {
        _selectedCylinders.add(cylinder);
      } else {
        _selectedCylinders.removeWhere((c) => c.id == cylinder.id);
      }
    });
  }
  
  void _selectAllCylinders() {
    final cylinders = ref.read(cylindersProvider).value ?? [];
    setState(() {
      for (final cylinder in cylinders) {
        _cylinderSelectionMap[cylinder.id] = true;
      }
      _selectedCylinders.clear();
      _selectedCylinders.addAll(cylinders);
    });
  }
  
  void _deselectAllCylinders() {
    setState(() {
      _cylinderSelectionMap.clear();
      _selectedCylinders.clear();
    });
  }
  
  Future<void> _refreshCylinders() async {
    await _loadCylinders();
  }
  
  Future<void> _searchCylinders() async {
    setState(() {
      _searchQuery = _searchController.text;
    });
    await _loadCylinders();
  }
  
  Future<void> _scanQRCode() async {
    try {
      final qrScannerService = QRScannerService();
      final scannedCode = await QRScannerService.scanQRCodeFullScreen(context);
      
      if (scannedCode != null) {
        try {
          final cylinder = await qrScannerService.getCylinderByQRCode(scannedCode);
          if (mounted) {
            if (cylinder.status == 'Full' || cylinder.status == 'Empty') {
              _showInspectionDialog(cylinder);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'This cylinder (${cylinder.serialNumber}) is not eligible for inspection. Status: ${cylinder.status}',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
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
    
    // Check if user has filler access for performing inspections
    final hasFillerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'filler'],
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cylinder Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Inspection History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InspectionHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: _scanQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCylinders,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: hasFillerAccess && _selectedCylinders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBatchInspectionDialog,
              icon: const Icon(Icons.check_circle),
              label: Text('Inspect ${_selectedCylinders.length}'),
              backgroundColor: Colors.green,
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search cylinders',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _loadCylinders();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchCylinders(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchCylinders,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Selection controls
          if (hasFillerAccess)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Selected: ${_selectedCylinders.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selectAllCylinders,
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: _deselectAllCylinders,
                    child: const Text('Deselect All'),
                  ),
                ],
              ),
            ),
          
          // Cylinders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : cylindersAsync.when(
                    data: (cylinders) {
                      if (cylinders.isEmpty) {
                        return const Center(
                          child: Text('No cylinders found for inspection'),
                        );
                      }
                      
                      return RefreshIndicator(
                        onRefresh: _refreshCylinders,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: cylinders.length,
                          itemBuilder: (context, index) {
                            final cylinder = cylinders[index];
                            final isSelected = _cylinderSelectionMap[cylinder.id] ?? false;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: hasFillerAccess
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => _toggleCylinderSelection(cylinder),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: _getStatusColor(cylinder.status),
                                        child: const Icon(Icons.propane_tank, color: Colors.white),
                                      ),
                                title: Text(
                                  'SN: ${cylinder.serialNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: ${cylinder.status}'),
                                    Text('Type: ${cylinder.gasType}, Size: ${cylinder.size}'),
                                    if (cylinder.lastInspectionDate != null)
                                      Text(
                                        'Last Inspection: ${_formatDate(cylinder.lastInspectionDate!)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: hasFillerAccess
                                    ? IconButton(
                                        icon: const Icon(Icons.check_circle),
                                        color: Colors.green,
                                        onPressed: () => _showInspectionDialog(cylinder),
                                      )
                                    : null,
                                onTap: hasFillerAccess
                                    ? () => _toggleCylinderSelection(cylinder)
                                    : null,
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${error.toString()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshCylinders,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Empty':
        return Colors.grey;
      case 'Full':
        return Colors.green;
      case 'Error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
  
  void _showInspectionDialog(Cylinder cylinder) {
    final _formKey = GlobalKey<FormState>();
    final _pressureController = TextEditingController(
      text: cylinder.status == 'Full' ? cylinder.workingPressure.toString() : '0',
    );
    bool _visualInspection = true;
    String _result = 'Approved';
    final _notesController = TextEditingController();
    bool _isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Inspect Cylinder: ${cylinder.serialNumber}'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cylinder info
                    Text('Status: ${cylinder.status}'),
                    Text('Gas Type: ${cylinder.gasType}'),
                    Text('Size: ${cylinder.size}'),
                    if (cylinder.lastInspectionDate != null)
                      Text('Last Inspection: ${_formatDate(cylinder.lastInspectionDate!)}'),
                    const Divider(),
                    
                    // Pressure reading
                    TextFormField(
                      controller: _pressureController,
                      decoration: const InputDecoration(
                        labelText: 'Pressure Reading (bar)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pressure reading';
                        }
                        final pressure = double.tryParse(value);
                        if (pressure == null || pressure < 0) {
                          return 'Please enter a valid pressure';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Visual inspection
                    SwitchListTile(
                      title: const Text('Visual Inspection Passed'),
                      value: _visualInspection,
                      onChanged: (value) {
                        setState(() {
                          _visualInspection = value;
                          // If visual inspection fails, auto set result to Rejected
                          if (!value) {
                            _result = 'Rejected';
                          }
                        });
                      },
                    ),
                    
                    // Inspection result
                    const SizedBox(height: 8),
                    const Text(
                      'Inspection Result:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('Approved'),
                      value: 'Approved',
                      groupValue: _result,
                      onChanged: (value) {
                        setState(() {
                          _result = value!;
                          // If approving, ensure visual inspection is passed
                          if (value == 'Approved') {
                            _visualInspection = true;
                          }
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Rejected'),
                      value: 'Rejected',
                      groupValue: _result,
                      onChanged: (value) {
                        setState(() {
                          _result = value!;
                        });
                      },
                    ),
                    
                    // Notes
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSubmitting = true;
                          });
                          
                          try {
                            // Create inspection object
                            final inspection = Inspection(
                              id: 0,
                              inspectionDate: DateTime.now(),
                              cylinderId: cylinder.id,
                              inspectedById: 0, // Will be set by server from token
                              pressureReading: double.parse(_pressureController.text),
                              visualInspection: _visualInspection,
                              result: _result,
                              notes: _notesController.text.isEmpty ? null : _notesController.text,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            
                            // Submit inspection
                            await ref.read(inspectionsProvider.notifier).createInspection(inspection);
                            
                            if (mounted) {
                              Navigator.pop(context);
                              _refreshCylinders();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Inspection saved successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              _isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save inspection: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Inspection'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showBatchInspectionDialog() {
    if (_selectedCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cylinder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final _formKey = GlobalKey<FormState>();
    String _result = 'Approved';
    final _notesController = TextEditingController();
    bool _isSubmitting = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Batch Inspection - ${_selectedCylinders.length} Cylinders'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Cylinders: ${_selectedCylinders.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    // List selected cylinders
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 150,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _selectedCylinders.length,
                        itemBuilder: (context, index) {
                          final cylinder = _selectedCylinders[index];
                          return ListTile(
                            dense: true,
                            title: Text(cylinder.serialNumber),
                            subtitle: Text('${cylinder.gasType}, ${cylinder.status}'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Inspection result
                    const Text(
                      'Inspection Result for All Selected:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('Approve All'),
                      value: 'Approved',
                      groupValue: _result,
                      onChanged: (value) {
                        setState(() {
                          _result = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Reject All'),
                      value: 'Rejected',
                      groupValue: _result,
                      onChanged: (value) {
                        setState(() {
                          _result = value!;
                        });
                      },
                    ),
                    
                    // Notes
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSubmitting = true;
                          });
                          
                          try {
                            // Get cylinder IDs
                            final cylinderIds = _selectedCylinders.map((c) => c.id).toList();
                            
                            // Submit batch inspection
                            await ref.read(inspectionsProvider.notifier).batchInspect(
                              cylinderIds,
                              _result,
                              _notesController.text.isEmpty ? null : _notesController.text,
                            );
                            
                            if (mounted) {
                              Navigator.pop(context);
                              _deselectAllCylinders();
                              _refreshCylinders();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Batch inspection completed successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              _isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to complete batch inspection: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Complete Batch Inspection'),
              ),
            ],
          );
        },
      ),
    );
  }
}
