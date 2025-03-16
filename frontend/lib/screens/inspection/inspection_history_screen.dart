import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/inspection.dart';
import '../../providers/cylinder_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../widgets/app_drawer.dart';

class InspectionHistoryScreen extends ConsumerStatefulWidget {
  const InspectionHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InspectionHistoryScreen> createState() => _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends ConsumerState<InspectionHistoryScreen> {
  String? _selectedResult;
  String? _selectedInspectorId;
  int? _selectedCylinderId;
  DateTimeRange? _dateRange;
  
  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    // Create filter map based on selected filters
    final Map<String, dynamic> filters = {
      'page': 1,
    };

    if (_selectedResult != null) {
      filters['result'] = _selectedResult;
    }

    if (_selectedInspectorId != null) {
      filters['inspectedById'] = _selectedInspectorId;
    }

    if (_selectedCylinderId != null) {
      filters['cylinderId'] = _selectedCylinderId.toString();
    }

    if (_dateRange != null) {
      filters['startDate'] = _dateRange!.start.toIso8601String();
      filters['endDate'] = _dateRange!.end.toIso8601String();
    }

    await ref.read(inspectionsProvider.notifier).getInspections(
      filters: filters,
    );
  }

  Future<void> _refreshInspections() async {
    ref.read(inspectionFilterProvider.notifier).state = {
      ...ref.read(inspectionFilterProvider),
      'page': 1,
    };
    await _loadInspections();
  }

  void _clearFilters() {
    setState(() {
      _selectedResult = null;
      _selectedInspectorId = null;
      _selectedCylinderId = null;
      _dateRange = null;
    });
    _refreshInspections();
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
      _refreshInspections();
    }
  }

  Future<void> _selectCylinder() async {
    // Show a dialog with a searchable list of cylinders
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const CylinderSearchDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedCylinderId = result;
      });
      _refreshInspections();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionsAsync = ref.watch(inspectionsProvider);
    final paginationInfo = ref.watch(inspectionPaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInspections,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Active filters display
          if (_selectedResult != null || _selectedCylinderId != null || _dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (_selectedResult != null)
                      Chip(
                        label: Text(_selectedResult!),
                        onDeleted: () {
                          setState(() {
                            _selectedResult = null;
                          });
                          _refreshInspections();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_selectedCylinderId != null)
                      Chip(
                        label: Text('Cylinder ID: $_selectedCylinderId'),
                        onDeleted: () {
                          setState(() {
                            _selectedCylinderId = null;
                          });
                          _refreshInspections();
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
                          _refreshInspections();
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
          
          // Inspections list
          Expanded(
            child: inspectionsAsync.when(
              data: (inspections) => _buildInspectionList(
                inspections,
                paginationInfo,
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
                      onPressed: _refreshInspections,
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

  Widget _buildInspectionList(
    List<Inspection> inspections,
    Map<String, dynamic> paginationInfo,
  ) {
    if (inspections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No inspection records found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (_selectedResult != null || _selectedCylinderId != null || _dateRange != null)
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
            onRefresh: _refreshInspections,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getResultColor(inspection.result),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Cylinder: ${inspection.cylinder?.serialNumber ?? 'Unknown'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${DateFormat('MM/dd/yy HH:mm').format(inspection.inspectionDate)}'),
                        Text('Inspector: ${inspection.inspectedBy?.name ?? 'Unknown'}'),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getResultColor(inspection.result).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                inspection.result,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getResultColor(inspection.result),
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
                            Text('Cylinder Type: ${inspection.cylinder?.gasType ?? 'Unknown'}'),
                            Text('Cylinder Size: ${inspection.cylinder?.size ?? 'Unknown'}'),
                            Text('Pressure Reading: ${inspection.pressureReading} bar'),
                            Text('Visual Inspection: ${inspection.visualInspection ? 'Passed' : 'Failed'}'),
                            if (inspection.notes != null && inspection.notes!.isNotEmpty)
                              Text('Notes: ${inspection.notes}'),
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
                          ref.read(inspectionFilterProvider.notifier).state = {
                            ...ref.read(inspectionFilterProvider),
                            'page': paginationInfo['currentPage'] - 1,
                          };
                          _loadInspections();
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
                          ref.read(inspectionFilterProvider.notifier).state = {
                            ...ref.read(inspectionFilterProvider),
                            'page': paginationInfo['currentPage'] + 1,
                          };
                          _loadInspections();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    // Create temporary variables to hold filter selections
    String? tempResult = _selectedResult;
    DateTimeRange? tempDateRange = _dateRange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Inspections'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: tempResult,
                    decoration: const InputDecoration(
                      labelText: 'Result',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Results'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Approved',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempResult = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Close the dialog temporarily
                      Navigator.pop(context);
                      // Show cylinder search
                      await _selectCylinder();
                      // Reopen the dialog
                      if (mounted) {
                        _showFilterDialog();
                      }
                    },
                    child: Text(_selectedCylinderId == null
                        ? 'Select Cylinder'
                        : 'Cylinder ID: $_selectedCylinderId'),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      // Close the dialog temporarily
                      Navigator.pop(context);
                      // Show date picker
                      await _selectDateRange();
                      // Reopen the dialog
                      if (mounted) {
                        _showFilterDialog();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateRange == null
                            ? 'Select date range'
                            : '${DateFormat('MM/dd/yy').format(_dateRange!.start)} - '
                              '${DateFormat('MM/dd/yy').format(_dateRange!.end)}',
                      ),
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
                    _selectedResult = tempResult;
                  });
                  _refreshInspections();
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

// CylinderSearchDialog for selecting cylinders
class CylinderSearchDialog extends ConsumerStatefulWidget {
  const CylinderSearchDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<CylinderSearchDialog> createState() => _CylinderSearchDialogState();
}

class _CylinderSearchDialogState extends ConsumerState<CylinderSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

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
    setState(() {
      _isSearching = true;
    });

    try {
      await ref.read(cylindersProvider.notifier).getCylinders(
        filters: {
          'search': _searchQuery.isEmpty ? null : _searchQuery,
          'page': 1,
          'limit': 50,
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
          _isSearching = false;
        });
      }
    }
  }

  void _searchCylinders() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _loadCylinders();
  }

  @override
  Widget build(BuildContext context) {
    final cylindersAsync = ref.watch(cylindersProvider);

    return AlertDialog(
      title: const Text('Select Cylinder'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by serial number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadCylinders();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchCylinders(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _searchCylinders,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            
            // Cylinders list
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : cylindersAsync.when(
                      data: (cylinders) {
                        if (cylinders.isEmpty) {
                          return const Center(
                            child: Text('No cylinders found'),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: cylinders.length,
                          itemBuilder: (context, index) {
                            final cylinder = cylinders[index];
                            return ListTile(
                              title: Text(cylinder.serialNumber),
                              subtitle: Text(
                                '${cylinder.gasType}, ${cylinder.size}, ${cylinder.status}',
                              ),
                              onTap: () {
                                Navigator.pop(context, cylinder.id);
                              },
                            );
                          },
                        );
                      },
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Import missing packages
import 'package:intl/intl.dart';
