import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for customers list state
final customersProvider = AsyncNotifierProvider<CustomersNotifier, List<Customer>>(() {
  return CustomersNotifier();
});

// Provider for selected customer
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

// Provider for customer filter parameters
final customerFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'type': null,
    'paymentType': null,
    'search': null,
    'page': 1,
    'limit': AppConfig.defaultPageSize,
  };
});

// Provider for customers pagination info
final customerPaginationProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalCount': 0,
    'currentPage': 1,
    'totalPages': 1,
  };
});

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  late ApiService _apiService;
  
  @override
  Future<List<Customer>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all customers with optional filters
  Future<void> getCustomers({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();
    
    try {
      final currentFilters = ref.read(customerFilterProvider);
      final queryParams = filters ?? currentFilters;
      
      // Update filter provider if new filters are provided
      if (filters != null) {
        ref.read(customerFilterProvider.notifier).state = {
          ...currentFilters,
          ...filters,
        };
      }
      
      final response = await _apiService.get(
        AppConfig.customersEndpoint,
        queryParams: queryParams,
      );
      
      final List<Customer> customers = (response['customers'] as List)
          .map((customerData) => Customer.fromJson(customerData))
          .toList();
      
      // Update pagination info
      ref.read(customerPaginationProvider.notifier).state = {
        'totalCount': response['totalCount'],
        'currentPage': response['currentPage'],
        'totalPages': response['totalPages'],
      };
      
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get customer by ID
  Future<Customer> getCustomerById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.customersEndpoint}/$id');
      return Customer.fromJson(response['customer']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create customer
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _apiService.post(
        AppConfig.customersEndpoint,
        data: customer.toCreateJson(),
      );
      
      final newCustomer = Customer.fromJson(response['customer']);
      
      // Update state with new customer
      state = AsyncValue.data([...state.value ?? [], newCustomer]);
      
      return newCustomer;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update customer
  Future<Customer> updateCustomer(int id, Customer updatedCustomer) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.customersEndpoint}/$id',
        data: {
          'name': updatedCustomer.name,
          'type': updatedCustomer.type,
          'address': updatedCustomer.address,
          'contactPerson': updatedCustomer.contactPerson,
          'contactNumber': updatedCustomer.contactNumber,
          'email': updatedCustomer.email,
          'paymentType': updatedCustomer.paymentType,
          'priceGroup': updatedCustomer.priceGroup,
          'creditLimit': updatedCustomer.creditLimit,
        },
      );
      
      final customer = Customer.fromJson(response['customer']);
      
      // Update state with updated customer
      state = AsyncValue.data(
        state.value?.map((c) => c.id == id ? customer : c).toList() ?? [],
      );
      
      return customer;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update customer credit
  Future<Customer> updateCustomerCredit(int id, double amount, String operation) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.customersEndpoint}/$id/credit',
        data: {
          'amount': amount,
          'operation': operation,
        },
      );
      
      final customer = Customer.fromJson(response['customer']);
      
      // Update state with updated customer
      state = AsyncValue.data(
        state.value?.map((c) => c.id == id ? customer : c).toList() ?? [],
      );
      
      return customer;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete customer
  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.delete('${AppConfig.customersEndpoint}/$id');
      
      // Update state by removing deleted customer
      state = AsyncValue.data(
        state.value?.where((customer) => customer.id != id).toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }
}
