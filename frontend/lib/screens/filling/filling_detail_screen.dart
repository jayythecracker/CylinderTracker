import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/filling.dart';
import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filling_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/cylinder_card.dart';

class FillingDetailScreen extends ConsumerStatefulWidget {
  final Filling filling;
  
  const FillingDetailScreen({
    Key? key,
    required this.filling,
  }) : super(key: key);

  @override
  ConsumerState<FillingDetailScreen> createState() => _FillingDetailScreenState();
}

class _FillingDetailScreenState extends ConsumerState<FillingDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fillingPressureController = TextEditingController();
  final _notesController = TextEditingController();
  
  FillingStatus _status = FillingStatus.Completed;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _notesController.text = widget.filling.notes ?? '';
  }

  @override
  void dispose() {
    _fillingPressureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeFilling() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fillingData = {
        'fillingPressure': double.parse(_fillingPressureController.text),
        'status': _status.toString().split('.').last,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      final success = await ref.read(fillingProvider.notifier)
          .completeFilling(widget.filling.id, fillingData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filling completed successfully')),
        );
        Navigator.pop(context, true);
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
    final bool canCompleteFilling = currentUser?.isAdmin == true || 
                                 currentUser?.isManager == true || 
                                 currentUser?.isFiller == true;
    final bool isCompletable = widget.filling.status == FillingStatus.InProgress;
    
    final DateFormat dateTimeFormat = DateFormat('MMM dd, yyyy - HH:mm');
    final Duration? elapsed = widget.filling.endTime != null 
        ? widget.filling.endTime!.difference(widget.filling.startTime)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Filling #${widget.filling.id}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filling status card
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
                                  color: _getStatusColor(widget.filling.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getStatusIcon(widget.filling.status),
                                  color: _getStatusColor(widget.filling.status),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Line ${widget.filling.lineNumber}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(widget.filling.status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.filling.statusText,
                                            style: TextStyle(
                                              color: _getStatusColor(widget.filling.status),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.filling.gasType == GasType.Medical 
                                                ? Colors.blue.withOpacity(0.2)
                                                : Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.filling.gasType == GasType.Medical 
                                                ? 'Medical'
                                                : 'Industrial',
                                            style: TextStyle(
                                              color: widget.filling.gasType == GasType.Medical 
                                                  ? Colors.blue
                                                  : Colors.green,
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
                          
                          // Filling timestamps
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Started:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(dateTimeFormat.format(widget.filling.startTime)),
                                  ],
                                ),
                                if (widget.filling.endTime != null) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Finished:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(dateTimeFormat.format(widget.filling.endTime!)),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Duration:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${elapsed!.inHours}h ${elapsed.inMinutes.remainder(60)}m',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Personnel info
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Started by:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      widget.filling.startedBy?.name ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.filling.endedBy != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Completed by:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        widget.filling.endedBy?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          if (widget.filling.fillingPressure != null) ...[
                            const SizedBox(height: 16),
                            // Pressure info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.speed,
                                    color: kPrimaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filling Pressure: ${widget.filling.fillingPressure} bar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (widget.filling.batchNumber != null) ...[
                            const SizedBox(height: 16),
                            // Batch info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.batch_prediction,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Batch: ${widget.filling.batchNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (widget.filling.notes != null && widget.filling.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Notes:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.filling.notes!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cylinder info
                  const Text(
                    'Cylinder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (widget.filling.cylinder != null)
                    CylinderCard(
                      cylinder: widget.filling.cylinder!,
                      showDetailChevron: false,
                    ),

                  const SizedBox(height: 24),

                  // Complete filling form (only for in-progress filling)
                  if (isCompletable && canCompleteFilling) ...[
                    const Text(
                      'Complete Filling',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fillingPressureController,
                            decoration: const InputDecoration(
                              labelText: 'Filling Pressure (bar)',
                              hintText: 'Enter the final pressure',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => Validators.validatePositiveNumber(value, 'Filling pressure'),
                          ),
                          const SizedBox(height: 16),
                          
                          // Status radio buttons
                          const Text('Filling Result'),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<FillingStatus>(
                                  title: const Text('Completed'),
                                  value: FillingStatus.Completed,
                                  groupValue: _status,
                                  onChanged: (FillingStatus? value) {
                                    setState(() {
                                      _status = value!;
                                    });
                                  },
                                  dense: true,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<FillingStatus>(
                                  title: const Text('Failed'),
                                  value: FillingStatus.Failed,
                                  groupValue: _status,
                                  onChanged: (FillingStatus? value) {
                                    setState(() {
                                      _status = value!;
                                    });
                                  },
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'Enter any additional information',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _completeFilling,
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Complete Filling',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(FillingStatus status) {
    switch (status) {
      case FillingStatus.Completed:
        return Colors.green;
      case FillingStatus.Failed:
        return Colors.red;
      case FillingStatus.InProgress:
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(FillingStatus status) {
    switch (status) {
      case FillingStatus.Completed:
        return Icons.check_circle;
      case FillingStatus.Failed:
        return Icons.cancel;
      case FillingStatus.InProgress:
      default:
        return Icons.pending;
    }
  }
}
