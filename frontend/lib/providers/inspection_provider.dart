import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inspection.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for inspections list state
final inspectionsProvider = AsyncNotifierProvider<InspectionsNotifier, List<Inspection>>(() {
  return InspectionsNotifier();
});

// Provider for selected inspection
final selectedInspectionProvider = StateProvider<Inspection?>((ref) => null);

// Provider for inspection filter parameters
final inspectionFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'result': null,
    'cylinderId': null,
    'inspectedById': null,
    'startDate': null,
    'endDate': null,
    'page': 1,
    'limit': AppConfig.defaultPageSize,
  };
});

// Provider for inspections pagination info
final inspectionPaginationProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalCount': 0,
    'currentPage': 1,
    'totalPages': 1,
  };
});

// Provider for cylinder inspection history
final cylinderInspectionHistoryProvider = AsyncNotifierProvider<CylinderInspectionHistoryNotifier, List<Inspection>>(() {
  return CylinderInspectionHistoryNotifier();
});

class InspectionsNotifier extends AsyncNotifier<List<Inspection>> {
  late ApiService _apiService;
  
  @override
  Future<List<Inspection>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all inspections with optional filters
  Future<void> getInspections({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();
    
    try {
      final currentFilters = ref.read(inspectionFilterProvider);
      final queryParams = filters ?? currentFilters;
      
      // Update filter provider if new filters are provided
      if (filters != null) {
        ref.read(inspectionFilterProvider.notifier).state = {
          ...currentFilters,
          ...filters,
        };
      }
      
      final response = await _apiService.get(
        AppConfig.inspectionsEndpoint,
        queryParams: queryParams,
      );
      
      final List<Inspection> inspections = (response['inspections'] as List)
          .map((inspectionData) => Inspection.fromJson(inspectionData))
          .toList();
      
      // Update pagination info
      ref.read(inspectionPaginationProvider.notifier).state = {
        'totalCount': response['totalCount'],
        'currentPage': response['currentPage'],
        'totalPages': response['totalPages'],
      };
      
      state = AsyncValue.data(inspections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get inspection by ID
  Future<Inspection> getInspectionById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.inspectionsEndpoint}/$id');
      return Inspection.fromJson(response['inspection']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create new inspection
  Future<Inspection> createInspection(Inspection inspection) async {
    try {
      final response = await _apiService.post(
        AppConfig.inspectionsEndpoint,
        data: inspection.toCreateJson(),
      );
      
      final newInspection = Inspection.fromJson(response['inspection']);
      
      // Update state with new inspection
      state = AsyncValue.data([...state.value ?? [], newInspection]);
      
      return newInspection;
    } catch (e) {
      rethrow;
    }
  }
  
  // Batch inspect cylinders
  Future<void> batchInspect(List<int> cylinderIds, String result, String? notes) async {
    try {
      await _apiService.post(
        '${AppConfig.inspectionsEndpoint}/batch',
        data: Inspection.toBatchInspectJson(
          cylinderIds: cylinderIds,
          result: result,
          notes: notes,
        ),
      );
      
      // Refresh inspections list
      await getInspections();
    } catch (e) {
      rethrow;
    }
  }
}

class CylinderInspectionHistoryNotifier extends AsyncNotifier<List<Inspection>> {
  late ApiService _apiService;
  
  @override
  Future<List<Inspection>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get cylinder inspection history
  Future<void> getCylinderInspectionHistory(int cylinderId) async {
    state = const AsyncValue.loading();
    
    try {
      final response = await _apiService.get('${AppConfig.inspectionsEndpoint}/cylinder/$cylinderId');
      
      final List<Inspection> inspections = (response['inspections'] as List)
          .map((inspectionData) => Inspection.fromJson(inspectionData))
          .toList();
      
      state = AsyncValue.data(inspections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
