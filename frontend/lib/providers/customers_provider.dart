import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/customer.dart';

final customersProvider = StateNotifierProvider<CustomersNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomersNotifier(ref);
});

class CustomersNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final Ref ref;
  final Dio _dio = Dio();

  CustomersNotifier(this.ref) : super(const AsyncValue.loading()) {
    getCustomers(); // Load customers when provider is initialized
  }

  Future<void> getCustomers({
    String? search,
    String? type,
    String? paymentType,
    bool? active,
    int page = 1,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        if (search != null) 'search': search,
        if (type != null) 'type': type,
        if (paymentType != null) 'paymentType': paymentType,
        if (active != null) 'active': active.toString(),
        'page': page.toString(),
        'limit': AppConfig.defaultPaginationLimit.toString(),
      };

      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}${AppConfig.customersEndpoint}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<Customer> customers = (response.data['data']['customers'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
        
        state = AsyncValue.data(customers);
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Customer?> getCustomerById(int id) async {
    try {
      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}${AppConfig.customersEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(response.data['data']['customer']);
      }
      return null;
    } catch (error) {
      print('Error fetching customer by ID: $error');
      return null;
    }
  }

  Future<void> createCustomer(Customer customer) async {
    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}${AppConfig.customersEndpoint}',
        data: customer.toJson(),
      );

      if (response.statusCode == 201) {
        getCustomers(); // Refresh the list
      } else {
        throw Exception('Failed to create customer');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final response = await _dio.put(
        '${AppConfig.apiBaseUrl}${AppConfig.customersEndpoint}/${customer.id}',
        data: customer.toJson(),
      );

      if (response.statusCode == 200) {
        getCustomers(); // Refresh the list
      } else {
        throw Exception('Failed to update customer');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleCustomerStatus(int id, bool active) async {
    try {
      final response = await _dio.patch(
        '${AppConfig.apiBaseUrl}${AppConfig.customersEndpoint}/$id',
        data: {'active': active},
      );

      if (response.statusCode == 200) {
        getCustomers(); // Refresh the list
      } else {
        throw Exception('Failed to update customer status');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
