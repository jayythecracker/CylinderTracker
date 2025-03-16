import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cylinder_provider.dart';
import '../../providers/report_provider.dart';
import '../../config/app_router.dart';
import '../../widgets/app_drawer.dart';
import '../../models/cylinder.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _cylinderStats = {};
  Map<String, dynamic> _salesStats = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Load dashboard data
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load cylinder status report
      final cylinderReport = await ref.read(reportProvider.notifier).getCylinderStatusReport();
      
      // Load daily sales report
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final salesReport = await ref.read(reportProvider.notifier).getDailySalesReport(date: today);
      
      setState(() {
        _cylinderStats = cylinderReport;
        _salesStats = salesReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current authenticated user
    final authState = ref.watch(authStateProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${user?.name ?? 'User'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Role: ${user?.role.displayName ?? ''}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Today: ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quick actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildActionCard(
                              context,
                              title: 'Cylinders',
                              icon: Icons.gas_cylinder_rounded,
                              onTap: () => Navigator.pushNamed(context, AppRouter.cylinderListRoute),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Filling',
                              icon: Icons.opacity,
                              onTap: () => Navigator.pushNamed(context, AppRouter.fillingRoute),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Inspection',
                              icon: Icons.fact_check,
                              onTap: () => Navigator.pushNamed(context, AppRouter.inspectionRoute),
                            ),
                            _buildActionCard(
                              context,
                              title: 'Sales',
                              icon: Icons.point_of_sale,
                              onTap: () => Navigator.pushNamed(context, AppRouter.salesRoute),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cylinder status overview
                        Text(
                          'Cylinder Status Overview',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Total Cylinders: ${_cylinderStats['totalCylinders'] ?? 0}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                _buildCylinderStatusChart(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Today's sales summary
                        Text(
                          'Today\'s Sales Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSalesStat(
                                      context,
                                      title: 'Total Sales',
                                      value: '${_salesStats['totalSales'] ?? 0}',
                                      icon: Icons.shopping_cart,
                                    ),
                                    _buildSalesStat(
                                      context,
                                      title: 'Amount',
                                      value: '\$${_salesStats['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                      icon: Icons.money,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSalesStat(
                                      context,
                                      title: 'Paid',
                                      value: '\$${_salesStats['totalPaid']?.toStringAsFixed(2) ?? '0.00'}',
                                      icon: Icons.payment,
                                      color: Colors.green,
                                    ),
                                    _buildSalesStat(
                                      context,
                                      title: 'Outstanding',
                                      value: '\$${_salesStats['totalOutstanding']?.toStringAsFixed(2) ?? '0.00'}',
                                      icon: Icons.account_balance_wallet,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // View reports button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRouter.reportRoute),
                            icon: const Icon(Icons.assessment),
                            label: const Text('View All Reports'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Build cylinder status chart
  Widget _buildCylinderStatusChart() {
    // Get status counts from data
    final statusCounts = _cylinderStats['statusCounts'] as List<dynamic>? ?? [];
    final Map<String, int> statusMap = {};
    
    for (final status in statusCounts) {
      statusMap[status['status']] = int.parse(status['count'].toString());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatusIndicator(
          context,
          title: 'Empty',
          count: statusMap['empty'] ?? 0,
          color: CylinderStatus.empty.color,
        ),
        _buildStatusIndicator(
          context,
          title: 'Filled',
          count: statusMap['filled'] ?? 0,
          color: CylinderStatus.filled.color,
        ),
        _buildStatusIndicator(
          context,
          title: 'Inspection',
          count: statusMap['inspection'] ?? 0,
          color: CylinderStatus.inspection.color,
        ),
        _buildStatusIndicator(
          context,
          title: 'Error',
          count: statusMap['error'] ?? 0,
          color: CylinderStatus.error.color,
        ),
      ],
    );
  }

  // Build status indicator
  Widget _buildStatusIndicator(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Build action card
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build sales stat
  Widget _buildSalesStat(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: color ?? Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
