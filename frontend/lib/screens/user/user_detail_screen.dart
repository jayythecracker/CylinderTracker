import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final User? user;

  const UserDetailScreen({Key? key, this.user}) : super(key: key);

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedRole = 'Seller';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEditMode = false;
  bool _isResetPassword = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.user != null;
    if (_isEditMode) {
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email;
      _contactController.text = widget.user!.contact ?? '';
      _addressController.text = widget.user!.address ?? '';
      _selectedRole = widget.user!.role;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        final userData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'role': _selectedRole,
          'isActive': _isActive,
        };

        final success = await ref.read(userProvider.notifier)
            .updateUser(widget.user!.id, userData);

        if (_isResetPassword && _passwordController.text.isNotEmpty) {
          await ref.read(userProvider.notifier)
              .resetUserPassword(widget.user!.id, _passwordController.text);
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        final userData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'role': _selectedRole,
        };

        final success = await ref.read(userProvider.notifier).createUser(userData);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully')),
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
    final bool canModifyUser = currentUser?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit User' : 'Create User'),
        actions: [
          if (_isEditMode && canModifyUser && widget.user!.id != currentUser?.id)
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
              tooltip: _isActive ? 'Deactivate User' : 'Activate User',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info container
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
                                  CircleAvatar(
                                    backgroundColor: _getRoleColor(_selectedRole).withOpacity(0.2),
                                    radius: 32,
                                    child: Icon(
                                      _getRoleIcon(_selectedRole),
                                      color: _getRoleColor(_selectedRole),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.user!.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _selectedRole,
                                          style: TextStyle(
                                            color: _getRoleColor(_selectedRole),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          widget.user!.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
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
                                  ),
                                  if (widget.user?.id == currentUser?.id)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: Colors.blue[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Current User',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.bold,
                                              ),
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

                    // Form fields
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => Validators.validateRequired(value, 'Name'),
                      enabled: canModifyUser || !_isEditMode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      enabled: canModifyUser || !_isEditMode,
                    ),
                    const SizedBox(height: 16),
                    if (!_isEditMode || _isResetPassword)
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: _isEditMode ? 'New Password' : 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) => _isEditMode
                            ? (value!.isEmpty ? null : Validators.validatePassword(value))
                            : Validators.validatePassword(value),
                      ),
                    if (_isEditMode && !_isResetPassword)
                      TextButton.icon(
                        onPressed: canModifyUser
                            ? () {
                                setState(() {
                                  _isResetPassword = true;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Password'),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                      enabled: canModifyUser || !_isEditMode,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      enabled: canModifyUser || !_isEditMode,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildRoleChip('Admin', canModifyUser),
                        _buildRoleChip('Manager', canModifyUser),
                        _buildRoleChip('Filler', canModifyUser),
                        _buildRoleChip('Seller', canModifyUser),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (canModifyUser || !_isEditMode) && !_isLoading
                            ? _saveUser
                            : null,
                        child: Text(
                          _isEditMode ? 'Update User' : 'Create User',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRoleChip(String role, bool enabled) {
    final bool isSelected = _selectedRole == role;
    final Color roleColor = _getRoleColor(role);

    return FilterChip(
      label: Text(role),
      selected: isSelected,
      onSelected: enabled
          ? (selected) {
              setState(() {
                _selectedRole = role;
              });
            }
          : null,
      backgroundColor: enabled ? Colors.white : Colors.grey[200],
      selectedColor: roleColor.withOpacity(0.2),
      checkmarkColor: roleColor,
      labelStyle: TextStyle(
        color: isSelected ? roleColor : enabled ? Colors.black : Colors.grey,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? roleColor : Colors.grey[300]!,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Manager':
        return Colors.blue;
      case 'Filler':
        return Colors.green;
      case 'Seller':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.security;
      case 'Manager':
        return Icons.manage_accounts;
      case 'Filler':
        return Icons.water_drop;
      case 'Seller':
        return Icons.shopping_cart;
      default:
        return Icons.person;
    }
  }
}
