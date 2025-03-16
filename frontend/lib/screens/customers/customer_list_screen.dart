import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedPaymentType;
  
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    await ref.read(customersProvider.notifier).getCustomers(
      filters: {
        'type': _selectedType,
        'paymentType': _selectedPaymentType,
        'search': _searchController.text.isEmpty ? null : _searchController.text,
        'page': 1,
      },
    );
  }

  Future<void> _refreshCustomers() async {
    // Reset page to 1 and refresh
    ref.read(customerFilterProvider.notifier).state = {
      ...ref.read(customerFilterProvider),
      'page': 1,
    };
    await _loadCustomers();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedPaymentType = null;
    });
    _refreshCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final customersAsync = ref.watch(customersProvider);
    final paginationInfo = ref.watch(customerPaginationProvider);
    
    // Check if user has access to create/edit customers
    final hasEditAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'seller'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCustomers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: hasEditAccess
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerFormScreen(),
                  ),
                ).then((_) => _loadCustomers());
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search customers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshCustomers();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _refreshCustomers(),
            ),
          ),
          
          // Active filters display
          if (_selectedType != null || _selectedPaymentType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text('Filters:'),
                  const SizedBox(width: 8),
                  if (_selectedType != null)
                    Chip(
                      label: Text(_selectedType!),
                      onDeleted: () {
                        setState(() {
                          _selectedType = null;
                        });
                        _refreshCustomers();
                      },
                    ),
                  const SizedBox(width: 4),
                  if (_selectedPaymentType != null)
                    Chip(
                      label: Text(_selectedPaymentType!),
                      onDeleted: () {
                        setState(() {
                          _selectedPaymentType = null;
                        });
                        _refreshCustomers();
                      },
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          // Customers list
          Expanded(
            child: customersAsync.when(
              data: (customers) => _buildCustomerList(
                customers,
                paginationInfo,
                hasEditAccess,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Error: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(
    List<Customer> customers,
    Map<String, dynamic> paginationInfo,
    bool hasEditAccess,
  ) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers found'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshCustomers,
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(customer.type),
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type: ${customer.type}'),
                        Text('Contact: ${customer.contactNumber}'),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: customer.paymentType == 'Credit'
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.paymentType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: customer.paymentType == 'Credit'
                                      ? Colors.orange
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (customer.paymentType == 'Credit') ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Credit: \$${customer.currentCredit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: hasEditAccess
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              ref.read(selectedCustomerProvider.notifier).state = customer;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerFormScreen(customerId: customer.id),
                                ),
                              ).then((_) => _loadCustomers());
                            },
                          )
                        : null,
                    onTap: () => _showCustomerDetails(customer, hasEditAccess),
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
                          ref.read(customerFilterProvider.notifier).state = {
                            ...ref.read(customerFilterProvider),
                            'page': paginationInfo['currentPage'] - 1,
                          };
                          _loadCustomers();
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
                          ref.read(customerFilterProvider.notifier).state = {
                            ...ref.read(customerFilterProvider),
                            'page': paginationInfo['currentPage'] + 1,
                          };
                          _loadCustomers();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Hospital':
        return Colors.red;
      case 'Factory':
        return Colors.blue;
      case 'Shop':
        return Colors.green;
      case 'Workshop':
        return Colors.orange;
      case 'Individual':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showCustomerDetails(Customer customer, bool hasEditAccess) {
    final currentUser = ref.read(authProvider).value;
    final hasAdminOrManagerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Type', customer.type),
              _buildDetailItem('Address', customer.address),
              if (customer.contactPerson != null)
                _buildDetailItem('Contact Person', customer.contactPerson!),
              _buildDetailItem('Contact Number', customer.contactNumber),
              if (customer.email != null) _buildDetailItem('Email', customer.email!),
              _buildDetailItem('Payment Type', customer.paymentType),
              if (customer.priceGroup != null)
                _buildDetailItem('Price Group', customer.priceGroup!),
              if (customer.paymentType == 'Credit') ...[
                _buildDetailItem('Credit Limit', '\$${customer.creditLimit.toStringAsFixed(2)}'),
                _buildDetailItem(
                  'Current Credit',
                  '\$${customer.currentCredit.toStringAsFixed(2)}',
                ),
              ],
              _buildDetailItem('Created', customer.createdAt.toString().substring(0, 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (hasEditAccess)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(selectedCustomerProvider.notifier).state = customer;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerFormScreen(customerId: customer.id),
                  ),
                ).then((_) => _loadCustomers());
              },
              child: const Text('Edit'),
            ),
          if (hasAdminOrManagerAccess && customer.paymentType == 'Credit')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showUpdateCreditDialog(customer);
              },
              child: const Text('Update Credit'),
            ),
        ],
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

  void _showUpdateCreditDialog(Customer customer) {
    final TextEditingController amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String operation = 'add';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Credit for ${customer.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Credit: \$${customer.currentCredit.toStringAsFixed(2)}'),
              Text('Credit Limit: \$${customer.creditLimit.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: operation,
                decoration: const InputDecoration(
                  labelText: 'Operation',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'add',
                    child: Text('Add Credit'),
                  ),
                  DropdownMenuItem(
                    value: 'subtract',
                    child: Text('Subtract Credit'),
                  ),
                ],
                onChanged: (value) {
                  operation = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
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
                  return null;
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
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final amount = double.parse(amountController.text);
                  await ref.read(customersProvider.notifier).updateCustomerCredit(
                        customer.id,
                        amount,
                        operation,
                      );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer credit updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _refreshCustomers();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update credit: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Create temporary variables to hold filter selections
    String? tempType = _selectedType;
    String? tempPaymentType = _selectedPaymentType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Customers'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: tempType,
                    decoration: const InputDecoration(
                      labelText: 'Customer Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      for (final type in ['Hospital', 'Individual', 'Shop', 'Factory', 'Workshop'])
                        DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempPaymentType,
                    decoration: const InputDecoration(
                      labelText: 'Payment Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Payment Types'),
                      ),
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
                        tempPaymentType = value;
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
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedType = tempType;
                    _selectedPaymentType = tempPaymentType;
                  });
                  _refreshCustomers();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
