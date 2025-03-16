import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

// State class for customer list
class CustomersState {
  final bool isLoading;
  final List<Customer> customers;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const CustomersState({
    this.isLoading = false,
    this.customers = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  // Copy with method for immutability
  CustomersState copyWith({
    bool? isLoading,
    List<Customer>? customers,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return CustomersState(
      isLoading: isLoading ?? this.isLoading,
      customers: customers ?? this.customers,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Customer notifier to handle customer list state
class CustomerNotifier extends StateNotifier<CustomersState> {
  final ApiService _apiService;

  CustomerNotifier(this._apiService) : super(const CustomersState());

  // Get customers with pagination and filters
  Future<void> getCustomers({
    int page = 1,
    int limit = 20,
    String? type,
    String? paymentType,
    String? search,
    String? sortBy,
    String? order,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'customers',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (type != null) 'type': type,
          if (paymentType != null) 'paymentType': paymentType,
          if (search != null && search.isNotEmpty) 'search': search,
          if (sortBy != null) 'sortBy': sortBy,
          if (order != null) 'order': order,
        },
      );

      final List<Customer> customers = (response['customers'] as List)
          .map((json) => Customer.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        customers: customers,
        totalCount: response['totalCount'] ?? 0,
        currentPage: response['currentPage'] ?? 1,
        totalPages: response['totalPages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load customers: ${e.toString()}',
      );
    }
  }

  // Get customer by ID
  Future<Map<String, dynamic>> getCustomerById(int id) async {
    try {
      final response = await _apiService.get('customers/$id');
      return {
        'customer': Customer.fromJson(response['customer']),
        'recentSales': response['recentSales'],
      };
    } catch (e) {
      throw Exception('Failed to load customer: ${e.toString()}');
    }
  }

  // Create customer
  Future<Customer> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await _apiService.post('customers', data: customerData);
      final customer = Customer.fromJson(response['customer']);
      
      // Update state with new customer
      state = state.copyWith(
        customers: [...state.customers, customer],
        totalCount: state.totalCount + 1,
      );
      
      return customer;
    } catch (e) {
      throw Exception('Failed to create customer: ${e.toString()}');
    }
  }

  // Update customer
  Future<Customer> updateCustomer(int id, Map<String, dynamic> customerData) async {
    try {
      final response = await _apiService.put('customers/$id', data: customerData);
      final updatedCustomer = Customer.fromJson(response['customer']);
      
      // Update state with updated customer
      final index = state.customers.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final updatedCustomers = [...state.customers];
        updatedCustomers[index] = updatedCustomer;
        state = state.copyWith(customers: updatedCustomers);
      }
      
      return updatedCustomer;
    } catch (e) {
      throw Exception('Failed to update customer: ${e.toString()}');
    }
  }

  // Update customer balance
  Future<Customer> updateCustomerBalance(
    int id,
    double amount,
    String operation,
    {String? notes}
  ) async {
    try {
      final response = await _apiService.patch(
        'customers/$id/balance',
        data: {
          'amount': amount,
          'operation': operation,
          if (notes != null) 'notes': notes,
        },
      );
      
      final customer = Customer.fromJson(response['customer']);
      
      // Update state with updated customer balance
      final index = state.customers.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final updatedCustomers = [...state.customers];
        updatedCustomers[index] = customer;
        state = state.copyWith(customers: updatedCustomers);
      }
      
      return customer;
    } catch (e) {
      throw Exception('Failed to update customer balance: ${e.toString()}');
    }
  }

  // Delete customer
  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.delete('customers/$id');
      
      // Update state by removing deleted customer
      final updatedCustomers = state.customers.where((c) => c.id != id).toList();
      state = state.copyWith(
        customers: updatedCustomers,
        totalCount: state.totalCount - 1,
      );
    } catch (e) {
      throw Exception('Failed to delete customer: ${e.toString()}');
    }
  }
}

// Customer providers
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomersState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CustomerNotifier(apiService);
});

// Provider for current customer (for details page)
final currentCustomerProvider = StateProvider<Customer?>((ref) => null);
