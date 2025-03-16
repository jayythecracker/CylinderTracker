import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    
    if (user == null) {
      return const Drawer(
        child: Center(
          child: Text('User not authenticated'),
        ),
      );
    }
    
    return Drawer(
      child: Column(
        children: [
          // Header with user info
          UserAccountsDrawerHeader(
            accountName: Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
            ),
            otherAccountsPictures: [
              Tooltip(
                message: user.roleDisplayName,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: AppConfig.primaryColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  index: 0,
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                ),
                _buildRoleDivider('MANAGEMENT'),
                if (_canAccessSection(user, 'factory'))
                  _buildDrawerItem(
                    context,
                    index: 1,
                    title: 'Factories',
                    icon: Icons.business,
                  ),
                if (_canAccessSection(user, 'cylinder'))
                  _buildDrawerItem(
                    context,
                    index: 2,
                    title: 'Cylinders',
                    icon: Icons.propane_tank_outlined,
                  ),
                if (_canAccessSection(user, 'customer'))
                  _buildDrawerItem(
                    context,
                    index: 3,
                    title: 'Customers',
                    icon: Icons.people,
                  ),
                _buildRoleDivider('OPERATIONS'),
                if (_canAccessSection(user, 'filling'))
                  _buildDrawerItem(
                    context,
                    index: 4,
                    title: 'Filling',
                    icon: Icons.local_gas_station,
                  ),
                if (_canAccessSection(user, 'inspection'))
                  _buildDrawerItem(
                    context,
                    index: 5,
                    title: 'Inspection',
                    icon: Icons.check_circle_outline,
                  ),
                if (_canAccessSection(user, 'sales'))
                  _buildDrawerItem(
                    context,
                    index: 6,
                    title: 'Sales',
                    icon: Icons.point_of_sale,
                  ),
                if (_canAccessSection(user, 'reports'))
                  _buildRoleDivider('ANALYSIS'),
                if (_canAccessSection(user, 'reports'))
                  _buildDrawerItem(
                    context,
                    index: 7,
                    title: 'Reports',
                    icon: Icons.bar_chart,
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutConfirmation(context, ref);
                  },
                ),
              ],
            ),
          ),
          
          // App version at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version ${AppConfig.appVersion}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppConfig.primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppConfig.primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      tileColor: isSelected ? AppConfig.primaryColor.withOpacity(0.1) : null,
      onTap: () => onItemSelected(index),
    );
  }
  
  Widget _buildRoleDivider(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'filler':
        return Icons.engineering;
      case 'seller':
        return Icons.store;
      default:
        return Icons.person;
    }
  }
  
  bool _canAccessSection(user, String section) {
    if (user.isAdmin || user.isManager) {
      return true;
    }
    
    switch (section) {
      case 'factory':
        return user.isAdmin || user.isManager;
      case 'cylinder':
        return true; // All roles can view cylinders
      case 'customer':
        return user.isAdmin || user.isManager || user.isSeller;
      case 'filling':
        return user.isAdmin || user.isManager || user.isFiller;
      case 'inspection':
        return user.isAdmin || user.isManager || user.isFiller;
      case 'sales':
        return user.isAdmin || user.isManager || user.isSeller;
      case 'reports':
        return user.isAdmin || user.isManager;
      default:
        return false;
    }
  }
  
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
