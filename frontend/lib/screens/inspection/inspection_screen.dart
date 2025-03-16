import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/cylinder.dart';
import '../../models/inspection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/cylinder_card.dart';
import '../../widgets/qr_scanner.dart';
import 'inspection_detail_screen.dart';

class InspectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? args;

  const InspectionScreen({Key? key, this.args}) : super(key: key);

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  
  bool _isLoading = false;
  InspectionResult? _resultFilter;
  List<Cylinder> _selectedCylinders = [];
  bool _batchMode = false;
  bool _showActive = true;
  List<Inspection> _recentInspections = [];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspectionProvider.notifier).fetchInspections();
      
      // If cylinder already provided in args
      if (widget.args != null && widget.args!.containsKey('cylinderId')) {
        _loadInitialCylinder(widget.args!['cylinderId']);
      }
    });
  }

  Future<void> _loadInitialCylinder(int cylinderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cylinder = await ref.read(cylinderProvider.notifier).getCylinderById(cylinderId);
      if (cylinder != null) {
        setState(() {
          _selectedCylinders = [cylinder];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cylinder: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchCylinder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_searchController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a serial number')),
        );
        return;
      }

      final List<Cylinder> cylinders = await ref.read(cylinderProvider.notifier).fetchCylinders(
        status: 'Empty', // Only get empty cylinders for inspection
      );
      
      final List<Cylinder> matchedCylinders = cylinders.where(
        (c) => c.serialNumber.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();

      if (matchedCylinders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching cylinders found')),
        );
        return;
      }

      if (matchedCylinders.length == 1) {
        // Single match, add to selection
        _addCylinder(matchedCylinders[0]);
      } else {
        // Multiple matches, show selection dialog
        _showCylinderSelectionDialog(matchedCylinders);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scanCylinder() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cylinder = await ref.read(cylinderProvider.notifier).getCylinderByQRCode(result);
        
        if (cylinder == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cylinder found with this QR code')),
          );
          return;
        }

        if (cylinder.status != CylinderStatus.Empty && cylinder.status != CylinderStatus.InInspection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cylinder is not eligible for inspection. Current status: ${cylinder.status.toString().split('.').last}'
              ),
            ),
          );
          return;
        }

        _addCylinder(cylinder);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addCylinder(Cylinder cylinder) {
    // Check if already selected
    if (_selectedCylinders.any((c) => c.id == cylinder.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cylinder already selected')),
      );
      return;
    }

    // Add to selection
    setState(() {
      _selectedCylinders.add(cylinder);
    });
  }

  void _removeCylinder(int index) {
    setState(() {
      _selectedCylinders.removeAt(index);
    });
  }

  void _showCylinderSelectionDialog(List<Cylinder> cylinders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Multiple Cylinders Found'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cylinders.length,
            itemBuilder: (context, index) {
              final cylinder = cylinders[index];
              return ListTile(
                title: Text(cylinder.serialNumber),
                subtitle: Text('Size: ${cylinder.size}'),
                trailing: Text(
                  cylinder.gasType == GasType.Medical ? 'Medical' : 'Industrial',
                  style: TextStyle(
                    color: cylinder.gasType == GasType.Medical ? Colors.blue : Colors.green,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addCylinder(cylinder);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAllCylinders() async {
    if (_selectedCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cylinders selected')),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
          'Are you sure you want to approve all ${_selectedCylinders.length} selected cylinders?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate next inspection date (1 year from now)
      final nextInspectionDate = DateTime.now().add(const Duration(days: 365));
      
      final batchData = {
        'cylinderIds': _selectedCylinders.map((c) => c.id).toList(),
        'nextInspectionDate': nextInspectionDate.toIso8601String(),
        'notes': 'Batch approved on ${_dateFormat.format(DateTime.now())}',
      };

      final success = await ref.read(inspectionProvider.notifier).batchApproveInspections(batchData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cylinders approved successfully')),
        );
        
        // Refresh inspections list and clear selection
        ref.read(inspectionProvider.notifier).fetchInspections();
        setState(() {
          _selectedCylinders = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _inspectCylinder(Cylinder cylinder) async {
    final inspection = await Navigator.push<Inspection>(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionDetailScreen(cylinder: cylinder),
      ),
    );

    if (inspection != null) {
      // Refresh inspections
      ref.read(inspectionProvider.notifier).fetchInspections();
      
      // Remove cylinder from selected list
      setState(() {
        _selectedCylinders.removeWhere((c) => c.id == cylinder.id);
      });
    }
  }

  void _showRecentInspections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inspections = await ref.read(inspectionProvider.notifier).fetchInspections();
      
      setState(() {
        _recentInspections = inspections.take(10).toList(); // Get most recent 10
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recent Inspections'),
          content: SizedBox(
            width: double.maxFinite,
            child: _recentInspections.isEmpty
                ? const Center(
                    child: Text('No recent inspections found'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _recentInspections.length,
                    itemBuilder: (context, index) {
                      final inspection = _recentInspections[index];
                      return ListTile(
                        title: Text('Cylinder: ${inspection.cylinder?.serialNumber ?? 'Unknown'}'),
                        subtitle: Text(
                          'Date: ${_dateFormat.format(inspection.inspectionDate)}'
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getResultColor(inspection.result).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            inspection.resultText,
                            style: TextStyle(
                              color: _getResultColor(inspection.result),
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspectionDetailScreen.fromInspection(
                                inspection: inspection,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final bool canInspectCylinders = currentUser?.isAdmin == true || 
                                   currentUser?.isManager == true || 
                                   currentUser?.isFiller == true;
    final inspectionState = ref.watch(inspectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cylinder Inspection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showRecentInspections,
            tooltip: 'Recent Inspections',
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() {
              _batchMode = !_batchMode;
            }),
            tooltip: _batchMode ? 'Switch to Individual Mode' : 'Switch to Batch Mode',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and scan
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by serial number',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              onSubmitted: (_) => _searchCylinder(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: canInspectCylinders ? _scanCylinder : null,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _batchMode
                                ? 'Batch Inspection Mode'
                                : 'Individual Inspection Mode',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Selected: ${_selectedCylinders.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Batch actions bar in batch mode
                if (_batchMode && _selectedCylinders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: canInspectCylinders ? _approveAllCylinders : null,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCylinders = [];
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear All'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Selected cylinders list
                Expanded(
                  child: _selectedCylinders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No cylinders selected for inspection',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search by serial number or scan QR code',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _selectedCylinders.length,
                          itemBuilder: (context, index) {
                            final cylinder = _selectedCylinders[index];
                            return Stack(
                              children: [
                                CylinderCard(
                                  cylinder: cylinder,
                                  onTap: !_batchMode && canInspectCylinders
                                      ? () => _inspectCylinder(cylinder)
                                      : null,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 16,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close, size: 16),
                                      color: Colors.white,
                                      onPressed: () => _removeCylinder(index),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _selectedCylinders.isEmpty || _batchMode || !canInspectCylinders
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: () => _inspectCylinder(_selectedCylinders[0]),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text(
                    'Inspect Cylinder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  Color _getResultColor(InspectionResult result) {
    switch (result) {
      case InspectionResult.Approved:
        return Colors.green;
      case InspectionResult.Rejected:
        return Colors.red;
      case InspectionResult.Pending:
      default:
        return Colors.amber;
    }
  }
}
