import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../providers/factory_provider.dart';
import '../../models/cylinder.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/cylinder_card.dart';
import '../../widgets/qr_scanner.dart';
import 'cylinder_detail_screen.dart';

class CylinderListScreen extends ConsumerStatefulWidget {
  const CylinderListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CylinderListScreen> createState() => _CylinderListScreenState();
}

class _CylinderListScreenState extends ConsumerState<CylinderListScreen> {
  String _searchQuery = '';
  CylinderStatus? _statusFilter;
  GasType? _gasTypeFilter;
  int? _factoryIdFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cylinderProvider.notifier).fetchCylinders();
      ref.read(factoryProvider.notifier).fetchFactories();
    });
  }

  void _openQRScanner() async {
    final qrCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScanComplete: (String code) {
            Navigator.pop(context, code);
          },
        ),
      ),
    );

    if (qrCode != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final cylinder = await ref.read(cylinderProvider.notifier).getCylinderByQRCode(qrCode);
        
        if (cylinder != null && mounted) {
          _navigateToCylinderDetail(context, cylinder);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cylinder not found for this QR code')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
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
  }

  @override
  Widget build(BuildContext context) {
    final cylindersState = ref.watch(cylinderProvider);
    final cylinders = cylindersState.filteredCylinders;
    final currentUser = ref.watch(authProvider).user;
    final factoriesState = ref.watch(factoryProvider);
    final factories = factoriesState.filteredFactories;
    
    // Filter cylinders based on search query
    final filteredCylinders = cylinders.where((cylinder) {
      return cylinder.serialNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (cylinder.originalNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    final bool canCreateCylinder = currentUser?.isAdmin == true || currentUser?.isManager == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cylinders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openQRScanner,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cylinderProvider.notifier).fetchCylinders(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar and filters
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
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
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterDropdown<CylinderStatus>(
                              label: 'Status',
                              value: _statusFilter,
                              items: CylinderStatus.values.map((status) {
                                return DropdownMenuItem<CylinderStatus>(
                                  value: status,
                                  child: Text(status.toString().split('.').last),
                                );
                              }).toList(),
                              onChanged: (CylinderStatus? value) {
                                setState(() {
                                  _statusFilter = value;
                                });
                                ref.read(cylinderProvider.notifier).setFilters(
                                  statusFilter: value?.toString().split('.').last,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterDropdown<GasType>(
                              label: 'Gas Type',
                              value: _gasTypeFilter,
                              items: GasType.values.map((type) {
                                return DropdownMenuItem<GasType>(
                                  value: type,
                                  child: Text(type.toString().split('.').last),
                                );
                              }).toList(),
                              onChanged: (GasType? value) {
                                setState(() {
                                  _gasTypeFilter = value;
                                });
                                ref.read(cylinderProvider.notifier).setFilters(
                                  gasTypeFilter: value,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterDropdown<int?>(
                              label: 'Factory',
                              value: _factoryIdFilter,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All Factories'),
                                ),
                                ...factories.map((factory) {
                                  return DropdownMenuItem<int?>(
                                    value: factory.id,
                                    child: Text(factory.name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (int? value) {
                                setState(() {
                                  _factoryIdFilter = value;
                                });
                                ref.read(cylinderProvider.notifier).setFilters(
                                  factoryIdFilter: value,
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _statusFilter = null;
                                  _gasTypeFilter = null;
                                  _factoryIdFilter = null;
                                  _searchQuery = '';
                                });
                                ref.read(cylinderProvider.notifier).clearFilters();
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'Total: ${filteredCylinders.length} cylinders',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (cylindersState.isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Cylinder list
                Expanded(
                  child: cylindersState.isLoading && cylinders.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : cylindersState.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading cylinders',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cylindersState.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => ref.read(cylinderProvider.notifier).fetchCylinders(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredCylinders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.propane_tank_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isNotEmpty || _statusFilter != null || 
                                        _gasTypeFilter != null || _factoryIdFilter != null
                                            ? 'No cylinders match your filters'
                                            : 'No cylinders found',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 16),
                                      if (canCreateCylinder)
                                        ElevatedButton.icon(
                                          onPressed: () => _navigateToCylinderDetail(context, null),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Cylinder'),
                                        ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () => ref.read(cylinderProvider.notifier).fetchCylinders(),
                                  child: ListView.builder(
                                    itemCount: filteredCylinders.length,
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    itemBuilder: (context, index) {
                                      final cylinder = filteredCylinders[index];
                                      return CylinderCard(
                                        cylinder: cylinder,
                                        onTap: () => _navigateToCylinderDetail(context, cylinder),
                                        showActions: true,
                                        onActionSelected: (action) => _handleCylinderAction(action, cylinder),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
      floatingActionButton: canCreateCylinder
          ? FloatingActionButton(
              onPressed: () => _navigateToCylinderDetail(context, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            isDense: true,
          ),
        ],
      ),
    );
  }

  void _navigateToCylinderDetail(BuildContext context, Cylinder? cylinder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CylinderDetailScreen(cylinder: cylinder),
      ),
    ).then((_) {
      // Refresh the list when returning
      ref.read(cylinderProvider.notifier).fetchCylinders();
    });
  }

  void _handleCylinderAction(String action, Cylinder cylinder) {
    switch (action) {
      case 'fill':
        Navigator.pushNamed(
          context,
          '/filling',
          arguments: {'cylinderId': cylinder.id},
        );
        break;
      case 'inspect':
        Navigator.pushNamed(
          context,
          '/inspection',
          arguments: {'cylinderId': cylinder.id},
        );
        break;
      case 'deliver':
        Navigator.pushNamed(
          context,
          '/delivery/add',
          arguments: {'cylinderId': cylinder.id},
        );
        break;
      case 'maintenance':
        Navigator.pushNamed(
          context,
          '/maintenance',
          arguments: {'cylinderId': cylinder.id},
        );
        break;
      case 'details':
        _navigateToCylinderDetail(context, cylinder);
        break;
      case 'history':
        // Navigate to cylinder history screen
        break;
      case 'qr':
        // Show QR code dialog
        break;
      default:
        break;
    }
  }
}
