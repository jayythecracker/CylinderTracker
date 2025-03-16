import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/inspection.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for inspections list
final inspectionsProvider = StateNotifierProvider<InspectionsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return InspectionsNotifier(ApiService());
});

// Provider for inspection details
final inspectionDetailsProvider = StateNotifierProvider.family<InspectionDetailsNotifier, AsyncValue<Inspection?>, int>((ref, id) {
  return InspectionDetailsNotifier(ApiService(), id);
});

// Provider for inspection stats
final inspectionStatsProvider = StateNotifierProvider<InspectionStatsNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return InspectionStatsNotifier(ApiService());
});

// Notifier for inspections list
class InspectionsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  InspectionsNotifier(this._apiService) : super(const AsyncValue.loading());
  
  // Fetch all inspections with pagination
  Future<void> fetchInspections({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inspections',
        (data) => {
          'inspections': (data['inspections'] as List).map((item) => Inspection.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch inspections',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new inspection
  Future<Inspection?> createInspection(Map<String, dynamic> inspectionData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/inspections',
        inspectionData,
        (data) => {'inspection': Inspection.fromJson(data['inspection'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh inspections list
        fetchInspections();
        return response.data!['inspection'];
      } else {
        throw Exception(response.message ?? 'Failed to create inspection');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Batch create inspections (approve all)
  Future<Map<String, dynamic>?> batchCreateInspections(Map<String, dynamic> inspectionData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/inspections/batch',
        inspectionData,
        (data) => data,
      );
      
      if (response.success && response.data != null) {
        // Refresh inspections list
        fetchInspections();
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to create batch inspections');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for inspection details
class InspectionDetailsNotifier extends StateNotifier<AsyncValue<Inspection?>> {
  final ApiService _apiService;
  final int inspectionId;
  
  InspectionDetailsNotifier(this._apiService, this.inspectionId) : super(const AsyncValue.loading()) {
    if (inspectionId > 0) {
      fetchInspectionDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch inspection details
  Future<void> fetchInspectionDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inspections/$inspectionId',
        (data) => {'inspection': Inspection.fromJson(data['inspection'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['inspection']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch inspection details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for inspection stats
class InspectionStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiService _apiService;
  
  InspectionStatsNotifier(this._apiService) : super(const AsyncValue.data(null));
  
  // Fetch inspection stats
  Future<void> fetchStats({String period = 'daily'}) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/inspections/stats/overview',
        (data) => data,
        queryParams: {'period': period},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch inspection statistics',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
