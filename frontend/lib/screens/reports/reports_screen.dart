import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final reportDataProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  try {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    
    if (user == null) {
      throw Exception('Not authenticated');
    }
    
    final reportType = params['reportType'];
    final startDate = params['startDate'];
    final endDate = params['endDate'];
    
    final url = Uri.parse('${AppConfig.baseUrl}/reports/$reportType');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await ref.read(authProvider.notifier)._authService.getToken()}',
      },
      body: json.encode({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      }),
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        return jsonData['data'];
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to fetch report data');
      }
    } else {
      throw Exception('Failed to fetch report data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching report data: $e');
  }
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReportType = 'inventory';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isGenerating = false;

  final Map<String, String> _reportTypes = {
    'inventory': 'Inventory Report',
    'sales': 'Sales Report',
    'operations': 'Operations Report',
    'customers': 'Customer Accounts Report',
    'maintenance': 'Maintenance Report',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report selection section
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
                    Text(
                      'Generate Reports',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Report Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Report Type',
                        prefixIcon: Icon(Icons.description),
                      ),
                      value: _selectedReportType,
                      items: _reportTypes.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedReportType = value;
                            _reportData = null;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date Range Selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              
                              if (pickedDate != null && pickedDate != _startDate) {
                                setState(() {
                                  _startDate = pickedDate;
                                  _reportData = null;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now(),
                              );
                              
                              if (pickedDate != null && pickedDate != _endDate) {
                                setState(() {
                                  _endDate = pickedDate;
                                  _reportData = null;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating
                            ? null
                            : () {
                                setState(() {
                                  _isGenerating = true;
                                });
                                
                                ref.read(
                                  reportDataProvider(
                                    {
                                      'reportType': _selectedReportType,
                                      'startDate': _startDate,
                                      'endDate': _endDate,
                                    },
                                  ).future,
                                ).then((data) {
                                  setState(() {
                                    _reportData = data;
                                    _isGenerating = false;
                                  });
                                }).catchError((error) {
                                  setState(() {
                                    _isGenerating = false;
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${error.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                              },
                        icon: _isGenerating
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isGenerating ? 'Generating...' : 'Generate Report'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Report Results Section
            if (_reportData != null) ...[
              Text(
                '${_reportTypes[_selectedReportType]} Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Different report layouts based on type
              if (_selectedReportType == 'inventory')
                _buildInventoryReport(context, _reportData!)
              else if (_selectedReportType == 'sales')
                _buildSalesReport(context, _reportData!)
              else if (_selectedReportType == 'operations')
                _buildOperationsReport(context, _reportData!)
              else if (_selectedReportType == 'customers')
                _buildCustomersReport(context, _reportData!)
              else if (_selectedReportType == 'maintenance')
                _buildMaintenanceReport(context, _reportData!),
              
              const SizedBox(height: 24),
              
              // Export/Share Options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Export as PDF
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export as PDF feature coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export as PDF'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Export as Excel
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export as Excel feature coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export as Excel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryReport(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inventory Summary
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSummaryTile(
              'Total Cylinders',
              data['totalCylinders'].toString(),
              Icons.timeline,
              Colors.blue,
            ),
            _buildSummaryTile(
              'Available Full Cylinders',
              data['fullCylinders'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildSummaryTile(
              'Empty Cylinders',
              data['emptyCylinders'].toString(),
              Icons.remove_circle,
              Colors.orange,
            ),
            _buildSummaryTile(
              'Cylinders in Maintenance',
              data['maintenanceCylinders'].toString(),
              Icons.build,
              Colors.red,
            ),
            _buildSummaryTile(
              'Cylinders in Transit',
              data['transitCylinders'].toString(),
              Icons.local_shipping,
              Colors.purple,
            ),
            
            const Divider(),
            
            // Factory Distribution
            Text(
              'Distribution by Factory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['factoryDistribution'].length,
              itemBuilder: (context, index) {
                final factory = data['factoryDistribution'][index];
                return ListTile(
                  title: Text(factory['name']),
                  subtitle: Text('${factory['count']} cylinders'),
                  trailing: Text('${factory['percentage']}%'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      factory['name'].substring(0, 1),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // Cylinder Type Distribution
            Text(
              'Distribution by Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeStat(
                    'Medical',
                    data['medicalCylinders'],
                    data['totalCylinders'],
                    Colors.teal,
                  ),
                ),
                Expanded(
                  child: _buildTypeStat(
                    'Industrial',
                    data['industrialCylinders'],
                    data['totalCylinders'],
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesReport(BuildContext context, Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Summary
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSummaryTile(
              'Total Sales',
              currencyFormat.format(data['totalSales']),
              Icons.attach_money,
              Colors.green,
            ),
            _buildSummaryTile(
              'Number of Transactions',
              data['transactionCount'].toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            _buildSummaryTile(
              'Average Sale Value',
              currencyFormat.format(data['averageSaleValue']),
              Icons.analytics,
              Colors.purple,
            ),
            _buildSummaryTile(
              'Cylinders Sold',
              data['cylindersSold'].toString(),
              Icons.shopping_cart,
              Colors.orange,
            ),
            
            const Divider(),
            
            // Sales by Customer Type
            Text(
              'Sales by Customer Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['salesByCustomerType'].length,
              itemBuilder: (context, index) {
                final item = data['salesByCustomerType'][index];
                return ListTile(
                  title: Text(item['type']),
                  subtitle: Text('${item['count']} sales'),
                  trailing: Text(currencyFormat.format(item['amount'])),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(
                      item['type'].substring(0, 1),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // Top Customers
            Text(
              'Top 5 Customers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['topCustomers'].length,
              itemBuilder: (context, index) {
                final customer = data['topCustomers'][index];
                return ListTile(
                  title: Text(customer['name']),
                  subtitle: Text('${customer['salesCount']} sales'),
                  trailing: Text(currencyFormat.format(customer['totalAmount'])),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsReport(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operations Summary
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSummaryTile(
              'Total Fillings',
              data['totalFillings'].toString(),
              Icons.local_gas_station,
              Colors.blue,
            ),
            _buildSummaryTile(
              'Total Inspections',
              data['totalInspections'].toString(),
              Icons.search,
              Colors.teal,
            ),
            _buildSummaryTile(
              'Failed Inspections',
              data['failedInspections'].toString(),
              Icons.error_outline,
              Colors.red,
            ),
            _buildSummaryTile(
              'Maintenance Operations',
              data['maintenanceOperations'].toString(),
              Icons.build,
              Colors.orange,
            ),
            
            const Divider(),
            
            // Filling Efficiency
            Text(
              'Filling Efficiency',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: data['fillingEfficiency'] / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Efficiency: ${data['fillingEfficiency']}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Average filling time: ${data['averageFillingTime']} minutes',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            
            const Divider(),
            
            // Operator Performance
            Text(
              'Top Operators',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['topOperators'].length,
              itemBuilder: (context, index) {
                final operator = data['topOperators'][index];
                return ListTile(
                  title: Text(operator['name']),
                  subtitle: Text('${operator['fillings']} fillings'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${operator['efficiency']}%'),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        color: operator['efficiency'] > 90
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(
                      operator['name'].substring(0, 1),
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersReport(BuildContext context, Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Summary
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSummaryTile(
              'Total Customers',
              data['totalCustomers'].toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildSummaryTile(
              'New Customers',
              data['newCustomers'].toString(),
              Icons.person_add,
              Colors.green,
            ),
            _buildSummaryTile(
              'Active Customers',
              data['activeCustomers'].toString(),
              Icons.check_circle,
              Colors.teal,
            ),
            _buildSummaryTile(
              'Total Outstanding',
              currencyFormat.format(data['totalOutstanding']),
              Icons.account_balance_wallet,
              Colors.red,
            ),
            
            const Divider(),
            
            // Customer by Type
            Text(
              'Customers by Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['customersByType'].length,
              itemBuilder: (context, index) {
                final type = data['customersByType'][index];
                return ListTile(
                  title: Text(type['type']),
                  subtitle: Text('${type['count']} customers'),
                  trailing: Text('${type['percentage']}%'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: Text(
                      type['type'].substring(0, 1),
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // Outstanding Payments
            Text(
              'Outstanding Payments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['outstandingPayments'].length,
              itemBuilder: (context, index) {
                final customer = data['outstandingPayments'][index];
                return ListTile(
                  title: Text(customer['name']),
                  subtitle: Text('Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(customer['dueDate']))}'),
                  trailing: Text(
                    currencyFormat.format(customer['amount']),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    child: Text(
                      customer['name'].substring(0, 1),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceReport(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Maintenance Summary
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSummaryTile(
              'Total Maintenance',
              data['totalMaintenance'].toString(),
              Icons.build,
              Colors.blue,
            ),
            _buildSummaryTile(
              'Completed Maintenance',
              data['completedMaintenance'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildSummaryTile(
              'Pending Maintenance',
              data['pendingMaintenance'].toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
            _buildSummaryTile(
              'Scrapped Cylinders',
              data['scrappedCylinders'].toString(),
              Icons.delete_forever,
              Colors.red,
            ),
            
            const Divider(),
            
            // Maintenance by Type
            Text(
              'Issues by Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data['issuesByType'].length,
              itemBuilder: (context, index) {
                final issue = data['issuesByType'][index];
                return ListTile(
                  title: Text(issue['type']),
                  subtitle: Text('${issue['count']} instances'),
                  trailing: Text('${issue['percentage']}%'),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.report_problem,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
            
            const Divider(),
            
            // Maintenance Efficiency
            Text(
              'Maintenance Efficiency',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildEfficiencyStat(
                    'Resolution Rate',
                    data['resolutionRate'],
                    100,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildEfficiencyStat(
                    'Avg Resolution Time',
                    data['avgResolutionTime'],
                    data['targetResolutionTime'],
                    Colors.orange,
                    suffix: ' hours',
                    isTime: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets for building report elements
  Widget _buildSummaryTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildTypeStat(String title, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
    
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value cylinders',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyStat(
    String title,
    dynamic value,
    dynamic target,
    Color color, {
    String suffix = '%',
    bool isTime = false,
  }) {
    // For time metrics, lower is better
    final percentage = isTime
        ? target > 0
            ? ((target - value) / target * 100).clamp(0, 100)
            : 0
        : (value / target * 100).clamp(0, 100);
    
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value$suffix',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}