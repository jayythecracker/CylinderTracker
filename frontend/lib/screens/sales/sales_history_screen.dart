import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sale_provider.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  final int? initialCustomerId;
  
  const SalesHistoryScreen({Key? key, this.initialCustomerId}) : super(key: key);

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  String? _selectedDeliveryType;
  int? _selectedCustomerId;
  DateTimeRange? _dateRange;
  
  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
    _loadSales();
  }

  Future<void> _loadSales() async {
    // Create filter map based on selected filters
    final Map<String, dynamic> filters = {
      'page': 1,
    };

    if (_selectedStatus != null) {
      filters['status'] = _selectedStatus;
    }

    if (_selectedPaymentStatus != null) {
      filters['paymentStatus'] = _selectedPaymentStatus;
    }

    if (_selectedDeliveryType != null) {
      filters['deliveryType'] = _selectedDeliveryType;
    }

    if (_selectedCustomerId != null) {
      filters['customerId'] = _selectedCustomerId.toString();
    }

    if (_dateRange != null) {
      filters['startDate'] = _dateRange!.start.toIso8601String();
      filters['endDate'] = _dateRange!.end.toIso8601String();
    }

    await ref.read(salesProvider.notifier).getSales(
      filters: filters,
    );
  }

  Future<void> _refreshSales() async {
    ref.read(saleFilterProvider.notifier).state = {
      ...ref.read(saleFilterProvider),
      'page': 1,
    };
    await _loadSales();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentStatus = null;
      _selectedDeliveryType = null;
      if (widget.initialCustomerId == null) {
        _selectedCustomerId = null;
      }
      _dateRange = null;
    });
    _refreshSales();
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = _dateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _dateRange = newDateRange;
      });
      _refreshSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final paginationInfo = ref.watch(salePaginationProvider);
    final currentUser = ref.watch(authProvider).value;
    
    // Check if user has seller access for recording returns and making payments
    final hasSellerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'seller'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCustomerId != null 
            ? 'Customer Sales History' 
            : 'Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSales,
          ),
        ],
      ),
      drawer: widget.initialCustomerId == null ? const AppDrawer() : null,
      body: Column(
        children: [
          // Active filters display
          if (_selectedStatus != null || 
              _selectedPaymentStatus != null || 
              _selectedDeliveryType != null || 
              _dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (_selectedStatus != null)
                      Chip(
                        label: Text(_selectedStatus!),
                        onDeleted: () {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _refreshSales();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_selectedPaymentStatus != null)
                      Chip(
                        label: Text(_selectedPaymentStatus!),
                        onDeleted: () {
                          setState(() {
                            _selectedPaymentStatus = null;
                          });
                          _refreshSales();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_selectedDeliveryType != null)
                      Chip(
                        label: Text(_selectedDeliveryType!),
                        onDeleted: () {
                          setState(() {
                            _selectedDeliveryType = null;
                          });
                          _refreshSales();
                        },
                      ),
                    const SizedBox(width: 4),
                    if (_dateRange != null)
                      Chip(
                        label: Text(
                          '${DateFormat('MM/dd/yy').format(_dateRange!.start)} - '
                          '${DateFormat('MM/dd/yy').format(_dateRange!.end)}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _dateRange = null;
                          });
                          _refreshSales();
                        },
                      ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Sales list
          Expanded(
            child: salesAsync.when(
              data: (sales) => _buildSalesList(
                sales,
                paginationInfo,
                hasSellerAccess,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshSales,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesList(
    List<Sale> sales,
    Map<String, dynamic> paginationInfo,
    bool hasSellerAccess,
  ) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No sales found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (_selectedStatus != null || 
                _selectedPaymentStatus != null || 
                _selectedDeliveryType != null ||
                _dateRange != null)
              ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshSales,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(sale.status),
                      child: const Icon(
                        Icons.receipt,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Invoice: ${sale.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${sale.customer?.name ?? 'Unknown'}'),
                        Text('Date: ${DateFormat('MM/dd/yy').format(sale.saleDate)}'),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(sale.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sale.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(sale.status),
                                  fontWeight: FontWeight.bold,
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
                                color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sale.paymentStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPaymentStatusColor(sale.paymentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      '\$${sale.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            _buildSaleDetails(sale),
                            const SizedBox(height: 16),
                            if (hasSellerAccess) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (sale.status != 'Cancelled' && 
                                      sale.status != 'Completed' &&
                                      sale.paymentStatus != 'Paid')
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddPaymentDialog(sale),
                                      icon: const Icon(Icons.payments),
                                      label: const Text('Add Payment'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  if (sale.status == 'Pending')
                                    ElevatedButton.icon(
                                      onPressed: () => _showUpdateStatusDialog(sale),
                                      icon: const Icon(Icons.update),
                                      label: const Text('Update Status'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                    ),
                                  if (sale.status != 'Cancelled')
                                    ElevatedButton.icon(
                                      onPressed: () => _showRecordReturnDialog(sale),
                                      icon: const Icon(Icons.assignment_return),
                                      label: const Text('Record Return'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Pagination controls
        if (paginationInfo['totalPages'] > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: paginationInfo['currentPage'] > 1
                      ? () {
                          ref.read(saleFilterProvider.notifier).state = {
                            ...ref.read(saleFilterProvider),
                            'page': paginationInfo['currentPage'] - 1,
                          };
                          _loadSales();
                        }
                      : null,
                ),
                Text(
                  '${paginationInfo['currentPage']} of ${paginationInfo['totalPages']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: paginationInfo['currentPage'] < paginationInfo['totalPages']
                      ? () {
                          ref.read(saleFilterProvider.notifier).state = {
                            ...ref.read(saleFilterProvider),
                            'page': paginationInfo['currentPage'] + 1,
                          };
                          _loadSales();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaleDetails(Sale sale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic sale info
        _buildDetailItem('Invoice Number', sale.invoiceNumber),
        _buildDetailItem('Sale Date', DateFormat('MM/dd/yyyy HH:mm').format(sale.saleDate)),
        _buildDetailItem('Customer', sale.customer?.name ?? 'Unknown'),
        _buildDetailItem('Seller', sale.seller?.name ?? 'Unknown'),
        _buildDetailItem('Delivery Type', sale.deliveryType),
        if (sale.truck != null)
          _buildDetailItem('Truck', '${sale.truck!.licenseNumber} (${sale.truck!.type})'),
        _buildDetailItem('Status', sale.status),
        _buildDetailItem('Payment Method', sale.paymentMethod),
        _buildDetailItem('Payment Status', sale.paymentStatus),
        
        // Financial details
        const SizedBox(height: 8),
        const Text(
          'Financial Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        _buildDetailItem('Total Amount', '\$${sale.totalAmount.toStringAsFixed(2)}'),
        _buildDetailItem('Paid Amount', '\$${sale.paidAmount.toStringAsFixed(2)}'),
        _buildDetailItem('Outstanding', '\$${(sale.totalAmount - sale.paidAmount).toStringAsFixed(2)}'),
        
        // Delivery details
        const SizedBox(height: 8),
        const Text(
          'Delivery Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        _buildDetailItem('Delivery Address', sale.deliveryAddress ?? 'Not specified'),
        if (sale.deliveryDate != null)
          _buildDetailItem('Delivery Date', DateFormat('MM/dd/yyyy').format(sale.deliveryDate!)),
        
        // Notes
        if (sale.notes != null && sale.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(sale.notes!),
        ],
        
        // Cylinder items
        const SizedBox(height: 16),
        const Text(
          'Cylinder Items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (sale.items == null || sale.items!.isEmpty)
          const Text('No cylinder details available')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sale.items!.length,
            itemBuilder: (context, index) {
              final item = sale.items![index];
              final cylinder = item.cylinder;
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.returnedEmpty ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.propane_tank,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'SN: ${cylinder?.serialNumber ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${cylinder?.gasType ?? 'Unknown'}, Size: ${cylinder?.size ?? 'Unknown'}'),
                      Text('Price: \$${item.price.toStringAsFixed(2)}'),
                      if (item.returnedEmpty)
                        Text(
                          'Returned: ${DateFormat('MM/dd/yyyy').format(item.returnDate!)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                  trailing: item.returnedEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Text('Not Returned', style: TextStyle(color: Colors.orange)),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Delivered':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    // Create temporary variables to hold filter selections
    String? tempStatus = _selectedStatus;
    String? tempPaymentStatus = _selectedPaymentStatus;
    String? tempDeliveryType = _selectedDeliveryType;
    DateTimeRange? tempDateRange = _dateRange;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Sales'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: tempStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Delivered',
                        child: Text('Delivered'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Payment Statuses'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Paid',
                        child: Text('Paid'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Partial',
                        child: Text('Partial'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Unpaid',
                        child: Text('Unpaid'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempPaymentStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempDeliveryType,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Delivery Types'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Truck Delivery',
                        child: Text('Truck Delivery'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Customer Pickup',
                        child: Text('Customer Pickup'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempDeliveryType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      // Close the dialog temporarily
                      Navigator.pop(context);
                      // Show date picker
                      await _selectDateRange();
                      // Reopen the dialog
                      if (mounted) {
                        _showFilterDialog();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateRange == null
                            ? 'Select date range'
                            : '${DateFormat('MM/dd/yy').format(_dateRange!.start)} - '
                              '${DateFormat('MM/dd/yy').format(_dateRange!.end)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedStatus = tempStatus;
                    _selectedPaymentStatus = tempPaymentStatus;
                    _selectedDeliveryType = tempDeliveryType;
                    // _dateRange is already updated in the _selectDateRange method
                  });
                  _refreshSales();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateStatusDialog(Sale sale) {
    String selectedStatus = sale.status;
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDeliveryDate = sale.deliveryDate;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Sale Status'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: 'Delivered',
                        child: Text('Delivered'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (sale.deliveryType == 'Truck Delivery' && 
                      (selectedStatus == 'Delivered' || selectedStatus == 'Completed')) ...[
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDeliveryDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDeliveryDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Delivery Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDeliveryDate != null
                              ? DateFormat('MM/dd/yyyy').format(selectedDeliveryDate!)
                              : 'Select delivery date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).updateSaleStatus(
                            sale.id,
                            selectedStatus,
                            null, // Customer signature
                            selectedDeliveryDate,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _refreshSales();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sale status updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update status: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPaymentDialog(Sale sale) {
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    String paymentMethod = sale.paymentMethod;
    bool _isSubmitting = false;
    final double outstandingAmount = sale.totalAmount - sale.paidAmount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Amount: \$${sale.totalAmount.toStringAsFixed(2)}'),
                  Text('Already Paid: \$${sale.paidAmount.toStringAsFixed(2)}'),
                  Text(
                    'Outstanding: \$${outstandingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      if (amount > outstandingAmount) {
                        return 'Amount cannot exceed outstanding balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'Credit',
                        child: Text('Credit'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        paymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        // Validate amount
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0 || amount > outstandingAmount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).updateSalePayment(
                            sale.id,
                            amount,
                            paymentMethod,
                            notesController.text.isEmpty ? null : notesController.text,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _refreshSales();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment recorded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to record payment: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordReturnDialog(Sale sale) {
    if (sale.items == null || sale.items!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items available for this sale'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Filter out already returned cylinders
    final returnableCylinders = sale.items!.where((item) => !item.returnedEmpty).toList();
    
    if (returnableCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cylinders for this sale have already been returned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    int? selectedItemId;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Record Cylinder Return'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select cylinder to mark as returned:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  for (final item in returnableCylinders)
                    RadioListTile<int>(
                      title: Text('SN: ${item.cylinder?.serialNumber ?? 'Unknown'}'),
                      subtitle: Text('${item.cylinder?.size ?? ''} ${item.cylinder?.gasType ?? ''}'),
                      value: item.id,
                      groupValue: selectedItemId,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedItemId = value;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting || selectedItemId == null
                    ? null
                    : () async {
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).recordCylinderReturn(
                            selectedItemId!,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _refreshSales();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cylinder return recorded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to record return: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Return'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SaleDetailsScreen extends ConsumerStatefulWidget {
  final int saleId;

  const SaleDetailsScreen({Key? key, required this.saleId}) : super(key: key);

  @override
  ConsumerState<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends ConsumerState<SaleDetailsScreen> {
  bool _isLoading = true;
  Sale? _sale;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sale = await ref.read(salesProvider.notifier).getSaleById(widget.saleId);
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sale details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final hasSellerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'seller'],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Details - ${_sale?.invoiceNumber ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSaleDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sale == null
              ? const Center(child: Text('Sale not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sale status header
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Invoice: ${_sale!.invoiceNumber}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_sale!.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _sale!.status,
                                      style: TextStyle(
                                        color: _getStatusColor(_sale!.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Customer: ${_sale!.customer?.name ?? 'Unknown'}'),
                              Text('Date: ${DateFormat('MM/dd/yyyy').format(_sale!.saleDate)}'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total: \$${_sale!.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPaymentStatusColor(_sale!.paymentStatus).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _sale!.paymentStatus,
                                      style: TextStyle(
                                        color: _getPaymentStatusColor(_sale!.paymentStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Action buttons for seller
                      if (hasSellerAccess) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_sale!.status != 'Cancelled' && 
                                _sale!.status != 'Completed' &&
                                _sale!.paymentStatus != 'Paid')
                              ElevatedButton.icon(
                                onPressed: () => _showAddPaymentDialog(_sale!),
                                icon: const Icon(Icons.payments),
                                label: const Text('Add Payment'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            if (_sale!.status == 'Pending')
                              ElevatedButton.icon(
                                onPressed: () => _showUpdateStatusDialog(_sale!),
                                icon: const Icon(Icons.update),
                                label: const Text('Update Status'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            if (_sale!.status != 'Cancelled')
                              ElevatedButton.icon(
                                onPressed: () => _showRecordReturnDialog(_sale!),
                                icon: const Icon(Icons.assignment_return),
                                label: const Text('Record Return'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Sale details
                      const Text(
                        'Sale Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem('Seller', _sale!.seller?.name ?? 'Unknown'),
                      _buildDetailItem('Delivery Type', _sale!.deliveryType),
                      if (_sale!.truck != null)
                        _buildDetailItem('Truck', '${_sale!.truck!.licenseNumber} (${_sale!.truck!.type})'),
                      _buildDetailItem('Payment Method', _sale!.paymentMethod),
                      _buildDetailItem('Paid Amount', '\$${_sale!.paidAmount.toStringAsFixed(2)}'),
                      _buildDetailItem(
                        'Outstanding', 
                        '\$${(_sale!.totalAmount - _sale!.paidAmount).toStringAsFixed(2)}'
                      ),
                      
                      // Delivery details
                      const SizedBox(height: 16),
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailItem('Delivery Address', _sale!.deliveryAddress ?? 'Not specified'),
                      if (_sale!.deliveryDate != null)
                        _buildDetailItem(
                          'Delivery Date', 
                          DateFormat('MM/dd/yyyy').format(_sale!.deliveryDate!)
                        ),
                      
                      // Notes
                      if (_sale!.notes != null && _sale!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(_sale!.notes!),
                          ),
                        ),
                      ],
                      
                      // Cylinder items
                      const SizedBox(height: 16),
                      const Text(
                        'Cylinder Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_sale!.items == null || _sale!.items!.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No cylinder details available'),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _sale!.items!.length,
                          itemBuilder: (context, index) {
                            final item = _sale!.items![index];
                            final cylinder = item.cylinder;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.returnedEmpty ? Colors.grey : Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.propane_tank,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'SN: ${cylinder?.serialNumber ?? 'Unknown'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${cylinder?.gasType ?? 'Unknown'}, Size: ${cylinder?.size ?? 'Unknown'}'),
                                    Text('Price: \$${item.price.toStringAsFixed(2)}'),
                                    if (item.returnedEmpty)
                                      Text(
                                        'Returned: ${DateFormat('MM/dd/yyyy').format(item.returnDate!)}',
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                  ],
                                ),
                                trailing: item.returnedEmpty
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Text('Not Returned', style: TextStyle(color: Colors.orange)),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Delivered':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUpdateStatusDialog(Sale sale) {
    // Implementation similar to the one in SalesHistoryScreen
    String selectedStatus = sale.status;
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDeliveryDate = sale.deliveryDate;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Update Sale Status'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'In Progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: 'Delivered',
                        child: Text('Delivered'),
                      ),
                      DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'Cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (sale.deliveryType == 'Truck Delivery' && 
                      (selectedStatus == 'Delivered' || selectedStatus == 'Completed')) ...[
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDeliveryDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDeliveryDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Delivery Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDeliveryDate != null
                              ? DateFormat('MM/dd/yyyy').format(selectedDeliveryDate!)
                              : 'Select delivery date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).updateSaleStatus(
                            sale.id,
                            selectedStatus,
                            null, // Customer signature
                            selectedDeliveryDate,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _loadSaleDetails();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sale status updated successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update status: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPaymentDialog(Sale sale) {
    // Implementation similar to the one in SalesHistoryScreen
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    String paymentMethod = sale.paymentMethod;
    bool _isSubmitting = false;
    final double outstandingAmount = sale.totalAmount - sale.paidAmount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Amount: \$${sale.totalAmount.toStringAsFixed(2)}'),
                  Text('Already Paid: \$${sale.paidAmount.toStringAsFixed(2)}'),
                  Text(
                    'Outstanding: \$${outstandingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      if (amount > outstandingAmount) {
                        return 'Amount cannot exceed outstanding balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'Credit',
                        child: Text('Credit'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        paymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        // Validate amount
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0 || amount > outstandingAmount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).updateSalePayment(
                            sale.id,
                            amount,
                            paymentMethod,
                            notesController.text.isEmpty ? null : notesController.text,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _loadSaleDetails();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment recorded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to record payment: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordReturnDialog(Sale sale) {
    // Implementation similar to the one in SalesHistoryScreen
    if (sale.items == null || sale.items!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items available for this sale'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Filter out already returned cylinders
    final returnableCylinders = sale.items!.where((item) => !item.returnedEmpty).toList();
    
    if (returnableCylinders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All cylinders for this sale have already been returned'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    int? selectedItemId;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Record Cylinder Return'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select cylinder to mark as returned:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  for (final item in returnableCylinders)
                    RadioListTile<int>(
                      title: Text('SN: ${item.cylinder?.serialNumber ?? 'Unknown'}'),
                      subtitle: Text('${item.cylinder?.size ?? ''} ${item.cylinder?.gasType ?? ''}'),
                      value: item.id,
                      groupValue: selectedItemId,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedItemId = value;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting || selectedItemId == null
                    ? null
                    : () async {
                        setDialogState(() {
                          _isSubmitting = true;
                        });
                        
                        try {
                          await ref.read(salesProvider.notifier).recordCylinderReturn(
                            selectedItemId!,
                          );
                          
                          if (mounted) {
                            Navigator.pop(context);
                            _loadSaleDetails();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cylinder return recorded successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to record return: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() {
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Record Return'),
              ),
            ],
          );
        },
      ),
    );
  }
}
