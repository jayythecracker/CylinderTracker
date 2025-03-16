import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/filling.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filling_provider.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import 'complete_filling_batch_screen.dart';

class FillingHistoryScreen extends ConsumerStatefulWidget {
  const FillingHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FillingHistoryScreen> createState() => _FillingHistoryScreenState();
}

class _FillingHistoryScreenState extends ConsumerState<FillingHistoryScreen> {
  String? _selectedStatus;
  String? _selectedFillingLineId;
  DateTimeRange? _dateRange;
  
  @override
  void initState() {
    super.initState();
    _loadFillingBatches();
  }

  Future<void> _loadFillingBatches() async {
    // Create filter map based on selected filters
    final Map<String, dynamic> filters = {
      'page': 1,
    };

    if (_selectedStatus != null) {
      filters['status'] = _selectedStatus;
    }

    if (_selectedFillingLineId != null) {
      filters['fillingLineId'] = _selectedFillingLineId;
    }

    if (_dateRange != null) {
      filters['startDate'] = _dateRange!.start.toIso8601String();
      filters['endDate'] = _dateRange!.end.toIso8601String();
    }

    await ref.read(fillingBatchesProvider.notifier).getFillingBatches(
      filters: filters,
    );
  }

  Future<void> _refreshBatches() async {
    ref.read(fillingBatchFilterProvider.notifier).state = {
      ...ref.read(fillingBatchFilterProvider),
      'page': 1,
    };
    await _loadFillingBatches();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedFillingLineId = null;
      _dateRange = null;
    });
    _refreshBatches();
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
    
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _dateRange = newDateRange;
      });
      _refreshBatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final fillingBatchesAsync = ref.watch(fillingBatchesProvider);
    final paginationInfo = ref.watch(fillingBatchPaginationProvider);
    final fillingLinesAsync = ref.watch(fillingLinesProvider);
    
    // Check if user has access to complete filling batches
    final hasFillerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'filler'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filling History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(fillingLinesAsync.value ?? []),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBatches,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Active filters display
          if (_selectedStatus != null || _selectedFillingLineId != null || _dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (_selectedStatus != null)
                      Chip(
                        label: Text(_selectedStatus!),
                        onDeleted: () {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _refreshBatches();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_selectedFillingLineId != null)
                      Chip(
                        label: Text('Line: $_selectedFillingLineId'),
                        onDeleted: () {
                          setState(() {
                            _selectedFillingLineId = null;
                          });
                          _refreshBatches();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_dateRange != null)
                      Chip(
                        label: Text(
                          '${DateFormat('MM/dd/yy').format(_dateRange!.start)} - '
                          '${DateFormat('MM/dd/yy').format(_dateRange!.end)}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _dateRange = null;
                          });
                          _refreshBatches();
                        },
                      ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Filling batches list
          Expanded(
            child: fillingBatchesAsync.when(
              data: (batches) => _buildBatchList(
                batches,
                paginationInfo,
                hasFillerAccess,
              ),
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
                      onPressed: _refreshBatches,
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

  Widget _buildBatchList(
    List<FillingBatch> batches,
    Map<String, dynamic> paginationInfo,
    bool hasFillerAccess,
  ) {
    if (batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No filling batches found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (_selectedStatus != null || _selectedFillingLineId != null || _dateRange != null)
              ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshBatches,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: batches.length,
              itemBuilder: (context, index) {
                final batch = batches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(batch.status),
                      child: const Icon(
                        Icons.science,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Batch: ${batch.batchNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Line: ${batch.fillingLine?.name ?? 'Unknown'}'),
                        Text('Started: ${DateFormat('MM/dd/yy HH:mm').format(batch.startTime)}'),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(batch.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                batch.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(batch.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Text('Started By: ${batch.startedBy?.name ?? 'Unknown'}'),
                            if (batch.endedBy != null)
                              Text('Ended By: ${batch.endedBy?.name ?? 'N/A'}'),
                            if (batch.endTime != null)
                              Text('End Time: ${DateFormat('MM/dd/yy HH:mm').format(batch.endTime!)}'),
                            if (batch.notes != null && batch.notes!.isNotEmpty)
                              Text('Notes: ${batch.notes}'),
                            const SizedBox(height: 16),
                            if (batch.status == 'In Progress' && hasFillerAccess)
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CompleteFillingBatchScreen(
                                          batchId: batch.id,
                                        ),
                                      ),
                                    ).then((_) => _refreshBatches());
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Complete Batch'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            const Text(
                              'Cylinders:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (batch.details == null || batch.details!.isEmpty)
                              const Text('No cylinder details available')
                            else
                              ...batch.details!.map((detail) {
                                final cylinder = detail.cylinder;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.propane_tank,
                                    color: _getDetailStatusColor(detail.status),
                                  ),
                                  title: Text('SN: ${cylinder?.serialNumber ?? 'Unknown'}'),
                                  subtitle: Text(
                                    'Status: ${detail.status}, ${cylinder?.size ?? 'Unknown'} ${cylinder?.gasType ?? 'Unknown'}',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Initial: ${detail.initialPressure} bar'),
                                      if (detail.finalPressure != null)
                                        Text('Final: ${detail.finalPressure} bar'),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ],
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
                          ref.read(fillingBatchFilterProvider.notifier).state = {
                            ...ref.read(fillingBatchFilterProvider),
                            'page': paginationInfo['currentPage'] - 1,
                          };
                          _loadFillingBatches();
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
                          ref.read(fillingBatchFilterProvider.notifier).state = {
                            ...ref.read(fillingBatchFilterProvider),
                            'page': paginationInfo['currentPage'] + 1,
                          };
                          _loadFillingBatches();
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
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDetailStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'In Progress':
        return Colors.blue;
      case 'Success':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog(List<FillingLine> fillingLines) {
    // Create temporary variables to hold filter selections
    String? tempStatus = _selectedStatus;
    String? tempFillingLineId = _selectedFillingLineId;
    DateTimeRange? tempDateRange = _dateRange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Filling Batches'),
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
                      for (final status in ['In Progress', 'Completed', 'Failed'])
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
                    value: tempFillingLineId,
                    decoration: const InputDecoration(
                      labelText: 'Filling Line',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Filling Lines'),
                      ),
                      for (final line in fillingLines)
                        DropdownMenuItem(
                          value: line.id.toString(),
                          child: Text(line.name),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempFillingLineId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final initialDateRange = tempDateRange ?? DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      );
                      
                      final newDateRange = await showDateRangePicker(
                        context: context,
                        initialDateRange: initialDateRange,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (newDateRange != null) {
                        setDialogState(() {
                          tempDateRange = newDateRange;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        tempDateRange == null
                            ? 'Select date range'
                            : '${DateFormat('MM/dd/yy').format(tempDateRange!.start)} - '
                              '${DateFormat('MM/dd/yy').format(tempDateRange!.end)}',
                      ),
                    ),
                  ),
                  if (tempDateRange != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempDateRange = null;
                          });
                        },
                        child: const Text('Clear Dates'),
                      ),
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
                    _selectedFillingLineId = tempFillingLineId;
                    _dateRange = tempDateRange;
                  });
                  _refreshBatches();
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

// CompleteFillingBatchScreen implementation
class CompleteFillingBatchScreen extends ConsumerStatefulWidget {
  final int batchId;

  const CompleteFillingBatchScreen({
    Key? key,
    required this.batchId,
  }) : super(key: key);

  @override
  ConsumerState<CompleteFillingBatchScreen> createState() => _CompleteFillingBatchScreenState();
}

class _CompleteFillingBatchScreenState extends ConsumerState<CompleteFillingBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  FillingBatch? _batch;
  List<Map<String, dynamic>> _cylinderResults = [];

  @override
  void initState() {
    super.initState();
    _loadBatchDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBatchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load batch details
      final batch = await ref.read(fillingBatchesProvider.notifier).getFillingBatchById(widget.batchId);
      
      // Initialize cylinder results
      final cylinderResults = batch.details?.map((detail) {
        return {
          'cylinderId': detail.cylinderId,
          'cylinderSerial': detail.cylinder?.serialNumber ?? 'Unknown',
          'initialPressure': detail.initialPressure,
          'finalPressure': detail.cylinder?.workingPressure ?? 0.0,
          'status': 'Success', // Default to success
          'notes': '',
        };
      }).toList() ?? [];

      setState(() {
        _batch = batch;
        _cylinderResults = cylinderResults;
        _notesController.text = batch.notes ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load batch details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create filling details from cylinder results
      final fillingDetails = _cylinderResults.map((result) {
        return FillingDetail(
          id: 0, // ID will be ignored for update
          fillingBatchId: widget.batchId,
          cylinderId: result['cylinderId'],
          initialPressure: result['initialPressure'],
          finalPressure: result['finalPressure'],
          status: result['status'],
          notes: result['notes'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      // Complete the batch
      await ref.read(fillingBatchesProvider.notifier).completeFillingBatch(
        widget.batchId,
        fillingDetails,
        _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filling batch completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete batch: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updateCylinderStatus(int index, String status) {
    setState(() {
      _cylinderResults[index]['status'] = status;
    });
  }

  void _updateCylinderPressure(int index, double pressure) {
    setState(() {
      _cylinderResults[index]['finalPressure'] = pressure;
    });
  }

  void _updateCylinderNotes(int index, String notes) {
    setState(() {
      _cylinderResults[index]['notes'] = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Filling - ${_batch?.batchNumber ?? ''}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch info card
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch: ${_batch?.batchNumber ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Filling Line: ${_batch?.fillingLine?.name ?? 'Unknown'}'),
                          Text('Started: ${DateFormat('MM/dd/yy HH:mm').format(_batch?.startTime ?? DateTime.now())}'),
                          Text('Cylinders: ${_cylinderResults.length}'),
                        ],
                      ),
                    ),
                  ),
                  
                  // Notes field
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  
                  // Cylinders results header
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cylinder Results:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _completeBatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Complete Filling'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cylinder results list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cylinderResults.length,
                      itemBuilder: (context, index) {
                        final result = _cylinderResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(result['status']),
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              'SN: ${result['cylinderSerial']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Initial Pressure: ${result['initialPressure']} bar'),
                                Text('Final Pressure: ${result['finalPressure']} bar'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(result['status']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    result['status'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(result['status']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: result['status'],
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Success',
                                          child: Text('Success'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Failed',
                                          child: Text('Failed'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          _updateCylinderStatus(index, value);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: result['finalPressure'].toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'Final Pressure (bar)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter final pressure';
                                        }
                                        final pressure = double.tryParse(value);
                                        if (pressure == null || pressure < 0) {
                                          return 'Please enter a valid pressure';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        final pressure = double.tryParse(value);
                                        if (pressure != null) {
                                          _updateCylinderPressure(index, pressure);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: result['notes'],
                                      decoration: const InputDecoration(
                                        labelText: 'Notes (Optional)',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                      onChanged: (value) {
                                        _updateCylinderNotes(index, value);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Success':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/filling.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filling_provider.dart';
import '../../providers/api_service.dart';
