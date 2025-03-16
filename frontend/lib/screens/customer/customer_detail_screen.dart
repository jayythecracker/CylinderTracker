import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/cylinder_card.dart';
import '../cylinder/cylinder_detail_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const CustomerDetailScreen({Key? key, this.customer}) : super(key: key);

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceGroupController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();
  
  CustomerType _type = CustomerType.Individual;
  PaymentType _paymentType = PaymentType.Cash;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isFetchingCylinders = false;
  bool _isEditMode = false;
  bool _showCylinders = false;
  List<Cylinder> _cylinders = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.customer != null;
    if (_isEditMode) {
      _nameController.text = widget.customer!.name;
      _contactController.text = widget.customer!.contact;
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address;
      _priceGroupController.text = widget.customer!.priceGroup ?? '';
      _creditLimitController.text = widget.customer!.creditLimit?.toString() ?? '';
      _notesController.text = widget.customer!.notes ?? '';
      
      _type = widget.customer!.type;
      _paymentType = widget.customer!.paymentType;
      _isActive = widget.customer!.isActive;
      
      // Load cylinders for this customer
      _fetchCylinders();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _priceGroupController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCylinders() async {
    if (!_isEditMode) return;
    
    setState(() {
      _isFetchingCylinders = true;
    });

    try {
      final cylinders = await ref.read(customerProvider.notifier)
          .getCustomerCylinders(widget.customer!.id);
      
      setState(() {
        _cylinders = cylinders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cylinders: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isFetchingCylinders = false;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerData = {
        'name': _nameController.text,
        'type': _type.toString().split('.').last,
        'address': _addressController.text,
        'contact': _contactController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'paymentType': _paymentType == PaymentType.Credit ? 'Credit' : 'Cash',
        'priceGroup': _priceGroupController.text.isEmpty ? null : _priceGroupController.text,
        'creditLimit': _creditLimitController.text.isEmpty ? null : double.parse(_creditLimitController.text),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (_isEditMode) {
        // Add isActive for updates
        customerData['isActive'] = _isActive;
        
        final success = await ref.read(customerProvider.notifier)
            .updateCustomer(widget.customer!.id, customerData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        final success = await ref.read(customerProvider.notifier).createCustomer(customerData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBalanceUpdateDialog() {
    if (!_isEditMode) return;
    
    final amountController = TextEditingController();
    String transactionType = 'credit'; // Default to credit

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update ${widget.customer!.name}\'s Balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Balance: ${widget.customer!.currentBalance < 0 ? "-" : ""}₹${widget.customer!.currentBalance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.customer!.currentBalance < 0 ? Colors.red : Colors.green,
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
                    widget.customer!.id,
                    amount,
                    transactionType,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer balance updated successfully')),
                    );
                    // Refresh customer details
                    final updatedCustomer = await ref.read(customerProvider.notifier)
                        .getCustomerById(widget.customer!.id);
                    if (updatedCustomer != null) {
                      // This is a workaround to refresh the customer data
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerDetailScreen(customer: updatedCustomer),
                        ),
                      );
                    }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    
    final bool canModifyCustomer = currentUser?.isAdmin == true || 
                                 currentUser?.isManager == true || 
                                 currentUser?.isSeller == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? widget.customer!.name : 'Create Customer'),
        actions: [
          if (_isEditMode && _paymentType == PaymentType.Credit)
            IconButton(
              icon: const Icon(Icons.account_balance_wallet),
              onPressed: canModifyCustomer ? _showBalanceUpdateDialog : null,
              tooltip: 'Update Balance',
            ),
          if (_isEditMode && canModifyCustomer)
            IconButton(
              icon: Icon(
                _isActive ? Icons.block : Icons.check_circle,
                color: _isActive ? Colors.red : Colors.green,
              ),
              onPressed: () {
                setState(() {
                  _isActive = !_isActive;
                });
              },
              tooltip: _isActive ? 'Deactivate Customer' : 'Activate Customer',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info card
                  if (_isEditMode)
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(_type).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getTypeIcon(_type),
                                    color: _getTypeColor(_type),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.customer!.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        kCustomerTypeNames[_type.toString().split('.').last] ?? 'Unknown',
                                        style: TextStyle(
                                          color: _getTypeColor(_type),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.phone,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.customer!.contact,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Payment and balance info
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _paymentType == PaymentType.Credit 
                                          ? Colors.blue[50] 
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _paymentType == PaymentType.Credit ? 'Credit Customer' : 'Cash Customer',
                                          style: TextStyle(
                                            color: _paymentType == PaymentType.Credit ? Colors.blue : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_paymentType == PaymentType.Credit && widget.customer!.creditLimit != null)
                                          Text(
                                            'Credit Limit: ₹${widget.customer!.creditLimit!.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.customer!.currentBalance < 0 
                                          ? Colors.red[50] 
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Current Balance',
                                          style: TextStyle(
                                            color: widget.customer!.currentBalance < 0 
                                                ? Colors.red 
                                                : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${widget.customer!.currentBalance < 0 ? "-" : ""}₹${widget.customer!.currentBalance.abs().toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: widget.customer!.currentBalance < 0 
                                                ? Colors.red[700] 
                                                : Colors.green[700],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _isActive ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: _isActive ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          _isActive ? Icons.check_circle : Icons.cancel,
                                          color: _isActive ? Colors.green : Colors.red,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Form for editing/creating
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name',
                            hintText: 'Enter customer name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) => Validators.validateRequired(value, 'Customer name'),
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 16),
                        
                        // Customer type
                        const Text('Customer Type'),
                        Wrap(
                          spacing: 8.0,
                          children: CustomerType.values.map((type) {
                            return ChoiceChip(
                              label: Text(kCustomerTypeNames[type.toString().split('.').last] ?? 'Unknown'),
                              selected: _type == type,
                              onSelected: canModifyCustomer 
                                  ? (selected) {
                                      if (selected) {
                                        setState(() {
                                          _type = type;
                                        });
                                      }
                                    }
                                  : null,
                              selectedColor: _getTypeColor(type).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: _type == type ? _getTypeColor(type) : Colors.black,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact
                        TextFormField(
                          controller: _contactController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number',
                            hintText: 'Enter phone number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Optional)',
                            hintText: 'Enter email address',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => 
                              value!.isEmpty ? null : Validators.validateEmail(value),
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            hintText: 'Enter full address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) => Validators.validateRequired(value, 'Address'),
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Payment Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Payment type
                        const Text('Payment Method'),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<PaymentType>(
                                title: const Text('Cash'),
                                value: PaymentType.Cash,
                                groupValue: _paymentType,
                                onChanged: canModifyCustomer
                                    ? (PaymentType? value) {
                                        setState(() {
                                          _paymentType = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<PaymentType>(
                                title: const Text('Credit'),
                                value: PaymentType.Credit,
                                groupValue: _paymentType,
                                onChanged: canModifyCustomer
                                    ? (PaymentType? value) {
                                        setState(() {
                                          _paymentType = value!;
                                        });
                                      }
                                    : null,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Price group
                        TextFormField(
                          controller: _priceGroupController,
                          decoration: const InputDecoration(
                            labelText: 'Price Group (Optional)',
                            hintText: 'E.g., Premium, Standard, etc.',
                            prefixIcon: Icon(Icons.price_change),
                          ),
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 16),
                        
                        // Credit limit (only for credit customers)
                        if (_paymentType == PaymentType.Credit)
                          TextFormField(
                            controller: _creditLimitController,
                            decoration: const InputDecoration(
                              labelText: 'Credit Limit',
                              hintText: 'Maximum allowed credit',
                              prefixIcon: Icon(Icons.credit_card),
                              prefixText: '₹',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => Validators.validateCreditLimit(value, _paymentType == PaymentType.Credit),
                            enabled: canModifyCustomer,
                          ),
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Enter any additional information',
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                          enabled: canModifyCustomer,
                        ),
                        const SizedBox(height: 32),
                        
                        if (canModifyCustomer)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: !_isLoading ? _saveCustomer : null,
                              child: Text(
                                _isEditMode ? 'Update Customer' : 'Create Customer',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Customer cylinders section
                  if (_isEditMode) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer Cylinders',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: Icon(
                            _showCylinders ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          ),
                          onPressed: () {
                            setState(() {
                              _showCylinders = !_showCylinders;
                              if (_showCylinders && _cylinders.isEmpty) {
                                _fetchCylinders();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_showCylinders)
                      _isFetchingCylinders
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _cylinders.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No cylinders assigned to this customer',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _cylinders.length,
                                      itemBuilder: (context, index) {
                                        final cylinder = _cylinders[index];
                                        return CylinderCard(
                                          cylinder: cylinder,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CylinderDetailScreen(
                                                  cylinder: cylinder,
                                                ),
                                              ),
                                            ).then((_) => _fetchCylinders());
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _getTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.Hospital:
        return Colors.red;
      case CustomerType.Individual:
        return Colors.blue;
      case CustomerType.Shop:
        return Colors.green;
      case CustomerType.Factory:
        return Colors.orange;
      case CustomerType.Workshop:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.Hospital:
        return Icons.local_hospital;
      case CustomerType.Individual:
        return Icons.person;
      case CustomerType.Shop:
        return Icons.storefront;
      case CustomerType.Factory:
        return Icons.factory;
      case CustomerType.Workshop:
        return Icons.handyman;
      default:
        return Icons.business;
    }
  }
}
