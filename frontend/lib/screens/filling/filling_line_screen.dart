import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/filling.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filling_provider.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import 'filling_history_screen.dart';
import 'filling_line_form_dialog.dart';
import 'start_filling_batch_screen.dart';

class FillingLineScreen extends ConsumerStatefulWidget {
  const FillingLineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FillingLineScreen> createState() => _FillingLineScreenState();
}

class _FillingLineScreenState extends ConsumerState<FillingLineScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFillingLines();
  }

  Future<void> _loadFillingLines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(fillingLinesProvider.notifier).getFillingLines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load filling lines: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final fillingLinesAsync = ref.watch(fillingLinesProvider);

    // Check if user has admin/manager access for creating filling lines
    final hasAdminOrManagerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager'],
    );

    // Check if user has filler access for starting filling batches
    final hasFillerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'filler'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filling Lines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Filling History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FillingHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFillingLines,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: hasAdminOrManagerAccess
          ? FloatingActionButton(
              onPressed: () {
                _showFillingLineFormDialog(context);
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : fillingLinesAsync.when(
              data: (fillingLines) => _buildFillingLineList(
                fillingLines, 
                hasAdminOrManagerAccess, 
                hasFillerAccess
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
                      onPressed: _loadFillingLines,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFillingLineList(
    List<FillingLine> fillingLines,
    bool hasAdminOrManagerAccess,
    bool hasFillerAccess,
  ) {
    if (fillingLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_gas_station_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No filling lines available',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (hasAdminOrManagerAccess)
              ElevatedButton(
                onPressed: () {
                  _showFillingLineFormDialog(context);
                },
                child: const Text('Add Filling Line'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFillingLines,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: fillingLines.length,
        itemBuilder: (context, index) {
          final fillingLine = fillingLines[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(fillingLine.status),
                child: const Icon(
                  Icons.local_gas_station,
                  color: Colors.white,
                ),
              ),
              title: Text(
                fillingLine.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gas Type: ${fillingLine.gasType}'),
                  Text('Capacity: ${fillingLine.capacity} cylinders'),
                  Text('Status: ${fillingLine.status}'),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (hasFillerAccess && fillingLine.status == 'Idle')
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StartFillingBatchScreen(
                                      fillingLine: fillingLine,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Filling'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          if (hasAdminOrManagerAccess)
                            ElevatedButton.icon(
                              onPressed: () {
                                _showFillingLineFormDialog(context, fillingLine);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          if (hasAdminOrManagerAccess && fillingLine.status != 'Active')
                            ElevatedButton.icon(
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, fillingLine);
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Idle':
        return Colors.green;
      case 'Active':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showFillingLineFormDialog(BuildContext context, [FillingLine? fillingLine]) {
    showDialog(
      context: context,
      builder: (context) => FillingLineFormDialog(fillingLine: fillingLine),
    ).then((_) => _loadFillingLines());
  }

  void _showDeleteConfirmationDialog(BuildContext context, FillingLine fillingLine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Filling Line'),
        content: Text(
          'Are you sure you want to delete the filling line "${fillingLine.name}"?'
          ' This action cannot be undone.',
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
                await ref.read(fillingLinesProvider.notifier).deleteFillingLine(fillingLine.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filling line deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadFillingLines();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete filling line: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// FillingLineFormDialog implementation
class FillingLineFormDialog extends StatefulWidget {
  final FillingLine? fillingLine;

  const FillingLineFormDialog({Key? key, this.fillingLine}) : super(key: key);

  @override
  State<FillingLineFormDialog> createState() => _FillingLineFormDialogState();
}

class _FillingLineFormDialogState extends State<FillingLineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  String _gasType = 'Industrial';
  String _status = 'Idle';
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.fillingLine != null;

    if (_isEditMode) {
      _nameController.text = widget.fillingLine!.name;
      _capacityController.text = widget.fillingLine!.capacity.toString();
      _gasType = widget.fillingLine!.gasType;
      _status = widget.fillingLine!.status;
    } else {
      _capacityController.text = '10'; // Default capacity
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? 'Edit Filling Line' : 'Add Filling Line'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity (cylinders)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gasType,
                decoration: const InputDecoration(
                  labelText: 'Gas Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Medical',
                    child: Text('Medical'),
                  ),
                  DropdownMenuItem(
                    value: 'Industrial',
                    child: Text('Industrial'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gasType = value;
                    });
                  }
                },
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Idle',
                      child: Text('Idle'),
                    ),
                    DropdownMenuItem(
                      value: 'Maintenance',
                      child: Text('Maintenance'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _status = value;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, _) {
            return TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final fillingLine = FillingLine(
                            id: _isEditMode ? widget.fillingLine!.id : 0,
                            name: _nameController.text,
                            capacity: int.parse(_capacityController.text),
                            gasType: _gasType,
                            status: _status,
                            isActive: true,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          if (_isEditMode) {
                            await ref.read(fillingLinesProvider.notifier).updateFillingLine(
                                  widget.fillingLine!.id,
                                  fillingLine,
                                );
                          } else {
                            await ref.read(fillingLinesProvider.notifier).createFillingLine(
                                  fillingLine,
                                );
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isEditMode
                                      ? 'Filling line updated successfully'
                                      : 'Filling line added successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save filling line: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Update' : 'Add'),
            );
          },
        ),
      ],
    );
  }
}

// StartFillingBatchScreen implementation
class StartFillingBatchScreen extends ConsumerStatefulWidget {
  final FillingLine fillingLine;

  const StartFillingBatchScreen({
    Key? key,
    required this.fillingLine,
  }) : super(key: key);

  @override
  ConsumerState<StartFillingBatchScreen> createState() => _StartFillingBatchScreenState();
}

class _StartFillingBatchScreenState extends ConsumerState<StartFillingBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _selectedCylinders = <int>[];
  bool _isLoading = false;
  bool _isLoadingCylinders = true;
  List<Map<String, dynamic>> _availableCylinders = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCylinders();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCylinders() async {
    setState(() {
      _isLoadingCylinders = true;
    });

    try {
      // Get cylinders that are empty and match the filling line's gas type
      final response = await ref.read(apiServiceProvider).get(
        '${AppConfig.cylindersEndpoint}',
        queryParams: {
          'status': 'Empty',
          'gasType': widget.fillingLine.gasType,
        },
      );

      final cylinders = (response['cylinders'] as List)
          .map((cylinder) => {
                'id': cylinder['id'],
                'serialNumber': cylinder['serialNumber'],
                'gasType': cylinder['gasType'],
                'size': cylinder['size'],
                'selected': false,
              })
          .toList();

      setState(() {
        _availableCylinders = cylinders;
        _isLoadingCylinders = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load available cylinders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingCylinders = false;
        });
      }
    }
  }

  Future<void> _startFillingBatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cylinder'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if we're not exceeding the filling line capacity
    if (_selectedCylinders.length > widget.fillingLine.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You cannot select more than ${widget.fillingLine.capacity} cylinders for this filling line',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a batch object to start the filling process
      final batch = FillingBatch(
        id: 0,
        batchNumber: '',
        startTime: DateTime.now(),
        status: 'In Progress',
        fillingLineId: widget.fillingLine.id,
        startedById: 0, // This will be set by the server based on the token
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: _notesController.text,
        // We'll build the details here to include the cylinder IDs
        details: _selectedCylinders.map((cylinderId) {
          return FillingDetail(
            id: 0,
            fillingBatchId: 0,
            cylinderId: cylinderId,
            initialPressure: 0,
            status: 'Pending',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList(),
      );

      await ref.read(fillingBatchesProvider.notifier).startFillingBatch(batch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filling batch started successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        // Navigate to filling history screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FillingHistoryScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start filling batch: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleCylinderSelection(int index) {
    setState(() {
      _availableCylinders[index]['selected'] = !_availableCylinders[index]['selected'];
      
      final cylinderId = _availableCylinders[index]['id'];
      if (_availableCylinders[index]['selected']) {
        _selectedCylinders.add(cylinderId);
      } else {
        _selectedCylinders.remove(cylinderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Filling - ${widget.fillingLine.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filling line info card
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filling Line: ${widget.fillingLine.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Gas Type: ${widget.fillingLine.gasType}'),
                          Text('Capacity: ${widget.fillingLine.capacity} cylinders'),
                          Text('Selected: ${_selectedCylinders.length} cylinders'),
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
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  
                  // Select cylinders header
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Cylinders:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _startFillingBatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Start Filling'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cylinder selection list
                  Expanded(
                    child: _isLoadingCylinders
                        ? const Center(child: CircularProgressIndicator())
                        : _availableCylinders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No empty cylinders available for this gas type',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _availableCylinders.length,
                                itemBuilder: (context, index) {
                                  final cylinder = _availableCylinders[index];
                                  return CheckboxListTile(
                                    title: Text(
                                      'SN: ${cylinder['serialNumber']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Type: ${cylinder['gasType']}, Size: ${cylinder['size']}',
                                    ),
                                    value: cylinder['selected'],
                                    onChanged: (_) => _toggleCylinderSelection(index),
                                    secondary: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        (index + 1).toString(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
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
}

// Import the necessary providers
import '../../config/app_config.dart';
