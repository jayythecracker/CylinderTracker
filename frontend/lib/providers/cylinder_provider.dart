import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cylinder.dart';
import '../services/api_service.dart';

// State class for cylinder list
class CylindersState {
  final bool isLoading;
  final List<Cylinder> cylinders;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const CylindersState({
    this.isLoading = false,
    this.cylinders = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  // Copy with method for immutability
  CylindersState copyWith({
    bool? isLoading,
    List<Cylinder>? cylinders,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return CylindersState(
      isLoading: isLoading ?? this.isLoading,
      cylinders: cylinders ?? this.cylinders,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Cylinder notifier to handle cylinder list state
class CylinderNotifier extends StateNotifier<CylindersState> {
  final ApiService _apiService;

  CylinderNotifier(this._apiService) : super(const CylindersState());

  // Get cylinders with pagination and filters
  Future<void> getCylinders({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    int? factoryId,
    String? search,
    String? sortBy,
    String? order,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'cylinders',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': status,
          if (type != null) 'type': type,
          if (factoryId != null) 'factoryId': factoryId.toString(),
          if (search != null && search.isNotEmpty) 'search': search,
          if (sortBy != null) 'sortBy': sortBy,
          if (order != null) 'order': order,
        },
      );

      final List<Cylinder> cylinders = (response['cylinders'] as List)
          .map((json) => Cylinder.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        cylinders: cylinders,
        totalCount: response['totalCount'] ?? 0,
        currentPage: response['currentPage'] ?? 1,
        totalPages: response['totalPages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cylinders: ${e.toString()}',
      );
    }
  }

  // Get cylinder by ID
  Future<Cylinder?> getCylinderById(int id) async {
    try {
      final response = await _apiService.get('cylinders/$id');
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      throw Exception('Failed to load cylinder: ${e.toString()}');
    }
  }

  // Get cylinder by QR code
  Future<Cylinder?> getCylinderByQR(String qrCode) async {
    try {
      final response = await _apiService.get('cylinders/qr/$qrCode');
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      throw Exception('Failed to load cylinder: ${e.toString()}');
    }
  }

  // Create cylinder
  Future<Cylinder> createCylinder(Map<String, dynamic> cylinderData) async {
    try {
      final response = await _apiService.post('cylinders', data: cylinderData);
      final cylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with new cylinder
      state = state.copyWith(
        cylinders: [...state.cylinders, cylinder],
        totalCount: state.totalCount + 1,
      );
      
      return cylinder;
    } catch (e) {
      throw Exception('Failed to create cylinder: ${e.toString()}');
    }
  }

  // Update cylinder
  Future<Cylinder> updateCylinder(int id, Map<String, dynamic> cylinderData) async {
    try {
      final response = await _apiService.put('cylinders/$id', data: cylinderData);
      final updatedCylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with updated cylinder
      final index = state.cylinders.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final updatedCylinders = [...state.cylinders];
        updatedCylinders[index] = updatedCylinder;
        state = state.copyWith(cylinders: updatedCylinders);
      }
      
      return updatedCylinder;
    } catch (e) {
      throw Exception('Failed to update cylinder: ${e.toString()}');
    }
  }

  // Update cylinder status
  Future<Cylinder> updateCylinderStatus(int id, String status, {String? notes}) async {
    try {
      final response = await _apiService.patch(
        'cylinders/$id/status',
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
      final updatedCylinder = Cylinder.fromJson(response['cylinder']);
      
      // Update state with updated cylinder status
      final index = state.cylinders.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final updatedCylinders = [...state.cylinders];
        updatedCylinders[index] = updatedCylinder;
        state = state.copyWith(cylinders: updatedCylinders);
      }
      
      return updatedCylinder;
    } catch (e) {
      throw Exception('Failed to update cylinder status: ${e.toString()}');
    }
  }

  // Batch update cylinder status
  Future<void> batchUpdateStatus(List<int> cylinderIds, String status, {String? notes}) async {
    try {
      await _apiService.post(
        'cylinders/batch-update',
        data: {
          'cylinderIds': cylinderIds,
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
      
      // Refresh cylinders after batch update
      await getCylinders(page: state.currentPage);
    } catch (e) {
      throw Exception('Failed to batch update cylinders: ${e.toString()}');
    }
  }

  // Delete cylinder
  Future<void> deleteCylinder(int id) async {
    try {
      await _apiService.delete('cylinders/$id');
      
      // Update state by removing deleted cylinder
      final updatedCylinders = state.cylinders.where((c) => c.id != id).toList();
      state = state.copyWith(
        cylinders: updatedCylinders,
        totalCount: state.totalCount - 1,
      );
    } catch (e) {
      throw Exception('Failed to delete cylinder: ${e.toString()}');
    }
  }
}

// Cylinder providers
final cylinderProvider = StateNotifierProvider<CylinderNotifier, CylindersState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CylinderNotifier(apiService);
});

// Provider for current cylinder (for details page)
final currentCylinderProvider = StateProvider<Cylinder?>((ref) => null);
