import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cylinder.dart';
import '../../models/filling.dart';
import '../../providers/auth_provider.dart';
import '../../providers/filling_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/cylinder_card.dart';
import '../../widgets/qr_scanner.dart';
import 'filling_detail_screen.dart';

class FillingLineScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? args;

  const FillingLineScreen({Key? key, this.args}) : super(key: key);

  @override
  ConsumerState<FillingLineScreen> createState() => _FillingLineScreenState();
}

class _FillingLineScreenState extends ConsumerState<FillingLineScreen> {
  final List<Cylinder> _scannedCylinders = [];
  final List<String> _errors = [];
  int _selectedLine = 1;
  GasType _selectedGasType = GasType.Industrial;
  String _batchNumber = '';
  bool _isLoading = false;
  bool _isSending = false;
  bool _batchMode = false;
  int _maxCylindersPerLine = kMaxCylindersPerLine;

  @override
  void initState() {
    super.initState();
    
    // If cylinder already provided in args
    if (widget.args != null && widget.args!.containsKey('cylinderId')) {
      _loadInitialCylinder(widget.args!['cylinderId']);
    }
  }

  Future<void> _loadInitialCylinder(int cylinderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cylinder = await ref.read(cylinderProvider.notifier).getCylinderById(cylinderId);
      if (cylinder != null) {
        setState(() {
          _scannedCylinders.add(cylinder);
          _selectedGasType = cylinder.gasType;
        });
      }
    } catch (e) {
      _errors.add('Error loading cylinder: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanCylinder() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      _processCylinderCode(result);
    }
  }

  Future<void> _processCylinderCode(String code) async {
    setState(() {
      _isLoading = true;
      _errors.clear();
    });

    try {
      final cylinder = await ref.read(cylinderProvider.notifier).getCylinderByQRCode(code);
      
      if (cylinder == null) {
        setState(() {
          _errors.add('No cylinder found with this QR code.');
        });
        return;
      }

      // Check if already in the list
      if (_scannedCylinders.any((c) => c.id == cylinder.id)) {
        setState(() {
          _errors.add('Cylinder already scanned and in the queue.');
        });
        return;
      }

      // Check gas type consistency
      if (_scannedCylinders.isNotEmpty && _scannedCylinders[0].gasType != cylinder.gasType) {
        setState(() {
          _errors.add('Inconsistent gas types. All cylinders in a batch must be of the same gas type.');
        });
        return;
      }

      // Check if cylinder is eligible for filling
      if (cylinder.status != CylinderStatus.Empty) {
        setState(() {
          _errors.add('Cylinder is not empty and cannot be filled. Current status: ${cylinder.status.toString().split('.').last}');
        });
        return;
      }

      // Check if batch is full
      if (_scannedCylinders.length >= _maxCylindersPerLine) {
        setState(() {
          _errors.add('Maximum number of cylinders reached for this line.');
        });
        return;
      }

      setState(() {
        _scannedCylinders.add(cylinder);
        // Set gas type based on first cylinder
        if (_scannedCylinders.length == 1) {
          _selectedGasType = cylinder.gasType;
        }
      });
    } catch (e) {
      setState(() {
        _errors.add('Error: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeCylinder(int index) {
    setState(() {
      _scannedCylinders.removeAt(index);
      if (_scannedCylinders.isEmpty) {
        // Reset gas type if no cylinders
        _selectedGasType = GasType.Industrial;
      }
    });
  }

  Future<void> _startFilling() async {
    if (_scannedCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan at least one cylinder')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _errors.clear();
    });

    try {
      if (_batchMode) {
        // Batch filling
        final cylinderIds = _scannedCylinders.map((c) => c.id).toList();
        final batchData = {
          'cylinderIds': cylinderIds,
          'lineNumber': _selectedLine,
          'gasType': _selectedGasType == GasType.Medical ? 'Medical' : 'Industrial',
          'batchNumber': _batchNumber.isEmpty ? null : _batchNumber,
        };

        final result = await ref.read(fillingProvider.notifier).batchStartFilling(batchData);

        if (result && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch filling started successfully')),
          );
          Navigator.pushReplacementNamed(context, '/filling');
        }
      } else {
        // Individual filling
        for (int i = 0; i < _scannedCylinders.length; i++) {
          final cylinder = _scannedCylinders[i];
          
          final fillingData = {
            'cylinderId': cylinder.id,
            'lineNumber': _selectedLine,
            'gasType': _selectedGasType == GasType.Medical ? 'Medical' : 'Industrial',
            'batchNumber': _batchNumber.isEmpty ? null : _batchNumber,
          };

          final result = await ref.read(fillingProvider.notifier).startFilling(fillingData);

          if (!result) {
            setState(() {
              _errors.add('Failed to start filling for cylinder ${cylinder.serialNumber}');
            });
            break;
          }
        }

        if (_errors.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Filling started successfully')),
          );
          Navigator.pushReplacementNamed(context, '/filling');
        }
      }
    } catch (e) {
      setState(() {
        _errors.add('Error: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final bool canFillCylinders = currentUser?.isAdmin == true || 
                                currentUser?.isManager == true || 
                                currentUser?.isFiller == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Filling'),
        actions: [
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
                // Line and gas type selection
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _batchMode ? 'Batch Filling' : 'Individual Filling',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Filling Line',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedLine,
                                  items: List.generate(5, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index + 1,
                                      child: Text('Line ${index + 1}'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLine = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<GasType>(
                                  decoration: const InputDecoration(
                                    labelText: 'Gas Type',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedGasType,
                                  items: const [
                                    DropdownMenuItem<GasType>(
                                      value: GasType.Medical,
                                      child: Text('Medical'),
                                    ),
                                    DropdownMenuItem<GasType>(
                                      value: GasType.Industrial,
                                      child: Text('Industrial'),
                                    ),
                                  ],
                                  onChanged: _scannedCylinders.isEmpty 
                                      ? (value) {
                                          setState(() {
                                            _selectedGasType = value!;
                                          });
                                        }
                                      : null, // Disable if cylinders are already selected
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Batch Number (Optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Enter batch number for tracking',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _batchNumber = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Cylinder count indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scanned Cylinders: ${_scannedCylinders.length}/$_maxCylindersPerLine',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: canFillCylinders ? _scanCylinder : null,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Cylinder'),
                      ),
                    ],
                  ),
                ),

                // Error messages
                if (_errors.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Errors:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_errors.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              '• ${_errors[index]}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                // Scanned cylinders list
                Expanded(
                  child: _scannedCylinders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Scan cylinders to start filling',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cylinders must be empty to be filled',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _scannedCylinders.length,
                          itemBuilder: (context, index) {
                            final cylinder = _scannedCylinders[index];
                            return Stack(
                              children: [
                                CylinderCard(
                                  cylinder: cylinder,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CylinderDetailScreen(cylinder: cylinder),
                                      ),
                                    );
                                  },
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: canFillCylinders && !_isSending && _scannedCylinders.isNotEmpty
                ? _startFilling
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: _isSending
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(
                    _batchMode
                        ? 'Start Batch Filling'
                        : 'Start Filling ${_scannedCylinders.length} Cylinder${_scannedCylinders.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
