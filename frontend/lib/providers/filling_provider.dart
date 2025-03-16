import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filling.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for filling lines list state
final fillingLinesProvider = AsyncNotifierProvider<FillingLinesNotifier, List<FillingLine>>(() {
  return FillingLinesNotifier();
});

// Provider for selected filling line
final selectedFillingLineProvider = StateProvider<FillingLine?>((ref) => null);

// Provider for filling batches list state
final fillingBatchesProvider = AsyncNotifierProvider<FillingBatchesNotifier, List<FillingBatch>>(() {
  return FillingBatchesNotifier();
});

// Provider for selected filling batch
final selectedFillingBatchProvider = StateProvider<FillingBatch?>((ref) => null);

// Provider for filling batch filter parameters
final fillingBatchFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'status': null,
    'fillingLineId': null,
    'startDate': null,
    'endDate': null,
    'page': 1,
    'limit': AppConfig.defaultPageSize,
  };
});

// Provider for filling batches pagination info
final fillingBatchPaginationProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalCount': 0,
    'currentPage': 1,
    'totalPages': 1,
  };
});

class FillingLinesNotifier extends AsyncNotifier<List<FillingLine>> {
  late ApiService _apiService;
  
  @override
  Future<List<FillingLine>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all filling lines
  Future<void> getFillingLines() async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _apiService.get(AppConfig.fillingLinesEndpoint);
      final List<FillingLine> fillingLines = (response['fillingLines'] as List)
          .map((lineData) => FillingLine.fromJson(lineData))
          .toList();
      
      state = AsyncValue.data(fillingLines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get filling line by ID
  Future<FillingLine> getFillingLineById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.fillingLinesEndpoint}/$id');
      return FillingLine.fromJson(response['fillingLine']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create filling line
  Future<FillingLine> createFillingLine(FillingLine fillingLine) async {
    try {
      final response = await _apiService.post(
        AppConfig.fillingLinesEndpoint,
        data: fillingLine.toCreateJson(),
      );
      
      final newFillingLine = FillingLine.fromJson(response['fillingLine']);
      
      // Update state with new filling line
      state = AsyncValue.data([...state.value ?? [], newFillingLine]);
      
      return newFillingLine;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update filling line
  Future<FillingLine> updateFillingLine(int id, FillingLine updatedLine) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.fillingLinesEndpoint}/$id',
        data: {
          'name': updatedLine.name,
          'capacity': updatedLine.capacity,
          'gasType': updatedLine.gasType,
          'status': updatedLine.status,
        },
      );
      
      final fillingLine = FillingLine.fromJson(response['fillingLine']);
      
      // Update state with updated filling line
      state = AsyncValue.data(
        state.value?.map((line) => line.id == id ? fillingLine : line).toList() ?? [],
      );
      
      return fillingLine;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete filling line
  Future<void> deleteFillingLine(int id) async {
    try {
      await _apiService.delete('${AppConfig.fillingLinesEndpoint}/$id');
      
      // Update state by removing deleted filling line
      state = AsyncValue.data(
        state.value?.where((line) => line.id != id).toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }
}

class FillingBatchesNotifier extends AsyncNotifier<List<FillingBatch>> {
  late ApiService _apiService;
  
  @override
  Future<List<FillingBatch>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all filling batches with optional filters
  Future<void> getFillingBatches({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();
    
    try {
      final currentFilters = ref.read(fillingBatchFilterProvider);
      final queryParams = filters ?? currentFilters;
      
      // Update filter provider if new filters are provided
      if (filters != null) {
        ref.read(fillingBatchFilterProvider.notifier).state = {
          ...currentFilters,
          ...filters,
        };
      }
      
      final response = await _apiService.get(
        AppConfig.fillingBatchesEndpoint,
        queryParams: queryParams,
      );
      
      final List<FillingBatch> batches = (response['batches'] as List)
          .map((batchData) => FillingBatch.fromJson(batchData))
          .toList();
      
      // Update pagination info
      ref.read(fillingBatchPaginationProvider.notifier).state = {
        'totalCount': response['totalCount'],
        'currentPage': response['currentPage'],
        'totalPages': response['totalPages'],
      };
      
      state = AsyncValue.data(batches);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get filling batch by ID
  Future<FillingBatch> getFillingBatchById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.fillingBatchesEndpoint}/$id');
      return FillingBatch.fromJson(response['batch']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Start new filling batch
  Future<FillingBatch> startFillingBatch(FillingBatch batch) async {
    try {
      final response = await _apiService.post(
        AppConfig.fillingBatchesEndpoint,
        data: batch.toStartBatchJson(),
      );
      
      final newBatch = FillingBatch.fromJson(response['batch']);
      
      // Update state with new batch
      state = AsyncValue.data([...state.value ?? [], newBatch]);
      
      return newBatch;
    } catch (e) {
      rethrow;
    }
  }
  
  // Complete filling batch
  Future<FillingBatch> completeFillingBatch(int id, List<FillingDetail> details, String? notes) async {
    try {
      final FillingBatch batch = FillingBatch(
        id: id,
        batchNumber: '',
        startTime: DateTime.now(),
        status: 'Completed',
        fillingLineId: 0,
        startedById: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
        details: details,
      );
      
      final response = await _apiService.put(
        '${AppConfig.fillingBatchesEndpoint}/$id/complete',
        data: batch.toCompleteBatchJson(),
      );
      
      final completedBatch = FillingBatch.fromJson(response['batch']);
      
      // Update state with completed batch
      state = AsyncValue.data(
        state.value?.map((b) => b.id == id ? completedBatch : b).toList() ?? [],
      );
      
      return completedBatch;
    } catch (e) {
      rethrow;
    }
  }
}
