import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/cylinder.dart';
import '../../models/factory.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../providers/factory_provider.dart';
import '../../services/qr_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class CylinderDetailScreen extends ConsumerStatefulWidget {
  final Cylinder? cylinder;
  final Factory? factory; // Pre-selected factory if creating new cylinder

  const CylinderDetailScreen({
    Key? key,
    this.cylinder,
    this.factory,
  }) : super(key: key);

  @override
  ConsumerState<CylinderDetailScreen> createState() => _CylinderDetailScreenState();
}

class _CylinderDetailScreenState extends ConsumerState<CylinderDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _sizeController = TextEditingController();
  final _originalNumberController = TextEditingController();
  final _workingPressureController = TextEditingController();
  final _designPressureController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _importDate;
  DateTime _productionDate = DateTime.now();
  GasType _gasType = GasType.Industrial;
  int? _factoryId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.cylinder != null;
    
    if (_isEditMode) {
      // Edit mode - fill form with cylinder data
      _serialNumberController.text = widget.cylinder!.serialNumber;
      _sizeController.text = widget.cylinder!.size;
      _originalNumberController.text = widget.cylinder!.originalNumber ?? '';
      _workingPressureController.text = widget.cylinder!.workingPressure.toString();
      _designPressureController.text = widget.cylinder!.designPressure.toString();
      _notesController.text = widget.cylinder!.notes ?? '';
      
      _importDate = widget.cylinder!.importDate;
      _productionDate = widget.cylinder!.productionDate;
      _gasType = widget.cylinder!.gasType;
      _factoryId = widget.cylinder!.factory?.id;
      _isActive = widget.cylinder!.isActive;
    } else if (widget.factory != null) {
      // Create mode with pre-selected factory
      _factoryId = widget.factory!.id;
    }
    
    // Fetch factories for dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(factoryProvider.notifier).fetchFactories();
    });
  }

  @override
  void dispose() {
    _serialNumberController.dispose();
    _sizeController.dispose();
    _originalNumberController.dispose();
    _workingPressureController.dispose();
    _designPressureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isImportDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isImportDate ? (_importDate ?? DateTime.now()) : _productionDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isImportDate) {
          _importDate = picked;
        } else {
          _productionDate = picked;
        }
      });
    }
  }

  Future<void> _saveCylinder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_factoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a factory')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cylinderData = {
        'serialNumber': _serialNumberController.text,
        'size': _sizeController.text,
        'importDate': _importDate?.toIso8601String(),
        'productionDate': _productionDate.toIso8601String(),
        'originalNumber': _originalNumberController.text.isEmpty ? null : _originalNumberController.text,
        'workingPressure': double.parse(_workingPressureController.text),
        'designPressure': double.parse(_designPressureController.text),
        'gasType': _gasType == GasType.Medical ? 'Medical' : 'Industrial',
        'factoryId': _factoryId,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (_isEditMode) {
        // Add status and isActive for updates
        cylinderData['status'] = widget.cylinder!.status.toString().split('.').last;
        cylinderData['isActive'] = _isActive;
        
        final success = await ref.read(cylinderProvider.notifier)
            .updateCylinder(widget.cylinder!.id, cylinderData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cylinder updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        final success = await ref.read(cylinderProvider.notifier)
            .createCylinder(cylinderData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cylinder created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showQRCodeDialog() {
    if (!_isEditMode) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cylinder QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: QRService.formatCylinderQRData(widget.cylinder!.qrCode),
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 16),
              Text(
                'Serial Number: ${widget.cylinder!.serialNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan this code to quickly access cylinder information',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final factoriesState = ref.watch(factoryProvider);
    final factories = factoriesState.filteredFactories;
    
    final bool canModifyCylinder = currentUser?.isAdmin == true || currentUser?.isManager == true;
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Cylinder Details' : 'Create Cylinder'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _showQRCodeDialog,
              tooltip: 'Show QR Code',
            ),
          if (_isEditMode && canModifyCylinder)
            IconButton(
              icon: Icon(
                _isActive ? Icons.block : Icons.check_circle,
                color: _isActive ? Colors.red : Colors.green,
              ),
              onPressed: () {
                setState(() {
                  _isActive = !_isActive;
                });
              },
              tooltip: _isActive ? 'Deactivate Cylinder' : 'Activate Cylinder',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cylinder status card for edit mode
                  if (_isEditMode)
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Cylinder icon with status color
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getCylinderStatusColor(widget.cylinder!.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.propane_tank_outlined,
                                    color: _getCylinderStatusColor(widget.cylinder!.status),
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Cylinder basic info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SN: ${widget.cylinder!.serialNumber}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Size: ${widget.cylinder!.size}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildStatusChip(
                                            kCylinderStatusNames[widget.cylinder!.status.toString().split('.').last] ?? 'Unknown',
                                            _getCylinderStatusColor(widget.cylinder!.status),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusChip(
                                            widget.cylinder!.gasType == GasType.Medical ? 'Medical' : 'Industrial',
                                            widget.cylinder!.gasType == GasType.Medical ? Colors.blue : Colors.green,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Additional info row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Factory',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        widget.cylinder!.factory?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.cylinder!.currentCustomer != null)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Current Customer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          widget.cylinder!.currentCustomer!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Last Filled',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        widget.cylinder!.lastFilledDate != null
                                            ? dateFormat.format(widget.cylinder!.lastFilledDate!)
                                            : 'Never',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Form fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info Section
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _serialNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Serial Number',
                            hintText: 'Enter cylinder serial number',
                          ),
                          validator: Validators.validateCylinderSerial,
                          enabled: canModifyCylinder,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _sizeController,
                          decoration: const InputDecoration(
                            labelText: 'Size',
                            hintText: 'E.g., 50L, 10kg, etc.',
                          ),
                          validator: (value) => Validators.validateRequired(value, 'Size'),
                          enabled: canModifyCylinder,
                        ),
                        const SizedBox(height: 16),
                        
                        // Factory dropdown
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Factory',
                            hintText: 'Select factory',
                          ),
                          value: _factoryId,
                          items: factories.map((factory) {
                            return DropdownMenuItem<int>(
                              value: factory.id,
                              child: Text(factory.name),
                            );
                          }).toList(),
                          onChanged: canModifyCylinder 
                              ? (value) {
                                  setState(() {
                                    _factoryId = value;
                                  });
                                }
                              : null,
                          validator: (value) => value == null ? 'Please select a factory' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Gas Type Radio Buttons
                        const Text('Gas Type'),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<GasType>(
                                title: const Text('Medical'),
                                value: GasType.Medical,
                                groupValue: _gasType,
                                onChanged: canModifyCylinder
                                    ? (GasType? value) {
                                        setState(() {
                                          _gasType = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<GasType>(
                                title: const Text('Industrial'),
                                value: GasType.Industrial,
                                groupValue: _gasType,
                                onChanged: canModifyCylinder
                                    ? (GasType? value) {
                                        setState(() {
                                          _gasType = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Technical Details Section
                        const Text(
                          'Technical Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Original number
                        TextFormField(
                          controller: _originalNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Original Number (Optional)',
                            hintText: 'Manufacturer number if available',
                          ),
                          enabled: canModifyCylinder,
                        ),
                        const SizedBox(height: 16),
                        
                        // Pressure values
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _workingPressureController,
                                decoration: const InputDecoration(
                                  labelText: 'Working Pressure (bar)',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => Validators.validatePositiveNumber(value, 'Working pressure'),
                                enabled: canModifyCylinder,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _designPressureController,
                                decoration: const InputDecoration(
                                  labelText: 'Design Pressure (bar)',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) => Validators.validatePositiveNumber(value, 'Design pressure'),
                                enabled: canModifyCylinder,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: canModifyCylinder
                                    ? () => _selectDate(context, true)
                                    : null,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Import Date (Optional)',
                                  ),
                                  child: Text(
                                    _importDate != null
                                        ? dateFormat.format(_importDate!)
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _importDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: canModifyCylinder
                                    ? () => _selectDate(context, false)
                                    : null,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Production Date',
                                  ),
                                  child: Text(
                                    dateFormat.format(_productionDate),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Enter any additional information',
                          ),
                          maxLines: 3,
                          enabled: canModifyCylinder,
                        ),
                        const SizedBox(height: 32),
                        
                        if (canModifyCylinder)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: !_isLoading ? _saveCylinder : null,
                              child: Text(
                                _isEditMode ? 'Update Cylinder' : 'Create Cylinder',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getCylinderStatusColor(CylinderStatus status) {
    switch (status) {
      case CylinderStatus.Empty:
        return kCylinderEmptyColor;
      case CylinderStatus.Full:
        return kCylinderFullColor;
      case CylinderStatus.Error:
        return kCylinderErrorColor;
      case CylinderStatus.InTransit:
        return kCylinderInTransitColor;
      case CylinderStatus.InMaintenance:
        return kCylinderInMaintenanceColor;
      case CylinderStatus.InFilling:
        return kCylinderInFillingColor;
      case CylinderStatus.InInspection:
        return kCylinderInInspectionColor;
      default:
        return kCylinderEmptyColor;
    }
  }
}
