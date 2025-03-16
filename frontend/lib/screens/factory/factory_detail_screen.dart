import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/factory.dart';
import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/factory_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/cylinder_card.dart';
import '../cylinder/cylinder_detail_screen.dart';

class FactoryDetailScreen extends ConsumerStatefulWidget {
  final Factory? factory;

  const FactoryDetailScreen({Key? key, this.factory}) : super(key: key);

  @override
  ConsumerState<FactoryDetailScreen> createState() => _FactoryDetailScreenState();
}

class _FactoryDetailScreenState extends ConsumerState<FactoryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isFetchingCylinders = false;
  bool _isEditMode = false;
  bool _showCylinders = false;
  List<Cylinder> _cylinders = [];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.factory != null;
    if (_isEditMode) {
      _nameController.text = widget.factory!.name;
      _locationController.text = widget.factory!.location;
      _contactPersonController.text = widget.factory!.contactPerson ?? '';
      _phoneNumberController.text = widget.factory!.phoneNumber ?? '';
      _emailController.text = widget.factory!.email ?? '';
      _isActive = widget.factory!.isActive;
      
      // Load cylinders for this factory
      _fetchCylinders();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactPersonController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchCylinders() async {
    if (!_isEditMode) return;
    
    setState(() {
      _isFetchingCylinders = true;
    });

    try {
      final cylinders = await ref.read(factoryProvider.notifier)
          .getFactoryCylinders(widget.factory!.id);
      
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

  Future<void> _saveFactory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final factoryData = {
        'name': _nameController.text,
        'location': _locationController.text,
        'contactPerson': _contactPersonController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'isActive': _isActive,
      };

      bool success;
      if (_isEditMode) {
        success = await ref.read(factoryProvider.notifier)
            .updateFactory(widget.factory!.id, factoryData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factory updated successfully')),
          );
        }
      } else {
        success = await ref.read(factoryProvider.notifier).createFactory(factoryData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factory created successfully')),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final bool canModifyFactory = currentUser?.isAdmin == true || currentUser?.isManager == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Factory Details' : 'Create Factory'),
        actions: [
          if (_isEditMode && canModifyFactory)
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
              tooltip: _isActive ? 'Deactivate Factory' : 'Activate Factory',
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
                  // Factory info card
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
                                    color: kPrimaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.factory,
                                    color: kPrimaryColor,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.factory!.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.factory!.location,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
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
                            // Status indicator
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isActive ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isActive ? Icons.check_circle : Icons.cancel,
                                    color: _isActive ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: _isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Factory Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) => Validators.validateRequired(value, 'Factory name'),
                          enabled: canModifyFactory,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) => Validators.validateRequired(value, 'Location'),
                          enabled: canModifyFactory,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person',
                            prefixIcon: Icon(Icons.person),
                          ),
                          enabled: canModifyFactory,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          enabled: canModifyFactory,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => 
                              value!.isEmpty ? null : Validators.validateEmail(value),
                          enabled: canModifyFactory,
                        ),
                        const SizedBox(height: 32),
                        
                        if (canModifyFactory)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: !_isLoading ? _saveFactory : null,
                              child: Text(
                                _isEditMode ? 'Update Factory' : 'Create Factory',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Cylinders section
                  if (_isEditMode) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Factory Cylinders',
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
                                    child: Column(
                                      children: [
                                        const Text(
                                          'No cylinders found for this factory',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: canModifyFactory
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => CylinderDetailScreen(
                                                        factory: widget.factory,
                                                      ),
                                                    ),
                                                  ).then((_) => _fetchCylinders());
                                                }
                                              : null,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Add Cylinder'),
                                        ),
                                      ],
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
                                    const SizedBox(height: 16),
                                    if (canModifyFactory)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CylinderDetailScreen(
                                                factory: widget.factory,
                                              ),
                                            ),
                                          ).then((_) => _fetchCylinders());
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Cylinder'),
                                      ),
                                  ],
                                ),
                  ],
                ],
              ),
            ),
    );
  }
}
