import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cylinder.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for cylinders list state
final cylindersProvider = AsyncNotifierProvider<CylindersNotifier, List<Cylinder>>(() {
  return CylindersNotifier();
});

// Provider for selected cylinder
final selectedCylinderProvider = StateProvider<Cylinder?>((ref) => null);

// Provider for cylinder filter parameters
final cylinderFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'status': null,
    'gasType': null,
    'factoryId': null,
    'size': null,
    'search': null,
    'page': 1,
    'limit': AppConfig.defaultPageSize,
  };
});

// Provider for cylinders pagination info
final cylinderPaginationProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalCount': 0,
    'currentPage': 1,
    'totalPages': 1,
  };
});

class CylindersNotifier extends AsyncNotifier<List<Cylinder>> {
  late ApiService _apiService;
  
  @override
  Future<List<Cylinder>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all cylinders with optional filters
  Future<void> getCylinders({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();
    
    try {
      final currentFilters = ref.read(cylinderFilterProvider);
      final queryParams = filters ?? currentFilters;
      
      // Update filter provider if new filters are provided
      if (filters != null) {
        ref.read(cylinderFilterProvider.notifier).state = {
          ...currentFilters,
          ...filters,
        };
      }
      
      final response = await _apiService.get(
        AppConfig.cylindersEndpoint,
        queryParams: queryParams,
      );
      
      final List<Cylinder> cylinders = (response['cylinders'] as List)
          .map((cylinderData) => Cylinder.fromJson(cylinderData))
          .toList();
      
      // Update pagination info
      ref.read(cylinderPaginationProvider.notifier).state = {
        'totalCount': response['totalCount'],
        'currentPage': response['currentPage'],
        'totalPages': response['totalPages'],
      };
      
      state = AsyncValue.data(cylinders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get cylinder by ID
  Future<Cylinder> getCylinderById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.cylindersEndpoint}/$id');
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get cylinder by QR code
  Future<Cylinder> getCylinderByQRCode(String qrCode) async {
    try {
      final response = await _apiService.get('${AppConfig.cylindersByQREndpoint}/$qrCode');
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create cylinder
  Future<Cylinder> createCylinder(Cylinder cylinder) async {
    try {
      final response = await _apiService.post(
        AppConfig.cylindersEndpoint,
        data: cylinder.toCreateJson(),
      );
      
      final newCylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with new cylinder
      state = AsyncValue.data([...state.value ?? [], newCylinder]);
      
      return newCylinder;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update cylinder
  Future<Cylinder> updateCylinder(int id, Cylinder updatedCylinder) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.cylindersEndpoint}/$id',
        data: {
          'serialNumber': updatedCylinder.serialNumber,
          'size': updatedCylinder.size,
          'importDate': updatedCylinder.importDate?.toIso8601String(),
          'productionDate': updatedCylinder.productionDate.toIso8601String(),
          'originalNumber': updatedCylinder.originalNumber,
          'workingPressure': updatedCylinder.workingPressure,
          'designPressure': updatedCylinder.designPressure,
          'gasType': updatedCylinder.gasType,
          'factoryId': updatedCylinder.factoryId,
          'status': updatedCylinder.status,
        },
      );
      
      final cylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with updated cylinder
      state = AsyncValue.data(
        state.value?.map((c) => c.id == id ? cylinder : c).toList() ?? [],
      );
      
      return cylinder;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update cylinder status
  Future<Cylinder> updateCylinderStatus(int id, String status) async {
    try {
      final response = await _apiService.put(
        '${AppConfig.cylindersEndpoint}/$id/status',
        data: {
          'status': status,
        },
      );
      
      final cylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with updated cylinder
      state = AsyncValue.data(
        state.value?.map((c) => c.id == id ? cylinder : c).toList() ?? [],
      );
      
      return cylinder;
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete cylinder
  Future<void> deleteCylinder(int id) async {
    try {
      await _apiService.delete('${AppConfig.cylindersEndpoint}/$id');
      
      // Update state by removing deleted cylinder
      state = AsyncValue.data(
        state.value?.where((cylinder) => cylinder.id != id).toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }
}
