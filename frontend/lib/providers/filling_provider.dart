import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/filling.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for fillings list
final fillingsProvider = StateNotifierProvider<FillingsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return FillingsNotifier(ApiService());
});

// Provider for filling details
final fillingDetailsProvider = StateNotifierProvider.family<FillingDetailsNotifier, AsyncValue<Filling?>, int>((ref, id) {
  return FillingDetailsNotifier(ApiService(), id);
});

// Provider for active filling lines
final activeFillingLinesProvider = StateNotifierProvider<ActiveFillingLinesNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return ActiveFillingLinesNotifier(ApiService());
});

// Provider for filling stats
final fillingStatsProvider = StateNotifierProvider<FillingStatsNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return FillingStatsNotifier(ApiService());
});

// Notifier for fillings list
class FillingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  FillingsNotifier(this._apiService) : super(const AsyncValue.loading());
  
  // Fetch all fillings with pagination
  Future<void> fetchFillings({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/fillings',
        (data) => {
          'fillings': (data['fillings'] as List).map((item) => Filling.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch fillings',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Start filling process
  Future<Filling?> startFilling(Map<String, dynamic> fillingData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/fillings',
        fillingData,
        (data) => {'filling': Filling.fromJson(data['filling'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh fillings list
        fetchFillings();
        return response.data!['filling'];
      } else {
        throw Exception(response.message ?? 'Failed to start filling process');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Complete filling process
  Future<Filling?> completeFilling(int id, Map<String, dynamic> fillingData) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/fillings/$id',
        fillingData,
        (data) => {'filling': Filling.fromJson(data['filling'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh fillings list
        fetchFillings();
        return response.data!['filling'];
      } else {
        throw Exception(response.message ?? 'Failed to complete filling process');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for filling details
class FillingDetailsNotifier extends StateNotifier<AsyncValue<Filling?>> {
  final ApiService _apiService;
  final int fillingId;
  
  FillingDetailsNotifier(this._apiService, this.fillingId) : super(const AsyncValue.loading()) {
    if (fillingId > 0) {
      fetchFillingDetails();
    } else {
      state = const AsyncValue.data(null);
    }
  }
  
  // Fetch filling details
  Future<void> fetchFillingDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/fillings/$fillingId',
        (data) => {'filling': Filling.fromJson(data['filling'])},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['filling']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch filling details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for active filling lines
class ActiveFillingLinesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  ActiveFillingLinesNotifier(this._apiService) : super(const AsyncValue.loading());
  
  // Fetch active filling lines
  Future<void> fetchActiveLines() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/fillings/lines/active',
        (data) => data,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch active filling lines',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for filling stats
class FillingStatsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiService _apiService;
  
  FillingStatsNotifier(this._apiService) : super(const AsyncValue.data(null));
  
  // Fetch filling stats
  Future<void> fetchStats({String period = 'daily'}) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/fillings/stats/overview',
        (data) => data,
        queryParams: {'period': period},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch filling statistics',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
