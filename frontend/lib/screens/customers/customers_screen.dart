import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/customer.dart';
import 'package:cylinder_management/providers/customer_provider.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/screens/customers/customer_detail_screen.dart';
import 'package:cylinder_management/widgets/customer_card.dart';
import 'package:cylinder_management/widgets/loading_indicator.dart';
import 'package:cylinder_management/widgets/error_display.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  // Search and filter state
  String _searchQuery = '';
  String? _typeFilter;
  String? _paymentTypeFilter;
  bool _showOnlyActive = true;
  
  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Fetch initial data
    Future.microtask(() => _fetchCustomers());
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }
  
  void _loadMoreData() {
    if (_hasMoreData && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
      
      _fetchCustomers(isLoadMore: true);
    }
  }
  
  Future<void> _fetchCustomers({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      _currentPage = 1;
    }
    
    // Build filter parameters
    final filters = <String, dynamic>{
      'page': _currentPage,
      'limit': _pageSize,
    };
    
    if (_searchQuery.isNotEmpty) {
      filters['search'] = _searchQuery;
    }
    
    if (_typeFilter != null) {
      filters['type'] = _typeFilter;
    }
    
    if (_paymentTypeFilter != null) {
      filters['paymentType'] = _paymentTypeFilter;
    }
    
    if (_showOnlyActive) {
      filters['active'] = true;
    }
    
    // Fetch customers
    await ref.read(customersProvider.notifier).fetchCustomers(
      filters: filters,
      page: _currentPage,
      limit: _pageSize,
    );
    
    // Update state after fetch
    if (mounted) {
      final customersData = ref.read(customersProvider);
      
      customersData.whenData((data) {
        final pagination = data['pagination'] as Map<String, dynamic>;
        final totalPages = pagination['totalPages'] as int;
        
        setState(() {
          _hasMoreData = _currentPage < totalPages;
          _isLoadingMore = false;
        });
      });
    }
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    await _fetchCustomers();
  }
  
  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _typeFilter = null;
      _paymentTypeFilter = null;
      _showOnlyActive = true;
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    _fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final customersData = ref.watch(customersProvider);
    
    final bool canEdit = user != null && (user.isAdmin || user.isManager || user.isSeller);
    
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
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
                    onSubmitted: (_) => _refreshData(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onPressed: () => _showFilterDialog(),
                ),
              ],
            ),
          ),
          
          // Active filters display
          if (_typeFilter != null || _paymentTypeFilter != null || !_showOnlyActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_typeFilter != null)
                      _buildFilterChip(
                        'Type: $_typeFilter',
                        () {
                          setState(() {
                            _typeFilter = null;
                          });
                          _refreshData();
                        },
                      ),
                    if (_paymentTypeFilter != null)
                      _buildFilterChip(
                        'Payment: $_paymentTypeFilter',
                        () {
                          setState(() {
                            _paymentTypeFilter = null;
                          });
                          _refreshData();
                        },
                      ),
                    if (!_showOnlyActive)
                      _buildFilterChip(
                        'Show Inactive',
                        () {
                          setState(() {
                            _showOnlyActive = true;
                          });
                          _refreshData();
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: _resetFilters,
                    ),
                  ],
                ),
              ),
            ),
          
          // Customers list
          Expanded(
            child: customersData.when(
              data: (data) {
                final customers = data['customers'] as List<Customer>;
                final pagination = data['pagination'] as Map<String, dynamic>;
                
                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 72,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first customer or adjust filters',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (canEdit)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Customer'),
                              onPressed: _showAddCustomerDialog,
                            ),
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
                    itemCount: customers.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == customers.length) {
                        return _hasMoreData
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      final customer = customers[index];
                      return CustomerCard(
                        customer: customer,
                        onTap: () => _navigateToCustomerDetail(customer),
                        actions: canEdit
                            ? [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showEditCustomerDialog(customer),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showCustomerActions(customer),
                                  tooltip: 'More Actions',
                                ),
                              ]
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                onRetry: _refreshData,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: _showAddCustomerDialog,
              backgroundColor: AppConfig.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
        deleteIconColor: AppConfig.primaryColor,
        onDeleted: onRemove,
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Customers'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('All', null, _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Hospital', 'Hospital', _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Individual', 'Individual', _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Shop', 'Shop', _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Factory', 'Factory', _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                      _buildFilterOption('Workshop', 'Workshop', _typeFilter, (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Payment Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterOption('All', null, _paymentTypeFilter, (value) {
                        setState(() {
                          _paymentTypeFilter = value;
                        });
                      }),
                      _buildFilterOption('Cash', 'Cash', _paymentTypeFilter, (value) {
                        setState(() {
                          _paymentTypeFilter = value;
                        });
                      }),
                      _buildFilterOption('Credit', 'Credit', _paymentTypeFilter, (value) {
                        setState(() {
                          _paymentTypeFilter = value;
                        });
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Show only active customers'),
                    value: _showOnlyActive,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetFilters();
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshData();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFilterOption(
    String label,
    String? value,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    final isSelected = value == selectedValue;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? value : null);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppConfig.primaryColor.withOpacity(0.2),
    );
  }
  
  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customerId: customer.id),
      ),
    ).then((_) {
      // Refresh data when returning from detail screen
      _refreshData();
    });
  }
  
  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    
    String type = 'Individual';
    String paymentType = 'Cash';
    String priceGroup = 'Standard';
    final creditLimitController = TextEditingController();
    
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Customer'),
            content: SingleChildScrollView(
              child: Form(
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
                    
                    // Customer Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Customer Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Customer Type *',
                      ),
                      value: type,
                      items: ['Hospital', 'Individual', 'Shop', 'Factory', 'Workshop']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          type = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Payment Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Type *',
                      ),
                      value: paymentType,
                      items: ['Cash', 'Credit']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          paymentType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Price Group
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Price Group *',
                      ),
                      value: priceGroup,
                      items: ['Standard', 'Premium', 'Wholesale', 'VIP']
                          .map((group) => DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          priceGroup = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Credit Limit (only if payment type is Credit)
                    if (paymentType == 'Credit')
                      TextFormField(
                        controller: creditLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Credit Limit *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (paymentType == 'Credit') {
                            if (value == null || value.isEmpty) {
                              return 'Please enter credit limit';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
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
                        final customerData = {
                          'name': nameController.text,
                          'type': type,
                          'address': addressController.text,
                          'contact': contactController.text,
                          'email': emailController.text.isEmpty ? null : emailController.text,
                          'paymentType': paymentType,
                          'priceGroup': priceGroup,
                          'creditLimit': paymentType == 'Credit' && creditLimitController.text.isNotEmpty
                              ? double.parse(creditLimitController.text)
                              : null,
                          'notes': notesController.text.isEmpty ? null : notesController.text,
                        };
                        
                        final customer = await ref.read(customersProvider.notifier)
                            .createCustomer(customerData);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer created successfully'),
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
                  child: const Text('Create'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
      addressController.dispose();
      contactController.dispose();
      emailController.dispose();
      creditLimitController.dispose();
      notesController.dispose();
    });
  }
  
  void _showEditCustomerDialog(Customer customer) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final addressController = TextEditingController(text: customer.address);
    final contactController = TextEditingController(text: customer.contact);
    final emailController = TextEditingController(text: customer.email ?? '');
    final notesController = TextEditingController(text: customer.notes ?? '');
    
    String type = customer.type;
    String paymentType = customer.paymentType;
    String priceGroup = customer.priceGroup;
    final creditLimitController = TextEditingController(
      text: customer.creditLimit?.toString() ?? '',
    );
    bool active = customer.active;
    
    bool isLoading = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Customer'),
            content: SingleChildScrollView(
              child: Form(
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
                    
                    // Customer Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Customer Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Customer Type *',
                      ),
                      value: type,
                      items: ['Hospital', 'Individual', 'Shop', 'Factory', 'Workshop']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          type = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Contact
                    TextFormField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Payment Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Payment Type *',
                      ),
                      value: paymentType,
                      items: ['Cash', 'Credit']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          paymentType = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Price Group
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Price Group *',
                      ),
                      value: priceGroup,
                      items: ['Standard', 'Premium', 'Wholesale', 'VIP']
                          .map((group) => DropdownMenuItem(
                                value: group,
                                child: Text(group),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          priceGroup = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Credit Limit (only if payment type is Credit)
                    if (paymentType == 'Credit')
                      TextFormField(
                        controller: creditLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Credit Limit *',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (paymentType == 'Credit') {
                            if (value == null || value.isEmpty) {
                              return 'Please enter credit limit';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Active Status
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (value) {
                        setState(() {
                          active = value;
                        });
                      },
                    ),
                  ],
                ),
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
                        final customerData = {
                          'name': nameController.text,
                          'type': type,
                          'address': addressController.text,
                          'contact': contactController.text,
                          'email': emailController.text.isEmpty ? null : emailController.text,
                          'paymentType': paymentType,
                          'priceGroup': priceGroup,
                          'creditLimit': paymentType == 'Credit' && creditLimitController.text.isNotEmpty
                              ? double.parse(creditLimitController.text)
                              : null,
                          'active': active,
                          'notes': notesController.text.isEmpty ? null : notesController.text,
                        };
                        
                        final updatedCustomer = await ref.read(customersProvider.notifier)
                            .updateCustomer(customer.id, customerData);
                        
                        if (mounted) {
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer updated successfully'),
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
                  child: const Text('Update'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
      addressController.dispose();
      contactController.dispose();
      emailController.dispose();
      creditLimitController.dispose();
      notesController.dispose();
    });
  }
  
  void _showCustomerActions(Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                customer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('${customer.typeDisplayName}, ${customer.paymentType}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCustomerDetail(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(context);
                _showEditCustomerDialog(customer);
              },
            ),
            if (customer.paymentType == 'Credit')
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Adjust Balance'),
                onTap: () {
                  Navigator.pop(context);
                  _showBalanceAdjustmentDialog(customer);
                },
              ),
            if (customer.active)
              ListTile(
                leading: Icon(Icons.block, color: Colors.red.shade300),
                title: const Text('Deactivate Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeactivateDialog(customer);
                },
              )
            else
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green.shade300),
                title: const Text('Activate Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _activateCustomer(customer);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Customer'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(customer);
              },
            ),
          ],
        ),
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
  
  void _showDeactivateDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Customer'),
        content: Text('Are you sure you want to deactivate ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final updatedCustomer = await ref.read(customersProvider.notifier)
                    .updateCustomer(customer.id, {'active': false});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer deactivated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  _refreshData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _activateCustomer(Customer customer) async {
    try {
      final updatedCustomer = await ref.read(customersProvider.notifier)
          .updateCustomer(customer.id, {'active': true});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  _refreshData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
