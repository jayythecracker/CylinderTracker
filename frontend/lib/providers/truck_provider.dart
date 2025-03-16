import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/truck.dart';
import 'package:cylinder_management/models/sale.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for trucks list
final trucksProvider = StateNotifierProvider<TrucksNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return TrucksNotifier(ApiService());
});

// Provider for truck details
final truckDetailsProvider = StateNotifierProvider.family<TruckDetailsNotifier, AsyncValue<Truck?>, int>((ref, id) {
  return TruckDetailsNotifier(ApiService(), id);
});

// Provider for truck deliveries
final truckDeliveriesProvider = StateNotifierProvider.family<TruckDeliveriesNotifier, AsyncValue<Map<String, dynamic>>, int>((ref, id) {
  return TruckDeliveriesNotifier(ApiService(), id);
});

// Notifier for trucks list
class TrucksNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  TrucksNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchTrucks();
  }
  
  // Fetch all trucks with pagination
  Future<void> fetchTrucks({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/trucks',
        (data) => {
          'trucks': (data['trucks'] as List).map((item) => Truck.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch trucks',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new truck
  Future<Truck?> createTruck(Map<String, dynamic> truckData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/trucks',
        truckData,
        (data) => {'truck': Truck.fromJson(data['truck'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh trucks list
        fetchTrucks();
        return response.data!['truck'];
      } else {
        throw Exception(response.message ?? 'Failed to create truck');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update existing truck
  Future<Truck?> updateTruck(int id, Map<String, dynamic> truckData) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/trucks/$id',
        truckData,
        (data) => {'truck': Truck.fromJson(data['truck'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh trucks list
        fetchTrucks();
        return response.data!['truck'];
      } else {
        throw Exception(response.message ?? 'Failed to update truck');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update truck status
  Future<Truck?> updateTruckStatus(int id, String status, String? notes) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/trucks/$id/status',
        {
          'status': status,
          if (notes != null) 'notes': notes,
        },
        (data) => {'truck': Truck.fromJson(data['truck'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh trucks list
        fetchTrucks();
        return response.data!['truck'];
      } else {
        throw Exception(response.message ?? 'Failed to update truck status');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete truck
  Future<bool> deleteTruck(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/trucks/$id',
        (data) => data,
      );
      
      if (response.success) {
        // Refresh trucks list
        fetchTrucks();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete truck');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for truck details
class TruckDetailsNotifier extends StateNotifier<AsyncValue<Truck?>> {
  final ApiService _apiService;
  final int truckId;
  
  TruckDetailsNotifier(this._apiService, this.truckId) : super(const AsyncValue.loading()) {
    if (truckId > 0) {
      fetchTruckDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch truck details
  Future<void> fetchTruckDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/trucks/$truckId',
        (data) => {'truck': Truck.fromJson(data['truck'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['truck']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch truck details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for truck deliveries
class TruckDeliveriesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  final int truckId;
  
  TruckDeliveriesNotifier(this._apiService, this.truckId) : super(const AsyncValue.loading()) {
    if (truckId > 0) {
      fetchTruckDeliveries();
    } else {
      state = AsyncValue.data({
        'truck': null,
        'deliveries': <Sale>[],
        'pagination': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 0},
      });
    }
  }
  
  // Fetch deliveries for a specific truck
  Future<void> fetchTruckDeliveries({int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/trucks/$truckId/deliveries',
        (data) => {
          'truck': Truck.fromJson(data['truck']),
          'deliveries': (data['deliveries'] as List).map((item) => Sale.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch truck deliveries',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
