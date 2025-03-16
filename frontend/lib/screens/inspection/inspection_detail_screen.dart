import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/cylinder.dart';
import '../../models/inspection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspection_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/cylinder_card.dart';

class InspectionDetailScreen extends ConsumerStatefulWidget {
  final Cylinder? cylinder;
  final Inspection? inspection; // For viewing existing inspection

  const InspectionDetailScreen({
    Key? key,
    this.cylinder,
    this.inspection,
  }) : super(key: key);

  factory InspectionDetailScreen.fromInspection({
    required Inspection inspection,
  }) {
    return InspectionDetailScreen(inspection: inspection);
  }

  @override
  ConsumerState<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends ConsumerState<InspectionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pressureController = TextEditingController();
  final _visualInspectionController = TextEditingController();
  final _notesController = TextEditingController();
  
  InspectionResult _result = InspectionResult.Pending;
  DateTime _nextInspectionDate = DateTime.now().add(const Duration(days: 365)); // Default 1 year
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isViewMode = false;

  @override
  void initState() {
    super.initState();
    _isViewMode = widget.inspection != null;
    _isEditMode = widget.cylinder != null && !_isViewMode;
    
    if (_isViewMode) {
      // Viewing existing inspection
      _pressureController.text = widget.inspection!.pressure?.toString() ?? '';
      _visualInspectionController.text = widget.inspection!.visualInspection ?? '';
      _notesController.text = widget.inspection!.notes ?? '';
      _result = widget.inspection!.result;
      _nextInspectionDate = widget.inspection!.nextInspectionDate ?? _nextInspectionDate;
    }
  }

  @override
  void dispose() {
    _pressureController.dispose();
    _visualInspectionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectNextInspectionDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextInspectionDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // Up to 10 years
    );
    
    if (pickedDate != null) {
      setState(() {
        _nextInspectionDate = pickedDate;
      });
    }
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final inspectionData = {
        'cylinderId': widget.cylinder!.id,
        'result': _result.toString().split('.').last,
        'pressure': _pressureController.text.isEmpty ? null : double.parse(_pressureController.text),
        'visualInspection': _visualInspectionController.text.isEmpty ? null : _visualInspectionController.text,
        'nextInspectionDate': _nextInspectionDate.toIso8601String(),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (_isViewMode) {
        // Update existing inspection
        final success = await ref.read(inspectionProvider.notifier)
            .updateInspection(widget.inspection!.id, inspectionData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inspection updated successfully')),
          );
          Navigator.pop(context, widget.inspection);
        }
      } else {
        // Create new inspection
        final success = await ref.read(inspectionProvider.notifier).createInspection(inspectionData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inspection created successfully')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final bool canInspect = currentUser?.isAdmin == true || 
                          currentUser?.isManager == true || 
                          currentUser?.isFiller == true;
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isViewMode 
            ? 'Inspection Details' 
            : 'Inspect Cylinder'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cylinder information
                  const Text(
                    'Cylinder Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isViewMode && widget.inspection!.cylinder != null)
                    CylinderCard(
                      cylinder: widget.inspection!.cylinder!,
                      showDetailChevron: false,
                    )
                  else if (widget.cylinder != null)
                    CylinderCard(
                      cylinder: widget.cylinder!,
                      showDetailChevron: false,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Inspection form
                  const Text(
                    'Inspection Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // View mode info
                  if (_isViewMode) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getResultColor(widget.inspection!.result).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getResultIcon(widget.inspection!.result),
                                    color: _getResultColor(widget.inspection!.result),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Inspection #${widget.inspection!.id}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Date: ${dateFormat.format(widget.inspection!.inspectionDate)}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getResultColor(widget.inspection!.result).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              widget.inspection!.resultText,
                                              style: TextStyle(
                                                color: _getResultColor(widget.inspection!.result),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Inspection details
                            if (widget.inspection!.pressure != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.speed, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pressure: ${widget.inspection!.pressure} bar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (widget.inspection!.nextInspectionDate != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.event, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Next Inspection: ${dateFormat.format(widget.inspection!.nextInspectionDate!)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (widget.inspection!.inspector != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Inspector: ${widget.inspection!.inspector!.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (widget.inspection!.visualInspection != null && 
                                widget.inspection!.visualInspection!.isNotEmpty) ...[
                              const Text(
                                'Visual Inspection:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.inspection!.visualInspection!),
                              const SizedBox(height: 8),
                            ],
                            
                            if (widget.inspection!.notes != null && 
                                widget.inspection!.notes!.isNotEmpty) ...[
                              const Text(
                                'Notes:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.inspection!.notes!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Inspection form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Result radio buttons
                        const Text(
                          'Inspection Result',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<InspectionResult>(
                                title: const Text('Approve'),
                                value: InspectionResult.Approved,
                                groupValue: _result,
                                onChanged: canInspect && !_isViewMode
                                    ? (InspectionResult? value) {
                                        setState(() {
                                          _result = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                                activeColor: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<InspectionResult>(
                                title: const Text('Reject'),
                                value: InspectionResult.Rejected,
                                groupValue: _result,
                                onChanged: canInspect && !_isViewMode
                                    ? (InspectionResult? value) {
                                        setState(() {
                                          _result = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                                activeColor: Colors.red,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<InspectionResult>(
                                title: const Text('Pending'),
                                value: InspectionResult.Pending,
                                groupValue: _result,
                                onChanged: canInspect && !_isViewMode
                                    ? (InspectionResult? value) {
                                        setState(() {
                                          _result = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                                activeColor: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Pressure
                        TextFormField(
                          controller: _pressureController,
                          decoration: const InputDecoration(
                            labelText: 'Pressure (bar)',
                            hintText: 'Enter current pressure',
                          ),
                          keyboardType: TextInputType.number,
                          enabled: canInspect && !_isViewMode,
                        ),
                        const SizedBox(height: 16),
                        
                        // Visual inspection
                        TextFormField(
                          controller: _visualInspectionController,
                          decoration: const InputDecoration(
                            labelText: 'Visual Inspection',
                            hintText: 'Enter visual inspection details',
                          ),
                          maxLines: 3,
                          enabled: canInspect && !_isViewMode,
                        ),
                        const SizedBox(height: 16),
                        
                        // Next inspection date
                        InkWell(
                          onTap: canInspect && !_isViewMode ? _selectNextInspectionDate : null,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Next Inspection Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormat.format(_nextInspectionDate)),
                          ),
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
                          enabled: canInspect && !_isViewMode,
                        ),
                        const SizedBox(height: 24),
                        
                        if (canInspect && !_isViewMode)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveInspection,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      _result == InspectionResult.Approved
                                          ? 'Approve Cylinder'
                                          : _result == InspectionResult.Rejected
                                              ? 'Reject Cylinder'
                                              : 'Save Inspection',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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

  IconData _getResultIcon(InspectionResult result) {
    switch (result) {
      case InspectionResult.Approved:
        return Icons.check_circle;
      case InspectionResult.Rejected:
        return Icons.cancel;
      case InspectionResult.Pending:
      default:
        return Icons.pending;
    }
  }
}
