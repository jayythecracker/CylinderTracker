import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/providers/cylinder_provider.dart';
import 'package:cylinder_management/providers/factory_provider.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/screens/cylinders/cylinder_detail_screen.dart';
import 'package:cylinder_management/utils/qr_scanner.dart';
import 'package:cylinder_management/widgets/cylinder_card.dart';
import 'package:cylinder_management/widgets/loading_indicator.dart';
import 'package:cylinder_management/widgets/error_display.dart';

class CylindersScreen extends ConsumerStatefulWidget {
  const CylindersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CylindersScreen> createState() => _CylindersScreenState();
}

class _CylindersScreenState extends ConsumerState<CylindersScreen> {
  // Filter parameters
  String _searchQuery = '';
  String? _statusFilter;
  String? _typeFilter;
  int? _factoryFilter;
  
  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Fetch cylinders on init
    Future.microtask(() {
      _fetchCylinders();
      ref.read(factoriesProvider.notifier).fetchFactories();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }
  
  void _loadMoreData() {
    if (_hasMoreData && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      
      _fetchCylinders(isLoadMore: true);
    }
  }
  
  Future<void> _fetchCylinders({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _currentPage = 1;
    }
    
    // Build filter map
    final filters = <String, dynamic>{
      'page': _currentPage,
      'limit': _pageSize,
    };
    
    if (_searchQuery.isNotEmpty) {
      filters['search'] = _searchQuery;
    }
    
    if (_statusFilter != null) {
      filters['status'] = _statusFilter;
    }
    
    if (_typeFilter != null) {
      filters['type'] = _typeFilter;
    }
    
    if (_factoryFilter != null) {
      filters['factoryId'] = _factoryFilter;
    }
    
    // Fetch data
    await ref.read(cylindersProvider.notifier).fetchCylinders(filters: filters);
    
    // Update state
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    await _fetchCylinders();
  }
  
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _typeFilter = null;
      _factoryFilter = null;
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    _fetchCylinders();
  }
  
