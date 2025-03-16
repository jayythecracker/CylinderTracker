import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/factory.dart';
import 'package:cylinder_management/providers/factory_provider.dart';
import 'package:cylinder_management/providers/auth_provider.dart';
import 'package:cylinder_management/widgets/loading_indicator.dart';
import 'package:cylinder_management/widgets/error_display.dart';

class FactoriesScreen extends ConsumerStatefulWidget {
  const FactoriesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FactoriesScreen> createState() => _FactoriesScreenState();
}

class _FactoriesScreenState extends ConsumerState<FactoriesScreen> {
  String _searchQuery = '';
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    // Initial fetch
    Future.microtask(() {
      ref.read(factoriesProvider.notifier).fetchFactories();
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    
    if (_searchQuery.isNotEmpty) {
      filters['search'] = _searchQuery;
    }
    
    if (_showOnlyActive) {
      filters['active'] = true;
    }
    
    ref.read(factoriesProvider.notifier).fetchFactories(filters: filters);
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _showOnlyActive = true;
    });
    
    ref.read(factoriesProvider.notifier).fetchFactories();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final factories = ref.watch(factoriesProvider);
    
    final bool canEdit = user != null && (user.isAdmin || user.isManager);
    
    return Scaffold(
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search factories...',
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
                    onSubmitted: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
              ],
            ),
          ),
          
          // Factories list
          Expanded(
            child: factories.when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 72,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No factories found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first factory or adjust filters',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(factoriesProvider.notifier).fetchFactories();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final factory = data[index];
                      return _buildFactoryCard(factory, canEdit);
                    },
                  ),
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => ErrorDisplay(
                message: error.toString(),
                onRetry: () {
                  ref.read(factoriesProvider.notifier).fetchFactories();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () {
                _showFactoryFormDialog(null);
              },
              backgroundColor: AppConfig.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFactoryCard(Factory factory, bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showFactoryDetailsDialog(factory);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Factory name and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.business_outlined,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factory.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          factory.location,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  if (!factory.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Factory details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Contact Person',
                      factory.contactPerson ?? 'Not specified',
                      Icons.person_outline,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Phone',
                      factory.contactPhone ?? 'Not specified',
                      Icons.phone_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Cylinders',
                      factory.cylinderCount != null
                          ? factory.cylinderCount.toString()
                          : 'Unknown',
                      Icons.propane_tank_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Email',
                      factory.email ?? 'Not specified',
                      Icons.email_outlined,
                    ),
                  ),
                ],
              ),
              
              // Actions
              if (canEdit) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        _showFactoryFormDialog(factory);
                      },
                    ),
                    const SizedBox(width: 8),
                    if (factory.cylinderCount == null || factory.cylinderCount == 0)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(factory);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Factories'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show only active factories
                SwitchListTile(
                  title: const Text('Show only active factories'),
                  value: _showOnlyActive,
                  onChanged: (value) {
                    setDialogState(() {
                      _showOnlyActive = value;
                    });
                  },
                ),
              ],
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
                  _applyFilters();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFactoryDetailsDialog(Factory factory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(factory.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Location'),
                subtitle: Text(factory.location),
                leading: const Icon(Icons.location_on_outlined),
              ),
              if (factory.contactPerson != null)
                ListTile(
                  title: const Text('Contact Person'),
                  subtitle: Text(factory.contactPerson!),
                  leading: const Icon(Icons.person_outlined),
                ),
              if (factory.contactPhone != null)
                ListTile(
                  title: const Text('Contact Phone'),
                  subtitle: Text(factory.contactPhone!),
                  leading: const Icon(Icons.phone_outlined),
                ),
              if (factory.email != null)
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(factory.email!),
                  leading: const Icon(Icons.email_outlined),
                ),
              ListTile(
                title: const Text('Status'),
                subtitle: Text(factory.active ? 'Active' : 'Inactive'),
                leading: const Icon(Icons.toggle_on_outlined),
              ),
              if (factory.description != null)
                ListTile(
                  title: const Text('Description'),
                  subtitle: Text(factory.description!),
                  leading: const Icon(Icons.description_outlined),
                ),
              ListTile(
                title: const Text('Cylinders Count'),
                subtitle: Text(
                  factory.cylinderCount != null
                      ? factory.cylinderCount.toString()
                      : 'Unknown',
                ),
                leading: const Icon(Icons.propane_tank_outlined),
              ),
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

  void _showFactoryFormDialog(Factory? factory) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: factory?.name ?? '');
    final locationController = TextEditingController(text: factory?.location ?? '');
    final contactPersonController = TextEditingController(text: factory?.contactPerson ?? '');
    final contactPhoneController = TextEditingController(text: factory?.contactPhone ?? '');
    final emailController = TextEditingController(text: factory?.email ?? '');
    final descriptionController = TextEditingController(text: factory?.description ?? '');
    
    bool active = factory?.active ?? true;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(factory == null ? 'Add New Factory' : 'Edit Factory'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Factory Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a factory name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (value) {
                        setDialogState(() {
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
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final factoryData = {
                          'name': nameController.text,
                          'location': locationController.text,
                          'contactPerson': contactPersonController.text.isEmpty
                              ? null
                              : contactPersonController.text,
                          'contactPhone': contactPhoneController.text.isEmpty
                              ? null
                              : contactPhoneController.text,
                          'email': emailController.text.isEmpty
                              ? null
                              : emailController.text,
                          'active': active,
                          'description': descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                        };

                        if (factory == null) {
                          // Create new factory
                          await ref.read(factoriesProvider.notifier).createFactory(factoryData);
                        } else {
                          // Update existing factory
                          await ref.read(factoriesProvider.notifier).updateFactory(factory.id, factoryData);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        setDialogState(() {
                          errorMessage = e.toString();
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: Text(factory == null ? 'Create' : 'Update'),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controllers
      nameController.dispose();
      locationController.dispose();
      contactPersonController.dispose();
      contactPhoneController.dispose();
      emailController.dispose();
      descriptionController.dispose();
    });
  }

  void _showDeleteConfirmation(Factory factory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Factory'),
        content: Text('Are you sure you want to delete ${factory.name}?'),
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
                await ref.read(factoriesProvider.notifier).deleteFactory(factory.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Factory "${factory.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
