import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:cylinder_management/services/api_service.dart';

// Provider for cylinders list
final cylindersProvider = StateNotifierProvider<CylindersNotifier, AsyncValue<List<Cylinder>>>((ref) {
  return CylindersNotifier(ApiService());
});

// Provider for factory cylinders
final factoryCylindersProvider = StateNotifierProvider.family<FactoryCylindersNotifier, AsyncValue<Map<String, dynamic>>, int>((ref, factoryId) {
  return FactoryCylindersNotifier(ApiService(), factoryId);
});

// Provider for cylinder details
final cylinderDetailsProvider = StateNotifierProvider.family<CylinderDetailsNotifier, AsyncValue<Map<String, dynamic>>, int>((ref, id) {
  return CylinderDetailsNotifier(ApiService(), id);
});

// Provider for cylinder by QR code
final cylinderByQrProvider = StateNotifierProvider<CylinderByQrNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return CylinderByQrNotifier(ApiService());
});

// Notifier for cylinders list
class CylindersNotifier extends StateNotifier<AsyncValue<List<Cylinder>>> {
  final ApiService _apiService;
  
  CylindersNotifier(this._apiService) : super(const AsyncValue.loading());
  
  // Fetch all cylinders with optional filtering
  Future<void> fetchCylinders({Map<String, dynamic>? filters}) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/cylinders',
        (data) => {
          'cylinders': (data['cylinders'] as List).map((item) => Cylinder.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: filters,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!['cylinders']);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch cylinders',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Create new cylinder
  Future<Cylinder?> createCylinder(Map<String, dynamic> cylinderData) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/cylinders',
        cylinderData,
        (data) => {'cylinder': Cylinder.fromJson(data['cylinder'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh cylinders list
        fetchCylinders();
        return response.data!['cylinder'];
      } else {
        throw Exception(response.message ?? 'Failed to create cylinder');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update existing cylinder
  Future<Cylinder?> updateCylinder(int id, Map<String, dynamic> cylinderData) async {
    try {
      final response = await _apiService.put<Map<String, dynamic>>(
        '/cylinders/$id',
        cylinderData,
        (data) => {'cylinder': Cylinder.fromJson(data['cylinder'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh cylinders list
        fetchCylinders();
        return response.data!['cylinder'];
      } else {
        throw Exception(response.message ?? 'Failed to update cylinder');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update cylinder status
  Future<Cylinder?> updateCylinderStatus(int id, String status, String? notes) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        '/cylinders/$id/status',
        {
          'status': status,
          if (notes != null) 'notes': notes,
        },
        (data) => {'cylinder': Cylinder.fromJson(data['cylinder'])},
      );
      
      if (response.success && response.data != null) {
        // Refresh cylinders list
        fetchCylinders();
        return response.data!['cylinder'];
      } else {
        throw Exception(response.message ?? 'Failed to update cylinder status');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete cylinder
  Future<bool> deleteCylinder(int id) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        '/cylinders/$id',
        (data) => data,
      );
      
      if (response.success) {
        // Refresh cylinders list
        fetchCylinders();
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to delete cylinder');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for factory cylinders
class FactoryCylindersNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  final int factoryId;
  
  FactoryCylindersNotifier(this._apiService, this.factoryId) : super(const AsyncValue.loading()) {
    if (factoryId > 0) {
      fetchFactoryCylinders();
    } else {
      state = AsyncValue.data({
        'cylinders': <Cylinder>[],
        'pagination': {'total': 0, 'page': 1, 'limit': 20, 'totalPages': 0},
      });
    }
  }
  
  // Fetch cylinders for a specific factory
  Future<void> fetchFactoryCylinders({Map<String, dynamic>? filters, int page = 1, int limit = 20}) async {
    try {
      state = const AsyncValue.loading();
      
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters,
      };
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/factories/$factoryId/cylinders',
        (data) => {
          'cylinders': (data['cylinders'] as List).map((item) => Cylinder.fromJson(item)).toList(),
          'pagination': data['pagination'],
        },
        queryParams: queryParams,
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch factory cylinders',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Notifier for cylinder details
class CylinderDetailsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  final int cylinderId;
  
  CylinderDetailsNotifier(this._apiService, this.cylinderId) : super(const AsyncValue.loading()) {
    if (cylinderId > 0) {
      fetchCylinderDetails();
    } else {
      state = AsyncValue.data({
        'cylinder': null,
        'lastFilling': null,
        'lastInspection': null,
      });
    }
  }
  
  // Fetch cylinder details
  Future<void> fetchCylinderDetails() async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/cylinders/$cylinderId',
        (data) => {
          'cylinder': Cylinder.fromJson(data['cylinder']),
          'lastFilling': data['lastFilling'],
          'lastInspection': data['lastInspection'],
        },
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data!);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to fetch cylinder details',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Fetch cylinder history
  Future<Map<String, dynamic>?> fetchCylinderHistory() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/cylinders/$cylinderId/history',
        (data) => data,
      );
      
      if (response.success && response.data != null) {
        return response.data;
      } else {
        throw Exception(response.message ?? 'Failed to fetch cylinder history');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Notifier for getting cylinder by QR code
class CylinderByQrNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiService _apiService;
  
  CylinderByQrNotifier(this._apiService) : super(const AsyncValue.data(null));
  
  // Fetch cylinder by QR code
  Future<void> fetchCylinderByQr(String qrCode) async {
    try {
      state = const AsyncValue.loading();
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/cylinders/1', // ID is not important when using QR code
        (data) => {
          'cylinder': Cylinder.fromJson(data['cylinder']),
          'lastFilling': data['lastFilling'],
          'lastInspection': data['lastInspection'],
        },
        queryParams: {'qrCode': qrCode},
      );
      
      if (response.success && response.data != null) {
        state = AsyncValue.data(response.data);
      } else {
        state = AsyncValue.error(
          response.message ?? 'Failed to find cylinder with this QR code',
          StackTrace.current,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  
  // Clear current cylinder data
  void clearCylinder() {
    state = const AsyncValue.data(null);
  }
}
