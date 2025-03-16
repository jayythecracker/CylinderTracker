import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cylinder.dart';
import '../../models/factory.dart' as factory_model;
import '../../providers/cylinder_provider.dart';
import '../factory/factory_list_provider.dart';

class CylinderFormScreen extends ConsumerStatefulWidget {
  final int? cylinderId;

  const CylinderFormScreen({Key? key, this.cylinderId}) : super(key: key);

  @override
  ConsumerState<CylinderFormScreen> createState() => _CylinderFormScreenState();
}

class _CylinderFormScreenState extends ConsumerState<CylinderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _serialNumberController = TextEditingController();
  final _sizeController = TextEditingController();
  final _originalNumberController = TextEditingController();
  final _workingPressureController = TextEditingController();
  final _designPressureController = TextEditingController();
  
  DateTime _productionDate = DateTime.now();
  DateTime? _importDate;
  String _gasType = 'Industrial';
  int? _selectedFactoryId;
  String _status = 'Empty';
  bool _isLoading = false;
  bool _isEditMode = false;
  List<factory_model.Factory> _factories = [];
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.cylinderId != null;
    
    _loadFactories();
    if (_isEditMode) {
      _loadCylinderData();
    }
  }

  Future<void> _loadFactories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final factoriesAsync = await ref.read(factoryListProvider.future);
      setState(() {
        _factories = factoriesAsync;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load factories: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCylinderData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cylinder = await ref.read(cylindersProvider.notifier).getCylinderById(widget.cylinderId!);
      
      _serialNumberController.text = cylinder.serialNumber;
      _sizeController.text = cylinder.size;
      _originalNumberController.text = cylinder.originalNumber ?? '';
      _workingPressureController.text = cylinder.workingPressure.toString();
      _designPressureController.text = cylinder.designPressure.toString();
      _productionDate = cylinder.productionDate;
      _importDate = cylinder.importDate;
      _gasType = cylinder.gasType;
      _selectedFactoryId = cylinder.factoryId;
      _status = cylinder.status;
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load cylinder data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _sizeController.dispose();
    _originalNumberController.dispose();
    _workingPressureController.dispose();
    _designPressureController.dispose();
    super.dispose();
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFactoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a factory'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cylinder = Cylinder(
        id: _isEditMode ? widget.cylinderId! : 0,
        serialNumber: _serialNumberController.text,
        qrCode: '', // The server will generate this
        size: _sizeController.text,
        importDate: _importDate,
        productionDate: _productionDate,
        originalNumber: _originalNumberController.text.isEmpty ? null : _originalNumberController.text,
        workingPressure: double.parse(_workingPressureController.text),
        designPressure: double.parse(_designPressureController.text),
        gasType: _gasType,
        status: _status,
        factoryId: _selectedFactoryId!,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (_isEditMode) {
        // Update existing cylinder
        await ref.read(cylindersProvider.notifier).updateCylinder(
              widget.cylinderId!,
              cylinder,
            );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cylinder updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new cylinder
        await ref.read(cylindersProvider.notifier).createCylinder(cylinder);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cylinder created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save cylinder: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectProductionDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _productionDate) {
      setState(() {
        _productionDate = picked;
      });
    }
  }

  Future<void> _selectImportDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _importDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _importDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Cylinder' : 'Create Cylinder'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _serialNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a serial number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a size';
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
                        prefixIcon: Icon(Icons.local_gas_station),
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
                        setState(() {
                          _gasType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedFactoryId,
                      decoration: const InputDecoration(
                        labelText: 'Factory',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.factory),
                      ),
                      items: [
                        for (final factory in _factories)
                          DropdownMenuItem(
                            value: factory.id,
                            child: Text(factory.name),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFactoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a factory';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _workingPressureController,
                            decoration: const InputDecoration(
                              labelText: 'Working Pressure (bar)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.speed),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _designPressureController,
                            decoration: const InputDecoration(
                              labelText: 'Design Pressure (bar)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.speed),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectProductionDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Production Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _productionDate.toString().substring(0, 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectImportDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Import Date (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _importDate != null
                              ? _importDate.toString().substring(0, 10)
                              : 'Not specified',
                        ),
                      ),
                    ),
                    if (_importDate != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _importDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originalNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Original Number (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    if (_isEditMode) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Empty',
                            child: Text('Empty'),
                          ),
                          DropdownMenuItem(
                            value: 'Full',
                            child: Text('Full'),
                          ),
                          DropdownMenuItem(
                            value: 'In Filling',
                            child: Text('In Filling'),
                          ),
                          DropdownMenuItem(
                            value: 'In Inspection',
                            child: Text('In Inspection'),
                          ),
                          DropdownMenuItem(
                            value: 'Error',
                            child: Text('Error'),
                          ),
                          DropdownMenuItem(
                            value: 'In Delivery',
                            child: Text('In Delivery'),
                          ),
                          DropdownMenuItem(
                            value: 'Maintenance',
                            child: Text('Maintenance'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveCylinder,
                        child: Text(
                          _isEditMode ? 'Update Cylinder' : 'Create Cylinder',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Simple provider to fetch factories list
final factoryListProvider = FutureProvider<List<factory_model.Factory>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final response = await apiService.get('/api/factories');
    return (response['factories'] as List)
        .map((factoryData) => factory_model.Factory.fromJson(factoryData))
        .toList();
  } catch (e) {
    throw Exception('Failed to load factories: $e');
  }
});