  void _navigateToCylinderDetail(Cylinder cylinder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CylinderDetailScreen(cylinderId: cylinder.id),
      ),
    ).then((_) {
      // Refresh data when returning from detail screen
      _refreshData();
    });
  }
  
  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScanner(
          onScan: (String qrCode) {
            ref.read(cylinderByQrProvider.notifier).fetchCylinderByQr(qrCode);
          },
        ),
      ),
    ).then((_) {
      // Process scanned QR code
      final cylinderData = ref.read(cylinderByQrProvider);
      
      cylinderData.whenData((data) {
        if (data != null && data['cylinder'] != null) {
          final cylinder = data['cylinder'] as Cylinder;
          _navigateToCylinderDetail(cylinder);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final cylindersData = ref.watch(cylindersProvider);
    final factories = ref.watch(factoriesProvider);
    
    final bool canEdit = user != null && (user.isAdmin || user.isManager);
    
    // Listen for QR scanner results
    ref.listen(cylinderByQrProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error scanning QR code: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });
    
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search cylinders...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (_) => _refreshData(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan QR Code',
                  onPressed: _scanQRCode,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          
          // Active filters display
          if (_statusFilter != null || _typeFilter != null || _factoryFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_statusFilter != null)
                      _buildFilterChip(
                        'Status: $_statusFilter',
                        () {
                          setState(() {
                            _statusFilter = null;
                          });
                          _refreshData();
                        },
                      ),
                    if (_typeFilter != null)
                      _buildFilterChip(
                        'Type: $_typeFilter',
                        () {
                          setState(() {
                            _typeFilter = null;
                          });
                          _refreshData();
                        },
                      ),
                    if (_factoryFilter != null)
                      factories.whenOrNull(
                        data: (factoriesData) {
                          final factory = factoriesData.firstWhere(
                            (f) => f.id == _factoryFilter,
                            orElse: () => Factory.empty(),
                          );
                          return factory.id != 0
                              ? _buildFilterChip(
                                  'Factory: ${factory.name}',
                                  () {
                                    setState(() {
                                      _factoryFilter = null;
                                    });
                                    _refreshData();
                                  },
                                )
                              : const SizedBox.shrink();
                        },
                      ) ?? const SizedBox.shrink(),
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        _resetFilters();
                      },
                    ),
                  ],
                ),
              ),
            ),
          
          // Cylinders list
          Expanded(
            child: cylindersData.when(
              data: (cylinders) {
                if (cylinders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.propane_tank_outlined,
                          size: 72,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cylinders found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first cylinder or adjust filters',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (canEdit)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Cylinder'),
                              onPressed: _showAddCylinderDialog,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => _refreshData(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: cylinders.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == cylinders.length) {
                        return _hasMoreData
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      final cylinder = cylinders[index];
                      return CylinderCard(
                        cylinder: cylinder,
                        onTap: () => _navigateToCylinderDetail(cylinder),
                        actions: canEdit
                            ? [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showEditCylinderDialog(cylinder),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showCylinderActions(cylinder),
                                  tooltip: 'More Actions',
                                ),
                              ]
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                onRetry: _refreshData,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: _showAddCylinderDialog,
              backgroundColor: AppConfig.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
        deleteIconColor: AppConfig.primaryColor,
        onDeleted: onRemove,
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Cylinders'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  const Text('Status:'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('All', null, _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                      _buildFilterOption('Empty', 'Empty', _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                      _buildFilterOption('Full', 'Full', _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                      _buildFilterOption('Error', 'Error', _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                      _buildFilterOption('In Transit', 'InTransit', _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                      _buildFilterOption('In Maintenance', 'InMaintenance', _statusFilter, (value) {
                        setDialogState(() {
                          _statusFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Type filter
                  const Text('Type:'),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('All', null, _typeFilter, (value) {
                        setDialogState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Medical', 'Medical', _typeFilter, (value) {
                        setDialogState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Industrial', 'Industrial', _typeFilter, (value) {
                        setDialogState(() {
                          _typeFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Factory filter
                  const Text('Factory:'),
                  Consumer(
                    builder: (context, ref, child) {
                      final factories = ref.watch(factoriesProvider);
                      
                      return factories.when(
                        data: (factoriesData) => DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(
                            hintText: 'Select Factory',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _factoryFilter,
                          onChanged: (value) {
                            setDialogState(() {
                              _factoryFilter = value;
                            });
                          },
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Factories'),
                            ),
                            ...factoriesData.map((factory) => DropdownMenuItem<int?>(
                              value: factory.id,
                              child: Text(factory.name),
                            )),
                          ],
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error: $error'),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilters();
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshData();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFilterOption(
    String label,
    String? value,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    final isSelected = value == selectedValue;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? value : null);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppConfig.primaryColor.withOpacity(0.2),
    );
  }
  
  void _showAddCylinderDialog() {
    final formKey = GlobalKey<FormState>();
    final serialNumberController = TextEditingController();
    final sizeController = TextEditingController();
    String type = 'Industrial';
    DateTime? importDate;
    final DateTime productionDate = DateTime.now();
    final originalNumberController = TextEditingController();
    final workingPressureController = TextEditingController();
    final designPressureController = TextEditingController();
    int? factoryId;
    
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Cylinder'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Serial Number
                    TextFormField(
                      controller: serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a serial number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Size
                    TextFormField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size *',
                        hintText: 'e.g., Small, Medium, Large, or dimensions',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the cylinder size';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Type
                    FormField<String>(
                      initialValue: type,
                      builder: (FormFieldState<String> state) {
                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: type,
                              isDense: true,
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  type = newValue!;
                                });
                              },
                              items: <String>['Medical', 'Industrial']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Production Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: productionDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (date != null) {
                          setDialogState(() {
                            productionDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Production Date *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${productionDate.day}/${productionDate.month}/${productionDate.year}',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Import Date (Optional)
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: importDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (date != null) {
                          setDialogState(() {
                            importDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Import Date (Optional)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              importDate != null
                                  ? '${importDate!.day}/${importDate!.month}/${importDate!.year}'
                                  : 'Select Date',
                            ),
                            Icon(
                              importDate != null ? Icons.calendar_today : Icons.add_circle_outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Original Number (Optional)
                    TextFormField(
                      controller: originalNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Original Number (Optional)',
                        hintText: 'Manufacturer number',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Working Pressure
                    TextFormField(
                      controller: workingPressureController,
                      decoration: const InputDecoration(
                        labelText: 'Working Pressure (bar) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter working pressure';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Design Pressure
                    TextFormField(
                      controller: designPressureController,
                      decoration: const InputDecoration(
                        labelText: 'Design Pressure (bar) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter design pressure';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Factory
                    Consumer(
                      builder: (context, ref, child) {
                        final factories = ref.watch(factoriesProvider);
                        
                        return factories.when(
                          data: (factoriesData) => FormField<int?>(
                            initialValue: factoryId,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a factory';
                              }
                              return null;
                            },
                            builder: (FormFieldState<int?> state) {
                              return InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Factory *',
                                  errorText: state.errorText,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: factoryId,
                                    isDense: true,
                                    hint: const Text('Select Factory'),
                                    onChanged: (int? newValue) {
                                      setDialogState(() {
                                        factoryId = newValue;
                                        state.didChange(newValue);
                                      });
                                    },
                                    items: factoriesData
                                        .map<DropdownMenuItem<int?>>((factory) {
                                      return DropdownMenuItem<int?>(
                                        value: factory.id,
                                        child: Text(factory.name),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => Text('Error: $error'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      try {
                        final cylinderData = {
                          'serialNumber': serialNumberController.text,
                          'size': sizeController.text,
                          'type': type,
                          'productionDate': productionDate.toIso8601String(),
                          if (importDate != null) 'importDate': importDate!.toIso8601String(),
                          if (originalNumberController.text.isNotEmpty)
                            'originalNumber': originalNumberController.text,
                          'workingPressure': double.parse(workingPressureController.text),
                          'designPressure': double.parse(designPressureController.text),
                          'factoryId': factoryId,
                          'status': 'Empty',
                        };
                        
                        final cylinder = await ref.read(cylindersProvider.notifier)
                            .createCylinder(cylinderData);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          
                          if (cylinder != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cylinder created successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            _refreshData();
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          errorMessage = e.toString();
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      serialNumberController.dispose();
      sizeController.dispose();
      originalNumberController.dispose();
      workingPressureController.dispose();
      designPressureController.dispose();
    });
  }
  
  void _showEditCylinderDialog(Cylinder cylinder) {
    final formKey = GlobalKey<FormState>();
    final serialNumberController = TextEditingController(text: cylinder.serialNumber);
    final sizeController = TextEditingController(text: cylinder.size);
    String type = cylinder.type;
    DateTime? importDate = cylinder.importDate;
    DateTime productionDate = cylinder.productionDate;
    final originalNumberController = TextEditingController(text: cylinder.originalNumber ?? '');
    final workingPressureController = TextEditingController(text: cylinder.workingPressure.toString());
    final designPressureController = TextEditingController(text: cylinder.designPressure.toString());
    int factoryId = cylinder.factoryId;
    String status = cylinder.status;
    
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Cylinder'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Serial Number
                    TextFormField(
                      controller: serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a serial number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Size
                    TextFormField(
                      controller: sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the cylinder size';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Type
                    FormField<String>(
                      initialValue: type,
                      builder: (FormFieldState<String> state) {
                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Type *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: type,
                              isDense: true,
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  type = newValue!;
                                });
                              },
                              items: <String>['Medical', 'Industrial']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status
                    FormField<String>(
                      initialValue: status,
                      builder: (FormFieldState<String> state) {
                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Status *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              isDense: true,
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  status = newValue!;
                                });
                              },
                              items: <String>['Empty', 'Full', 'Error', 'InMaintenance', 'InTransit']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Production Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: productionDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (date != null) {
                          setDialogState(() {
                            productionDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Production Date *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${productionDate.day}/${productionDate.month}/${productionDate.year}',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Import Date (Optional)
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: importDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (date != null) {
                          setDialogState(() {
                            importDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Import Date (Optional)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              importDate != null
                                  ? '${importDate!.day}/${importDate!.month}/${importDate!.year}'
                                  : 'Select Date',
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (importDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      setDialogState(() {
                                        importDate = null;
                                      });
                                    },
                                  ),
                                Icon(
                                  importDate != null ? Icons.calendar_today : Icons.add_circle_outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Original Number (Optional)
                    TextFormField(
                      controller: originalNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Original Number (Optional)',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Working Pressure
                    TextFormField(
                      controller: workingPressureController,
                      decoration: const InputDecoration(
                        labelText: 'Working Pressure (bar) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter working pressure';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Design Pressure
                    TextFormField(
                      controller: designPressureController,
                      decoration: const InputDecoration(
                        labelText: 'Design Pressure (bar) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter design pressure';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Factory
                    Consumer(
                      builder: (context, ref, child) {
                        final factories = ref.watch(factoriesProvider);
                        
                        return factories.when(
                          data: (factoriesData) => FormField<int>(
                            initialValue: factoryId,
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a factory';
                              }
                              return null;
                            },
                            builder: (FormFieldState<int> state) {
                              return InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Factory *',
                                  errorText: state.errorText,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: factoryId,
                                    isDense: true,
                                    onChanged: (int? newValue) {
                                      setDialogState(() {
                                        factoryId = newValue!;
                                        state.didChange(newValue);
                                      });
                                    },
                                    items: factoriesData
                                        .map<DropdownMenuItem<int>>((factory) {
                                      return DropdownMenuItem<int>(
                                        value: factory.id,
                                        child: Text(factory.name),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => Text('Error: $error'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      try {
                        final cylinderData = {
                          'serialNumber': serialNumberController.text,
                          'size': sizeController.text,
                          'type': type,
                          'productionDate': productionDate.toIso8601String(),
                          'importDate': importDate?.toIso8601String(),
                          'originalNumber': originalNumberController.text.isNotEmpty
                              ? originalNumberController.text
                              : null,
                          'workingPressure': double.parse(workingPressureController.text),
                          'designPressure': double.parse(designPressureController.text),
                          'factoryId': factoryId,
                          'status': status,
                        };
                        
                        final updatedCylinder = await ref.read(cylindersProvider.notifier)
                            .updateCylinder(cylinder.id, cylinderData);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          
                          if (updatedCylinder != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cylinder updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            _refreshData();
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          errorMessage = e.toString();
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      serialNumberController.dispose();
      sizeController.dispose();
      originalNumberController.dispose();
      workingPressureController.dispose();
      designPressureController.dispose();
    });
  }
  
  void _showCylinderActions(Cylinder cylinder) {
    final TextEditingController notesController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Cylinder ${cylinder.serialNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Status: ${cylinder.status}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Cylinder'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCylinderDialog(cylinder);
                },
              ),
              if (cylinder.status != 'Empty')
                ListTile(
                  leading: Icon(
                    Icons.battery_0_bar,
                    color: AppConfig.getStatusColor('Empty'),
                  ),
                  title: const Text('Mark as Empty'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateCylinderStatus(cylinder, 'Empty');
                  },
                ),
              if (cylinder.status != 'Full')
                ListTile(
                  leading: Icon(
                    Icons.battery_full,
                    color: AppConfig.getStatusColor('Full'),
                  ),
                  title: const Text('Mark as Full'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateCylinderStatus(cylinder, 'Full');
                  },
                ),
              if (cylinder.status != 'Error')
                ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: AppConfig.getStatusColor('Error'),
                  ),
                  title: const Text('Mark as Error'),
                  onTap: () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(cylinder, 'Error');
                  },
                ),
              if (cylinder.status != 'InMaintenance')
                ListTile(
                  leading: Icon(
                    Icons.build,
                    color: AppConfig.getStatusColor('InMaintenance'),
                  ),
                  title: const Text('Mark as In Maintenance'),
                  onTap: () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(cylinder, 'InMaintenance');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Cylinder'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(cylinder);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  void _showStatusUpdateDialog(Cylinder cylinder, String status) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to $status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to mark cylinder ${cylinder.serialNumber} as $status?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add notes about this status change',
              ),
              maxLines: 3,
            ),
          ],
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
              Navigator.pop(context);
              _updateCylinderStatus(cylinder, status, notesController.text.isEmpty ? null : notesController.text);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ).then((_) {
      notesController.dispose();
    });
  }
  
  Future<void> _updateCylinderStatus(Cylinder cylinder, String status, [String? notes]) async {
    try {
      final updatedCylinder = await ref.read(cylindersProvider.notifier)
          .updateCylinderStatus(cylinder.id, status, notes);
      
      if (mounted && updatedCylinder != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cylinder status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDeleteConfirmation(Cylinder cylinder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cylinder'),
        content: Text(
          'Are you sure you want to delete cylinder ${cylinder.serialNumber}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(cylindersProvider.notifier).deleteCylinder(cylinder.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cylinder deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  _refreshData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
