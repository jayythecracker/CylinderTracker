import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../utils/role_based_access.dart';
import '../../widgets/app_drawer.dart';
import 'create_sale_screen.dart';
import 'sales_history_screen.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isCustomerLoading = false;
  
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
    setState(() {
      _isCustomerLoading = true;
    });
    
    try {
      await ref.read(customersProvider.notifier).getCustomers(
        filters: {
          'search': _searchQuery.isEmpty ? null : _searchQuery,
          'page': 1,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCustomerLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshCustomers() async {
    setState(() {
      _searchQuery = _searchController.text;
    });
    await _loadCustomers();
  }
  
  Future<void> _loadSales(int customerId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load recent sales for this customer
      await ref.read(salesProvider.notifier).getSales(
        filters: {
          'customerId': customerId.toString(),
          'page': 1,
          'limit': 5,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sales: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).value;
    final customersAsync = ref.watch(customersProvider);
    
    // Check if user has seller access for creating sales
    final hasSellerAccess = RoleBasedAccess.hasRole(
      currentUser?.role ?? '',
      ['admin', 'manager', 'seller'],
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sales History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCustomers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search customers',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _loadCustomers();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _refreshCustomers(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _refreshCustomers,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasSellerAccess)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalesHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View All Sales'),
                  ),
              ],
            ),
          ),
          
          // Customers list
          Expanded(
            child: _isCustomerLoading
                ? const Center(child: CircularProgressIndicator())
                : customersAsync.when(
                    data: (customers) {
                      if (customers.isEmpty) {
                        return const Center(
                          child: Text('No customers found'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ExpansionTile(
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
                              trailing: hasSellerAccess
                                  ? ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CreateSaleScreen(customer: customer),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('New Sale'),
                                    )
                                  : null,
                              onExpansionChanged: (expanding) {
                                if (expanding) {
                                  _loadSales(customer.id);
                                }
                              },
                              children: [
                                _buildCustomerSales(customer),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
                            onPressed: _refreshCustomers,
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
  
  Widget _buildCustomerSales(Customer customer) {
    final salesAsync = ref.watch(salesProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text(
            'Recent Sales:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : salesAsync.when(
                  data: (sales) {
                    if (sales.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No recent sales for this customer'),
                      );
                    }
                    
                    return Column(
                      children: sales.map((sale) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              'Invoice: ${sale.invoiceNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${_formatDate(sale.saleDate)}'),
                                Text('Status: ${sale.status}'),
                                Text('Amount: \$${sale.totalAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SaleDetailsScreen(saleId: sale.id),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading sales: ${error.toString()}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesHistoryScreen(
                      initialCustomerId: customer.id,
                    ),
                  ),
                );
              },
              child: const Text('View All Sales History'),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
}

// CreateSaleScreen is a placeholder. The full implementation will go in a separate file.
class CreateSaleScreen extends StatelessWidget {
  final Customer customer;

  const CreateSaleScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Sale - ${customer.name}'),
      ),
      body: const Center(
        child: Text('Create Sale Screen - Implement in create_sale_screen.dart'),
      ),
    );
  }
}

// SaleDetailsScreen is a placeholder. The full implementation will go in sales_history_screen.dart
class SaleDetailsScreen extends StatelessWidget {
  final int saleId;

  const SaleDetailsScreen({Key? key, required this.saleId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Details - $saleId'),
      ),
      body: const Center(
        child: Text('Sale Details Screen - Implement in sale_details_screen.dart'),
      ),
    );
  }
}
