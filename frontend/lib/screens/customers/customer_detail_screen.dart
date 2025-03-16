import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/customer.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/providers/customer_provider.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/widgets/loading_indicator.dart';
import 'package:cylinder_management/widgets/error_display.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _salesCurrentPage = 1;
  final int _salesPageSize = 10;
  bool _hasMoreSales = true;
  bool _isLoadingMoreSales = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch customer details
    Future.microtask(() {
      ref.read(customerDetailsProvider(widget.customerId).notifier).fetchCustomerDetails();
      
      // Initialize sales tab data
      _fetchSales();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreSales &&
        _hasMoreSales) {
      _loadMoreSales();
    }
  }
  
  void _loadMoreSales() {
    if (_hasMoreSales && !_isLoadingMoreSales) {
      setState(() {
        _isLoadingMoreSales = true;
        _salesCurrentPage++;
      });
      
      _fetchSales(isLoadMore: true);
    }
  }
  
  Future<void> _fetchSales({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _salesCurrentPage = 1;
    }
    
    // Fetch customer sales
    await ref.read(customerSalesProvider(widget.customerId).notifier)
        .fetchCustomerSales(page: _salesCurrentPage, limit: _salesPageSize);
    
    // Update state after fetch
    if (mounted) {
      final salesData = ref.read(customerSalesProvider(widget.customerId));
      
      salesData.whenData((data) {
        final pagination = data['pagination'] as Map<String, dynamic>;
        final totalPages = pagination['totalPages'] as int;
        
        setState(() {
          _hasMoreSales = _salesCurrentPage < totalPages;
          _isLoadingMoreSales = false;
        });
      });
    }
  }
  
  Future<void> _refreshData() async {
    ref.refresh(customerDetailsProvider(widget.customerId));
    
    setState(() {
      _salesCurrentPage = 1;
      _hasMoreSales = true;
    });
    
    await _fetchSales();
  }

  @override
  Widget build(BuildContext context) {
    final customerData = ref.watch(customerDetailsProvider(widget.customerId));
    final user = ref.watch(authProvider).value;
    final bool canEdit = user != null && (user.isAdmin || user.isManager || user.isSeller);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: AppConfig.primaryColor,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                customerData.whenData((customer) {
                  if (customer != null) {
                    _showEditDialog(customer);
                  }
                });
              },
            ),
        ],
      ),
      body: customerData.when(
        data: (customer) {
          if (customer == null) {
            return const Center(
              child: Text('Customer not found'),
            );
          }
          
          return Column(
            children: [
              // Customer info header
              _buildCustomerHeader(customer),
              
              // Tab bar
              Container(
                color: AppConfig.primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Information'),
                    Tab(text: 'Sales History'),
                  ],
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(customer),
                    _buildSalesTab(),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: error.toString(),
          onRetry: () {
            ref.refresh(customerDetailsProvider(widget.customerId));
          },
        ),
      ),
      floatingActionButton: canEdit ? _buildFloatingActionButton() : null,
    );
  }
  
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Show action menu
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final RelativeRect position = RelativeRect.fromRect(
          Rect.fromPoints(
            button.localToGlobal(Offset.zero, ancestor: overlay),
            button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
          ),
          Offset.zero & overlay.size,
        );
        
        showMenu<String>(
          context: context,
          position: position,
          items: [
            const PopupMenuItem<String>(
              value: 'new_sale',
              child: Row(
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text('New Sale'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'adjust_balance',
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet),
                  SizedBox(width: 8),
                  Text('Adjust Balance'),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == 'new_sale') {
            // Navigate to new sale screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Create new sale functionality to be implemented'),
              ),
            );
          } else if (value == 'adjust_balance') {
            // Show balance adjustment dialog
            ref.read(customerDetailsProvider(widget.customerId)).whenData((customer) {
              if (customer != null) {
                _showBalanceAdjustmentDialog(customer);
              }
            });
          }
        });
      },
      backgroundColor: AppConfig.primaryColor,
      icon: const Icon(Icons.add),
      label: const Text('Actions'),
    );
  }

  Widget _buildCustomerHeader(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCustomerTypeColor(customer.type).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: _getCustomerTypeColor(customer.type),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _getCustomerTypeColor(customer.type),
            child: Icon(
              _getCustomerTypeIcon(customer.type),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(
                      customer.typeDisplayName,
                      _getCustomerTypeIcon(customer.type),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      customer.paymentType,
                      Icons.payment,
                    ),
                    if (customer.priceGroup != 'Standard') ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        customer.priceGroup,
                        Icons.loyalty,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!customer.active)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (customer.balance > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    'Balance: \$${customer.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Contact Number:', customer.contact),
                  if (customer.email != null && customer.email!.isNotEmpty)
                    _buildInfoRow('Email:', customer.email!),
                  _buildInfoRow('Address:', customer.address),
                ],
              ),
            ),
          ),
          
          // Account Information Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Customer Type:', customer.typeDisplayName),
                  _buildInfoRow('Payment Type:', customer.paymentType),
                  _buildInfoRow('Price Group:', customer.priceGroup),
                  if (customer.paymentType == 'Credit') ...[
                    if (customer.creditLimit != null)
                      _buildInfoRow(
                        'Credit Limit:',
                        '\$${customer.creditLimit!.toStringAsFixed(2)}',
                      ),
                    _buildInfoRow(
                      'Current Balance:',
                      '\$${customer.balance.toStringAsFixed(2)}',
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customer.balance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                  _buildInfoRow('Active:', customer.active ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
          
          // Sales Statistics Card
          if (customer.totalSales != null || customer.totalAmount != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    if (customer.totalSales != null)
                      _buildInfoRow(
                        'Total Orders:',
                        customer.totalSales.toString(),
                      ),
                    if (customer.totalAmount != null)
                      _buildInfoRow(
                        'Total Amount:',
                        '\$${customer.totalAmount!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),
            ),
          
          // Notes Card (if any)
          if (customer.notes != null && customer.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      customer.notes!,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final salesData = ref.watch(customerSalesProvider(widget.customerId));
    
    return salesData.when(
      data: (data) {
        final customer = data['customer'] as Customer;
        final sales = data['sales'] as List<Sale>;
        final pagination = data['pagination'] as Map<String, dynamic>;
        
        if (sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No sales history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This customer has no purchase history yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: sales.length + (_hasMoreSales ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == sales.length) {
                return _hasMoreSales
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              
              final sale = sales[index];
              return _buildSaleCard(sale);
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => ErrorDisplay(
        message: error.toString(),
        onRetry: _refreshData,
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and order ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(sale.saleDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '#${sale.id}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const Divider(),
              
              // Sale details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: \$${sale.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sale.cylinderCount > 0)
                        Text('Cylinders: ${sale.cylinderCount}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Payment status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.5),
                          ),
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
                      const SizedBox(height: 4),
                      // Delivery status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDeliveryStatusColor(sale.deliveryStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getDeliveryStatusColor(sale.deliveryStatus).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          sale.deliveryStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDeliveryStatusColor(sale.deliveryStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Delivery method and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        sale.isPickup ? Icons.store : Icons.local_shipping,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sale.deliveryMethod,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    timeFormat.format(sale.saleDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Sale Details'),
            const Spacer(),
            Text(
              '#${sale.id}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(sale.saleDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(sale.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sale.paymentStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPaymentStatusColor(sale.paymentStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Divider(),
              
              // Amount information
              _buildInfoRow('Total Amount:', '\$${sale.totalAmount.toStringAsFixed(2)}'),
              _buildInfoRow('Paid Amount:', '\$${sale.paidAmount.toStringAsFixed(2)}'),
              if (sale.remainingAmount > 0)
                _buildInfoRow(
                  'Remaining:',
                  '\$${sale.remainingAmount.toStringAsFixed(2)}',
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Delivery information
              _buildInfoRow('Delivery Method:', sale.deliveryMethod),
              _buildInfoRow('Delivery Status:', sale.deliveryStatus),
              if (sale.truck != null)
                _buildInfoRow('Truck:', '${sale.truck!.licenseNumber} (${sale.truck!.type})'),
              if (sale.deliveryDate != null)
                _buildInfoRow(
                  'Delivery Date:',
                  DateFormat('MMM dd, yyyy - HH:mm').format(sale.deliveryDate!),
                ),
              
              const SizedBox(height: 16),
              
              // Cylinders
              if (sale.cylinders != null && sale.cylinders!.isNotEmpty) ...[
                const Text(
                  'Cylinders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sale.cylinders!.length,
                  itemBuilder: (context, index) {
                    final item = sale.cylinders![index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.cylinder?.serialNumber ?? 'Unknown Cylinder'),
                      subtitle: Text(
                        '${item.cylinder?.type ?? 'Unknown'} - ${item.cylinder?.size ?? 'Unknown'}',
                      ),
                      trailing: Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
              
              // Notes
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                Text(sale.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textStyle ?? const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Customer customer) {
    // Create edit dialog similar to the one in customers_screen.dart
    // This is a simplified version that should be expanded
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: const Text('Editing functionality should be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showBalanceAdjustmentDialog(Customer customer) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String operation = 'add'; // 'add' or 'subtract'
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adjust Balance'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Current Balance
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Balance:'),
                        Text(
                          '\$${customer.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: customer.balance > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Operation type (add or subtract)
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Add'),
                          value: 'add',
                          groupValue: operation,
                          onChanged: (value) {
                            setState(() {
                              operation = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Subtract'),
                          value: 'subtract',
                          groupValue: operation,
                          onChanged: (value) {
                            setState(() {
                              operation = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Amount
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Reason for adjustment',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      
                      try {
                        final amount = double.parse(amountController.text);
                        
                        final updatedCustomer = await ref.read(customersProvider.notifier)
                            .updateCustomerBalance(
                              customer.id,
                              amount,
                              operation,
                              notesController.text.isEmpty ? null : notesController.text,
                            );
                        
                        if (mounted) {
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Balance ${operation == 'add' ? 'increased' : 'decreased'} by \$${amount.toStringAsFixed(2)}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          
                          _refreshData();
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = e.toString();
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Adjust'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      amountController.dispose();
      notesController.dispose();
    });
  }

  Color _getCustomerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'individual':
        return Colors.blue;
      case 'shop':
        return Colors.green;
      case 'factory':
        return Colors.purple;
      case 'workshop':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCustomerTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'individual':
        return Icons.person;
      case 'shop':
        return Icons.storefront;
      case 'factory':
        return Icons.factory;
      case 'workshop':
        return Icons.home_repair_service;
      default:
        return Icons.business;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'intransit':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
