import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/customer.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for customers list
final customersProvider = StateNotifierProvider<CustomersNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return CustomersNotifier(ApiService());
});

// Provider for customer details
final customerDetailsProvider = StateNotifierProvider.family<CustomerDetailsNotifier, AsyncValue<Customer?>, int>((ref, id) {
  return CustomerDetailsNotifier(ApiService(), id);
});

// Provider for customer sales
final customerSalesProvider = StateNotifierProvider.family<CustomerSalesNotifier, AsyncValue<Map<String, dynamic>>, int>((ref, id) {
  return CustomerSalesNotifier(ApiService(), id);
});

// Notifier for customers list
class CustomersNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  CustomersNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchCustomers();
  }
  
  // Fetch all customers with pagination
  Future<void> fetchCustomers({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/customers',
        (data) => {
          'customers': (data['customers'] as List).map((item) => Customer.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch customers',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new customer
  Future<Customer?> createCustomer(Map<String, dynamic> customerData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/customers',
        customerData,
        (data) => {'customer': Customer.fromJson(data['customer'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh customers list
        fetchCustomers();
        return response.data!['customer'];
      } else {
        throw Exception(response.message ?? 'Failed to create customer');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update existing customer
  Future<Customer?> updateCustomer(int id, Map<String, dynamic> customerData) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/customers/$id',
        customerData,
        (data) => {'customer': Customer.fromJson(data['customer'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh customers list
        fetchCustomers();
        return response.data!['customer'];
      } else {
        throw Exception(response.message ?? 'Failed to update customer');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update customer balance
  Future<Customer?> updateCustomerBalance(int id, double amount, String operation, String? notes) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/customers/$id/balance',
        {
          'amount': amount,
          'operation': operation, // 'add' or 'subtract'
          if (notes != null) 'notes': notes,
        },
        (data) => {'customer': Customer.fromJson(data['customer'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh customers list
        fetchCustomers();
        return response.data!['customer'];
      } else {
        throw Exception(response.message ?? 'Failed to update customer balance');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete customer
  Future<bool> deleteCustomer(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/customers/$id',
        (data) => data,
      );
      
      if (response.success) {
        // Refresh customers list
        fetchCustomers();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete customer');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for customer details
class CustomerDetailsNotifier extends StateNotifier<AsyncValue<Customer?>> {
  final ApiService _apiService;
  final int customerId;
  
  CustomerDetailsNotifier(this._apiService, this.customerId) : super(const AsyncValue.loading()) {
    if (customerId > 0) {
      fetchCustomerDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch customer details
  Future<void> fetchCustomerDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/customers/$customerId',
        (data) => {'customer': Customer.fromJson(data['customer'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['customer']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch customer details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for customer sales
class CustomerSalesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  final int customerId;
  
  CustomerSalesNotifier(this._apiService, this.customerId) : super(const AsyncValue.loading()) {
    if (customerId > 0) {
      fetchCustomerSales();
    } else {
      state = AsyncValue.data({
        'customer': null,
        'sales': <Sale>[],
        'pagination': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 0},
      });
    }
  }
  
  // Fetch sales for a specific customer
  Future<void> fetchCustomerSales({int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/customers/$customerId/sales',
        (data) => {
          'customer': Customer.fromJson(data['customer']),
          'sales': (data['sales'] as List).map((item) => Sale.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch customer sales',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
