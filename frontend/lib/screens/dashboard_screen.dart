import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cylinder.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/cylinder_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _isLoading = true;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load cylinder status data
      await ref.read(reportProvider.notifier).getCylinderStatusReport();
      
      // Load filling report data
      await ref.read(reportProvider.notifier).getFillingReport(
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
      );
      
      // Load delivery report data
      await ref.read(reportProvider.notifier).getDeliveryReport(
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final reportData = ref.watch(reportProvider);
    final cylinderStatusReport = reportData['cylinderStatus']?.data;
    final fillingReport = reportData['filling']?.data;
    final deliveryReport = reportData['delivery']?.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading dashboard data:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Card
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: kPrimaryColor.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome, ${currentUser?.name ?? 'User'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Role: ${currentUser?.role ?? 'Staff'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Today: ${_dateFormat.format(DateTime.now())}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date Range Selection
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report Period',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _startDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _startDate = date;
                                            });
                                            _loadData();
                                          }
                                        },
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(
                                          'From: ${_dateFormat.format(_startDate)}',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: _endDate,
                                            firstDate: _startDate,
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            setState(() {
                                              _endDate = date;
                                            });
                                            _loadData();
                                          }
                                        },
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(
                                          'To: ${_dateFormat.format(_endDate)}',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Cylinder Status Summary
                        if (cylinderStatusReport != null &&
                            cylinderStatusReport['statusReport'] != null)
                          _buildCylinderStatusCard(cylinderStatusReport),

                        const SizedBox(height: 20),

                        // Filling Activity
                        if (fillingReport != null &&
                            fillingReport['fillingData'] != null)
                          _buildFillingActivityCard(fillingReport),

                        const SizedBox(height: 20),

                        // Delivery Summary
                        if (deliveryReport != null &&
                            deliveryReport['deliveryData'] != null)
                          _buildDeliveryCard(deliveryReport),

                        const SizedBox(height: 20),

                        // Quick Actions
                        _buildQuickActionsCard(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCylinderStatusCard(Map<String, dynamic> cylinderStatusReport) {
    final statusList = (cylinderStatusReport['statusReport'] as List);
    final gasTypeList = (cylinderStatusReport['gasTypeReport'] as List);

    final statusMap = {
      for (var item in statusList)
        item['status'].toString(): int.parse(item['count'].toString())
    };

    final gasTypeMap = {
      for (var item in gasTypeList)
        item['gasType'].toString(): int.parse(item['count'].toString())
    };

    final List<Color> statusColors = [
      Colors.grey, // Empty
      Colors.green, // Full
      Colors.red, // Error
      Colors.blue, // InTransit
      Colors.orange, // InMaintenance
      Colors.purple, // InFilling
      Colors.amber, // InInspection
    ];

    final List<Color> gasTypeColors = [
      Colors.blue, // Medical
      Colors.green, // Industrial
    ];

    int total = statusMap.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cylinder Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Cylinders: $total',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Status Pie Chart
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _getPieSections(statusMap, statusColors),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: Column(
                    children: [
                      for (var entry in statusMap.entries)
                        _buildStatusIndicator(
                          entry.key,
                          entry.value,
                          statusColors[_getStatusIndex(entry.key)],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            const Text(
              'Gas Type Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var entry in gasTypeMap.entries)
                  Expanded(
                    child: Card(
                      color: gasTypeColors[entry.key == 'Medical' ? 0 : 1].withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 8.0,
                        ),
                        child: Column(
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Cylinders',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillingActivityCard(Map<String, dynamic> fillingReport) {
    final fillingData = (fillingReport['fillingData'] as List);
    final statusSummary = (fillingReport['statusSummary'] as List);

    // Calculate totals
    final totalInProgress = statusSummary.firstWhere(
            (item) => item['status'] == 'InProgress',
            orElse: () => {'count': 0})['count'] ??
        0;
    final totalCompleted = statusSummary.firstWhere(
            (item) => item['status'] == 'Completed',
            orElse: () => {'count': 0})['count'] ??
        0;
    final totalFailed = statusSummary.firstWhere(
            (item) => item['status'] == 'Failed',
            orElse: () => {'count': 0})['count'] ??
        0;
    
    // Group by date for the chart
    Map<String, int> fillingsByDate = {};
    for (var item in fillingData) {
      final date = item['date'].toString();
      fillingsByDate[date] = (fillingsByDate[date] ?? 0) + int.parse(item['count'].toString());
    }

    // Sort dates for the chart
    final sortedDates = fillingsByDate.keys.toList()..sort();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filling Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Summary
            Row(
              children: [
                _buildActivityCard(
                  'In Progress',
                  totalInProgress.toString(),
                  Colors.blue,
                  Icons.hourglass_top,
                ),
                _buildActivityCard(
                  'Completed',
                  totalCompleted.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildActivityCard(
                  'Failed',
                  totalFailed.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Chart
            if (sortedDates.isNotEmpty)
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 10,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                              final date = sortedDates[value.toInt()];
                              // Just show the day part for readability
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  date.split('-').last,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          interval: 5,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                        left: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          sortedDates.length,
                          (index) => FlSpot(
                            index.toDouble(),
                            fillingsByDate[sortedDates[index]]!.toDouble(),
                          ),
                        ),
                        isCurved: true,
                        color: kPrimaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: kPrimaryColor.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (sortedDates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No filling activity data for the selected period',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> deliveryReport) {
    final deliveryData = (deliveryReport['deliveryData'] as List);
    final statusSummary = (deliveryReport['statusSummary'] as List);

    // Calculate totals
    final totalPending = statusSummary.firstWhere(
            (item) => item['status'] == 'Pending',
            orElse: () => {'count': 0})['count'] ??
        0;
    final totalInTransit = statusSummary.firstWhere(
            (item) => item['status'] == 'InTransit',
            orElse: () => {'count': 0})['count'] ??
        0;
    final totalDelivered = statusSummary.firstWhere(
            (item) => item['status'] == 'Delivered',
            orElse: () => {'count': 0})['count'] ??
        0;
    final totalAmount = statusSummary.fold(
        0.0,
        (sum, item) =>
            sum + (item['totalAmount'] != null ? double.parse(item['totalAmount'].toString()) : 0.0));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Summary
            Row(
              children: [
                _buildActivityCard(
                  'Pending',
                  totalPending.toString(),
                  Colors.orange,
                  Icons.hourglass_bottom,
                ),
                _buildActivityCard(
                  'In Transit',
                  totalInTransit.toString(),
                  Colors.blue,
                  Icons.local_shipping,
                ),
                _buildActivityCard(
                  'Delivered',
                  totalDelivered.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Total Amount
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Colors.green[700],
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Sales',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    final currentUser = ref.watch(authProvider).user;
    final bool canManageCylinders = currentUser?.isAdmin == true || currentUser?.isManager == true;
    final bool canFill = currentUser?.isAdmin == true || currentUser?.isManager == true || currentUser?.isFiller == true;
    final bool canSell = currentUser?.isAdmin == true || currentUser?.isManager == true || currentUser?.isSeller == true;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: [
                if (canManageCylinders)
                  _buildActionButton(
                    'Add Cylinder',
                    Icons.add_circle,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/cylinders/add'),
                  ),
                if (canFill)
                  _buildActionButton(
                    'Start Filling',
                    Icons.opacity,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/filling'),
                  ),
                if (canFill || currentUser?.isAdmin == true)
                  _buildActionButton(
                    'Inspect Cylinders',
                    Icons.search,
                    Colors.amber[700]!,
                    () => Navigator.pushNamed(context, '/inspection'),
                  ),
                if (canSell)
                  _buildActionButton(
                    'New Delivery',
                    Icons.local_shipping,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/delivery/add'),
                  ),
                _buildActionButton(
                  'Scan QR Code',
                  Icons.qr_code_scanner,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/scanner'),
                ),
                if (currentUser?.isAdmin == true)
                  _buildActionButton(
                    'Reports',
                    Icons.bar_chart,
                    Colors.indigo,
                    () => Navigator.pushNamed(context, '/reports'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieSections(Map<String, int> statusMap, List<Color> colors) {
    List<PieChartSectionData> sections = [];
    int i = 0;
    statusMap.forEach((status, count) {
      final color = colors[_getStatusIndex(status)];
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '', // No title inside the chart for cleaner look
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });
    return sections;
  }

  int _getStatusIndex(String status) {
    switch (status) {
      case 'Empty':
        return 0;
      case 'Full':
        return 1;
      case 'Error':
        return 2;
      case 'InTransit':
        return 3;
      case 'InMaintenance':
        return 4;
      case 'InFilling':
        return 5;
      case 'InInspection':
        return 6;
      default:
        return 0;
    }
  }

  Widget _buildActivityCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
