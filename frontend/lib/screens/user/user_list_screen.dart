import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import 'user_detail_screen.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  String _searchQuery = '';
  UserFilterType _currentFilter = UserFilterType.all;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(userProvider);
    final users = usersState.filteredUsers;
    final currentUser = ref.watch(authProvider).user;
    
    // Filter users based on search query
    final filteredUsers = users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesActive = _showInactive || user.isActive;
      return matchesSearch && matchesActive;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(userProvider.notifier).fetchUsers(),
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
                    hintText: 'Search users...',
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Users',
                        selected: _currentFilter == UserFilterType.all,
                        onSelected: (_) {
                          setState(() {
                            _currentFilter = UserFilterType.all;
                          });
                          ref.read(userProvider.notifier).setFilter(_currentFilter);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Admins',
                        selected: _currentFilter == UserFilterType.admin,
                        onSelected: (_) {
                          setState(() {
                            _currentFilter = UserFilterType.admin;
                          });
                          ref.read(userProvider.notifier).setFilter(_currentFilter);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Managers',
                        selected: _currentFilter == UserFilterType.manager,
                        onSelected: (_) {
                          setState(() {
                            _currentFilter = UserFilterType.manager;
                          });
                          ref.read(userProvider.notifier).setFilter(_currentFilter);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Fillers',
                        selected: _currentFilter == UserFilterType.filler,
                        onSelected: (_) {
                          setState(() {
                            _currentFilter = UserFilterType.filler;
                          });
                          ref.read(userProvider.notifier).setFilter(_currentFilter);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Sellers',
                        selected: _currentFilter == UserFilterType.seller,
                        onSelected: (_) {
                          setState(() {
                            _currentFilter = UserFilterType.seller;
                          });
                          ref.read(userProvider.notifier).setFilter(_currentFilter);
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
                        },
                        checkmarkColor: Colors.white,
                        selectedColor: kPrimaryColor,
                        labelStyle: TextStyle(
                          color: _showInactive ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Total: ${filteredUsers.length} users',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (usersState.isLoading)
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

          // User list
          Expanded(
            child: usersState.isLoading && users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : usersState.error != null
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
                              'Error loading users',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              usersState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(userProvider.notifier).fetchUsers(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users match your search'
                                  : 'No users found',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(userProvider.notifier).fetchUsers(),
                            child: ListView.builder(
                              itemCount: filteredUsers.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return _buildUserCard(context, user, currentUser);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: currentUser?.isAdmin == true
          ? FloatingActionButton(
              onPressed: () => _navigateToUserDetail(context, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUserCard(BuildContext context, User user, User? currentUser) {
    Color roleColor;
    IconData roleIcon;

    switch (user.role) {
      case 'Admin':
        roleColor = Colors.red;
        roleIcon = Icons.security;
        break;
      case 'Manager':
        roleColor = Colors.blue;
        roleIcon = Icons.manage_accounts;
        break;
      case 'Filler':
        roleColor = Colors.green;
        roleIcon = Icons.water_drop;
        break;
      case 'Seller':
        roleColor = Colors.orange;
        roleIcon = Icons.shopping_cart;
        break;
      default:
        roleColor = Colors.grey;
        roleIcon = Icons.person;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _navigateToUserDetail(context, user),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // User avatar & status
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.2),
                    radius: 28,
                    child: Icon(
                      roleIcon,
                      color: roleColor,
                      size: 24,
                    ),
                  ),
                  if (!user.isActive)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (currentUser?.isAdmin == true || user.id == currentUser?.id)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      checkmarkColor: Colors.white,
      selectedColor: kPrimaryColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }

  void _navigateToUserDetail(BuildContext context, User? user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(user: user),
      ),
    ).then((_) {
      // Refresh the list when returning
      ref.read(userProvider.notifier).fetchUsers();
    });
  }
}
