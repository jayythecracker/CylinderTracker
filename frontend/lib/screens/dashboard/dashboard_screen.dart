import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/screens/factories/factories_screen.dart';
import 'package:cylinder_management/screens/cylinders/cylinders_screen.dart';
import 'package:cylinder_management/screens/customers/customers_screen.dart';
import 'package:cylinder_management/screens/filling/filling_screen.dart';
import 'package:cylinder_management/screens/inspection/inspection_screen.dart';
import 'package:cylinder_management/screens/sales/sales_screen.dart';
import 'package:cylinder_management/screens/reports/reports_screen.dart';
import 'package:cylinder_management/widgets/app_drawer.dart';
import 'package:cylinder_management/widgets/app_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final url = Uri.parse('${AppConfig.baseUrl}/reports/dashboard');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await ref.read(authProvider.notifier)._authService.getToken()}',
      },
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        return jsonData['data'];
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to fetch dashboard data');
      }
    } else {
      throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching dashboard data: $e');
  }
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const _DashboardHomePage(),
    const FactoriesScreen(),
    const CylindersScreen(),
    const CustomersScreen(),
    const FillingScreen(),
    const InspectionScreen(),
    const SalesScreen(),
    const ReportsScreen(),
  ];
  
  final List<String> _titles = [
    'Dashboard',
    'Factories',
    'Cylinders',
    'Customers',
    'Filling',
    'Inspection',
    'Sales',
    'Reports',
  ];
  
  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final user = ref.watch(authProvider).value;
    
    return Scaffold(
      key: scaffoldKey,
      appBar: CustomAppBar(
        title: _titles[_selectedIndex],
        onMenuPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: AppDrawer(
        currentIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class _DashboardHomePage extends ConsumerWidget {
  const _DashboardHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider).value;
    
    return dashboardStats.when(
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppConfig.primaryColor,
                            radius: 24,
                            child: Text(
                              user?.name.substring(0, 1) ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user?.name ?? 'User'}!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Role: ${user?.roleDisplayName ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
              
              const SizedBox(height: 16),
              
              // Activity summary section
              Text(
                "Today's Activity",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    title: 'Sales',
                    value: '${stats['today']['sales']}',
                    icon: Icons.monetization_on_outlined,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Fillings',
                    value: '${stats['today']['fillings']}',
                    icon: Icons.local_gas_station_outlined,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Inspections',
                    value: '${stats['today']['inspections']}',
                    icon: Icons.check_circle_outline,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Month Sales',
                    value: '\$${stats['monthSalesTotal'].toStringAsFixed(2)}',
                    icon: Icons.calendar_today_outlined,
                    color: Colors.purple,
                  ),
                  _StatCard(
                    title: 'Active Cylinders',
                    value: '${stats['counts']['activeCylinders']}',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.teal,
                  ),
                  _StatCard(
                    title: 'Total Cylinders',
                    value: '${stats['counts']['totalCylinders']}',
                    icon: Icons.warehouse_outlined,
                    color: Colors.indigo,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Cylinder status section
              Text(
                "Cylinder Status",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: stats['counts']['cylinderStatus']['Full']?.toDouble() ?? 0,
                                  title: 'Full',
                                  color: AppConfig.getStatusColor('Full'),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: stats['counts']['cylinderStatus']['Empty']?.toDouble() ?? 0,
                                  title: 'Empty',
                                  color: AppConfig.getStatusColor('Empty'),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: stats['counts']['cylinderStatus']['InTransit']?.toDouble() ?? 0,
                                  title: 'Transit',
                                  color: AppConfig.getStatusColor('InTransit'),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: stats['counts']['cylinderStatus']['Error']?.toDouble() ?? 0,
                                  title: 'Error',
                                  color: AppConfig.getStatusColor('Error'),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: stats['counts']['cylinderStatus']['InMaintenance']?.toDouble() ?? 0,
                                  title: 'Maint.',
                                  color: AppConfig.getStatusColor('InMaintenance'),
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LegendItem(
                                color: AppConfig.getStatusColor('Full'),
                                title: 'Full',
                                value: '${stats['counts']['cylinderStatus']['Full'] ?? 0}',
                              ),
                              _LegendItem(
                                color: AppConfig.getStatusColor('Empty'),
                                title: 'Empty',
                                value: '${stats['counts']['cylinderStatus']['Empty'] ?? 0}',
                              ),
                              _LegendItem(
                                color: AppConfig.getStatusColor('InTransit'),
                                title: 'In Transit',
                                value: '${stats['counts']['cylinderStatus']['InTransit'] ?? 0}',
                              ),
                              _LegendItem(
                                color: AppConfig.getStatusColor('Error'),
                                title: 'Error',
                                value: '${stats['counts']['cylinderStatus']['Error'] ?? 0}',
                              ),
                              _LegendItem(
                                color: AppConfig.getStatusColor('InMaintenance'),
                                title: 'Maintenance',
                                value: '${stats['counts']['cylinderStatus']['InMaintenance'] ?? 0}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick actions section
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ActionCard(
                    title: 'New Sale',
                    icon: Icons.add_shopping_cart,
                    color: Colors.green,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6; // Sales screen
                      });
                    },
                  ),
                  _ActionCard(
                    title: 'Start Filling',
                    icon: Icons.local_gas_station,
                    color: Colors.blue,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4; // Filling screen
                      });
                    },
                  ),
                  _ActionCard(
                    title: 'New Inspection',
                    icon: Icons.check_circle,
                    color: Colors.orange,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5; // Inspection screen
                      });
                    },
                  ),
                  _ActionCard(
                    title: 'Add Cylinder',
                    icon: Icons.add_circle,
                    color: Colors.purple,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2; // Cylinders screen
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.refresh(dashboardStatsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void setState(Function() callback) {
    // This method needs to be passed up to the parent widget to change the selected index
    // It will be implemented by the _DashboardScreenState class
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  
  const _LegendItem({
    Key? key,
    required this.color,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
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
}
