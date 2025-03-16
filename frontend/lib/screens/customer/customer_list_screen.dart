import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/customer_card.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _searchQuery = '';
  CustomerType? _typeFilter;
  PaymentType? _paymentTypeFilter;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customerProvider);
    final customers = customersState.filteredCustomers;
    final currentUser = ref.watch(authProvider).user;
    
    // Filter customers based on search query
    final filteredCustomers = customers.where((customer) {
      final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           customer.contact.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           (customer.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesActive = _showInactive || customer.isActive;
      return matchesSearch && matchesActive;
    }).toList();

    final bool canCreateCustomer = currentUser?.isAdmin == true || 
                                  currentUser?.isManager == true || 
                                  currentUser?.isSeller == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerProvider.notifier).fetchCustomers(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search customers...',
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
                      _buildFilterDropdown<CustomerType?>(
                        label: 'Type',
                        value: _typeFilter,
                        items: [
                          const DropdownMenuItem<CustomerType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...CustomerType.values.map((type) {
                            return DropdownMenuItem<CustomerType?>(
                              value: type,
                              child: Text(kCustomerTypeNames[type.toString().split('.').last] ?? 'Unknown'),
                            );
                          }).toList(),
                        ],
                        onChanged: (CustomerType? value) {
                          setState(() {
                            _typeFilter = value;
                          });
                          ref.read(customerProvider.notifier).setFilters(
                            typeFilter: value,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown<PaymentType?>(
                        label: 'Payment',
                        value: _paymentTypeFilter,
                        items: [
                          const DropdownMenuItem<PaymentType?>(
                            value: null,
                            child: Text('All Payments'),
                          ),
                          const DropdownMenuItem<PaymentType?>(
                            value: PaymentType.Cash,
                            child: Text('Cash'),
                          ),
                          const DropdownMenuItem<PaymentType?>(
                            value: PaymentType.Credit,
                            child: Text('Credit'),
                          ),
                        ],
                        onChanged: (PaymentType? value) {
                          setState(() {
                            _paymentTypeFilter = value;
                          });
                          ref.read(customerProvider.notifier).setFilters(
                            paymentTypeFilter: value,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      FilterChip(
                        label: const Text('Show Inactive'),
                        selected: _showInactive,
                        onSelected: (value) {
                          setState(() {
                            _showInactive = value;
                          });
                          ref.read(customerProvider.notifier).toggleActiveFilter(!value);
                        },
                        checkmarkColor: Colors.white,
                        selectedColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: _showInactive ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _typeFilter = null;
                            _paymentTypeFilter = null;
                            _searchQuery = '';
                            _showInactive = false;
                          });
                          ref.read(customerProvider.notifier).clearFilters();
                          ref.read(customerProvider.notifier).toggleActiveFilter(true);
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
                        'Total: ${filteredCustomers.length} customers',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (customersState.isLoading)
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

          // Customer list
          Expanded(
            child: customersState.isLoading && customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : customersState.error != null
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
                              'Error loading customers',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customersState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(customerProvider.notifier).fetchCustomers(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _typeFilter != null || 
                                  _paymentTypeFilter != null
                                      ? 'No customers match your filters'
                                      : 'No customers found',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                if (canCreateCustomer)
                                  ElevatedButton.icon(
                                    onPressed: () => _navigateToCustomerDetail(context, null),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Customer'),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(customerProvider.notifier).fetchCustomers(),
                            child: ListView.builder(
                              itemCount: filteredCustomers.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return CustomerCard(
                                  customer: customer,
                                  onTap: () => _navigateToCustomerDetail(context, customer),
                                  showActions: true,
                                  onActionSelected: (action) => _handleCustomerAction(action, customer),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: canCreateCustomer
          ? FloatingActionButton(
              onPressed: () => _navigateToCustomerDetail(context, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T) onChanged,
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
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            isDense: true,
          ),
        ],
      ),
    );
  }

  void _navigateToCustomerDetail(BuildContext context, Customer? customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    ).then((_) {
      // Refresh the list when returning
      ref.read(customerProvider.notifier).fetchCustomers();
    });
  }

  void _handleCustomerAction(String action, Customer customer) {
    switch (action) {
      case 'details':
        _navigateToCustomerDetail(context, customer);
        break;
      case 'edit':
        _navigateToCustomerDetail(context, customer);
        break;
      case 'cylinders':
        Navigator.pushNamed(
          context,
          '/cylinders',
          arguments: {'customerId': customer.id},
        );
        break;
      case 'deliver':
        Navigator.pushNamed(
          context,
          '/delivery/add',
          arguments: {'customerId': customer.id},
        );
        break;
      case 'credit':
        _showUpdateBalanceDialog(customer);
        break;
      default:
        break;
    }
  }

  void _showUpdateBalanceDialog(Customer customer) {
    final amountController = TextEditingController();
    String transactionType = 'credit'; // Default to credit

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${customer.name}\'s Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Balance: ${customer.currentBalance < 0 ? "-" : ""}₹${customer.currentBalance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: customer.currentBalance < 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Credit'),
                    value: 'credit',
                    groupValue: transactionType,
                    onChanged: (value) {
                      setState(() {
                        transactionType = value!;
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Debit'),
                    value: 'debit',
                    groupValue: transactionType,
                    onChanged: (value) {
                      setState(() {
                        transactionType = value!;
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an amount')),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              Navigator.pop(context);
              
              try {
                final success = await ref.read(customerProvider.notifier).updateCustomerBalance(
                  customer.id,
                  amount,
                  transactionType,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Customer balance updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
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
}
