import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/factory_provider.dart';
import '../../models/factory.dart';
import '../../utils/constants.dart';
import '../../widgets/app_drawer.dart';
import 'factory_detail_screen.dart';

class FactoryListScreen extends ConsumerStatefulWidget {
  const FactoryListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends ConsumerState<FactoryListScreen> {
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(factoryProvider.notifier).fetchFactories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final factoriesState = ref.watch(factoryProvider);
    final factories = factoriesState.filteredFactories;
    final currentUser = ref.watch(authProvider).user;
    
    // Filter factories based on search query
    final filteredFactories = factories.where((factory) {
      final matchesSearch = factory.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           (factory.location.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesActive = _showInactive || factory.isActive;
      return matchesSearch && matchesActive;
    }).toList();

    final bool canCreateFactory = currentUser?.isAdmin == true || currentUser?.isManager == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(factoryProvider.notifier).fetchFactories(),
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
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Show Inactive'),
                      selected: _showInactive,
                      onSelected: (value) {
                        setState(() {
                          _showInactive = value;
                        });
                        ref.read(factoryProvider.notifier).toggleActiveFilter(!value);
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: kPrimaryColor,
                      labelStyle: TextStyle(
                        color: _showInactive ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${filteredFactories.length} factories',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (factoriesState.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Factory list
          Expanded(
            child: factoriesState.isLoading && factories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : factoriesState.error != null
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
                              'Error loading factories',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              factoriesState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(factoryProvider.notifier).fetchFactories(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredFactories.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No factories match your search'
                                  : 'No factories found',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(factoryProvider.notifier).fetchFactories(),
                            child: ListView.builder(
                              itemCount: filteredFactories.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemBuilder: (context, index) {
                                final factory = filteredFactories[index];
                                return _buildFactoryCard(context, factory);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: canCreateFactory
          ? FloatingActionButton(
              onPressed: () => _navigateToFactoryDetail(context, null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFactoryCard(BuildContext context, Factory factory) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _navigateToFactoryDetail(context, factory),
        borderRadius: BorderRadius.circular(8),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                factory.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!factory.isActive)
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
                        ),
                        const SizedBox(height: 4),
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
                                factory.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildContactInfo(
                        'Contact Person',
                        factory.contactPerson ?? 'N/A',
                        Icons.person,
                      ),
                    ),
                    Expanded(
                      child: _buildContactInfo(
                        'Phone',
                        factory.phoneNumber ?? 'N/A',
                        Icons.phone,
                      ),
                    ),
                  ],
                ),
              ),
              if (factory.email != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: _buildContactInfo(
                    'Email',
                    factory.email!,
                    Icons.email,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToFactoryDetail(BuildContext context, Factory? factory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FactoryDetailScreen(factory: factory),
      ),
    ).then((_) {
      // Refresh the list when returning
      ref.read(factoryProvider.notifier).fetchFactories();
    });
  }
}
