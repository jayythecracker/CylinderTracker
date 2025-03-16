import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for sales list
final salesProvider = StateNotifierProvider<SalesNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return SalesNotifier(ApiService());
});

// Provider for sale details
final saleDetailsProvider = StateNotifierProvider.family<SaleDetailsNotifier, AsyncValue<Sale?>, int>((ref, id) {
  return SaleDetailsNotifier(ApiService(), id);
});

// Provider for sales stats
final salesStatsProvider = StateNotifierProvider<SalesStatsNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return SalesStatsNotifier(ApiService());
});

// Notifier for sales list
class SalesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  SalesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchSales();
  }
  
  // Fetch all sales with pagination
  Future<void> fetchSales({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/sales',
        (data) => {
          'sales': (data['sales'] as List).map((item) => Sale.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch sales',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new sale
  Future<Sale?> createSale(Map<String, dynamic> saleData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/sales',
        saleData,
        (data) => {'sale': Sale.fromJson(data['sale'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh sales list
        fetchSales();
        return response.data!['sale'];
      } else {
        throw Exception(response.message ?? 'Failed to create sale');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update delivery status
  Future<Sale?> updateDeliveryStatus(int id, Map<String, dynamic> deliveryData) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/sales/$id/delivery',
        deliveryData,
        (data) => {'sale': Sale.fromJson(data['sale'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh sales list
        fetchSales();
        return response.data!['sale'];
      } else {
        throw Exception(response.message ?? 'Failed to update delivery status');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update payment status
  Future<Sale?> updatePaymentStatus(int id, Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/sales/$id/payment',
        paymentData,
        (data) => {'sale': Sale.fromJson(data['sale'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh sales list
        fetchSales();
        return response.data!['sale'];
      } else {
        throw Exception(response.message ?? 'Failed to update payment status');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for sale details
class SaleDetailsNotifier extends StateNotifier<AsyncValue<Sale?>> {
  final ApiService _apiService;
  final int saleId;
  
  SaleDetailsNotifier(this._apiService, this.saleId) : super(const AsyncValue.loading()) {
    if (saleId > 0) {
      fetchSaleDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch sale details
  Future<void> fetchSaleDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/sales/$saleId',
        (data) => {'sale': Sale.fromJson(data['sale'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['sale']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch sale details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for sales stats
class SalesStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiService _apiService;
  
  SalesStatsNotifier(this._apiService) : super(const AsyncValue.data(null));
  
  // Fetch sales stats
  Future<void> fetchStats({String period = 'daily', String? startDate, String? endDate}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/sales/stats/overview',
        (data) => data,
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch sales statistics',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
