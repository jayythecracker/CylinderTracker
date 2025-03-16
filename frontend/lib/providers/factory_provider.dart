import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/factory.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for factories list
final factoriesProvider = StateNotifierProvider<FactoriesNotifier, AsyncValue<List<Factory>>>((ref) {
  return FactoriesNotifier(ApiService());
});

// Provider for current factory details
final factoryDetailsProvider = StateNotifierProvider.family<FactoryDetailsNotifier, AsyncValue<Factory?>, int>((ref, id) {
  return FactoryDetailsNotifier(ApiService(), id);
});

// Notifier for factories list
class FactoriesNotifier extends StateNotifier<AsyncValue<List<Factory>>> {
  final ApiService _apiService;
  
  FactoriesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchFactories();
  }
  
  // Fetch all factories
  Future<void> fetchFactories({Map<String, dynamic>? filters}) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/factories',
        (data) => {'factories': (data['factories'] as List).map((item) => Factory.fromJson(item)).toList()},
        queryParams: filters,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['factories']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch factories',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new factory
  Future<Factory?> createFactory(Map<String, dynamic> factoryData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/factories',
        factoryData,
        (data) => {'factory': Factory.fromJson(data['factory'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh factories list
        fetchFactories();
        return response.data!['factory'];
      } else {
        throw Exception(response.message ?? 'Failed to create factory');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update existing factory
  Future<Factory?> updateFactory(int id, Map<String, dynamic> factoryData) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/factories/$id',
        factoryData,
        (data) => {'factory': Factory.fromJson(data['factory'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh factories list
        fetchFactories();
        return response.data!['factory'];
      } else {
        throw Exception(response.message ?? 'Failed to update factory');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete factory
  Future<bool> deleteFactory(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/factories/$id',
        (data) => data,
      );
      
      if (response.success) {
        // Refresh factories list
        fetchFactories();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete factory');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for factory details
class FactoryDetailsNotifier extends StateNotifier<AsyncValue<Factory?>> {
  final ApiService _apiService;
  final int factoryId;
  
  FactoryDetailsNotifier(this._apiService, this.factoryId) : super(const AsyncValue.loading()) {
    if (factoryId > 0) {
      fetchFactoryDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch factory details
  Future<void> fetchFactoryDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/factories/$factoryId',
        (data) => {'factory': Factory.fromJson(data['factory'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['factory']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch factory details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
