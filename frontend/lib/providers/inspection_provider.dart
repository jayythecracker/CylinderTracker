import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cylinder.dart';
import '../services/api_service.dart';

// State class for cylinders under inspection
class InspectionState {
  final bool isLoading;
  final List<dynamic> cylinders; // List of cylinders with filling details
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final List<int> selectedCylinders; // For batch operations

  const InspectionState({
    this.isLoading = false,
    this.cylinders = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedCylinders = const [],
  });

  // Copy with method for immutability
  InspectionState copyWith({
    bool? isLoading,
    List<dynamic>? cylinders,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    List<int>? selectedCylinders,
  }) {
    return InspectionState(
      isLoading: isLoading ?? this.isLoading,
      cylinders: cylinders ?? this.cylinders,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedCylinders: selectedCylinders ?? this.selectedCylinders,
    );
  }
}

// Inspection notifier to handle inspection state
class InspectionNotifier extends StateNotifier<InspectionState> {
  final ApiService _apiService;

  InspectionNotifier(this._apiService) : super(const InspectionState());

  // Get cylinders for inspection
  Future<void> getCylindersForInspection({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'inspection/cylinders',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List<dynamic> cylinders = response['cylinders'] as List;

      state = state.copyWith(
        isLoading: false,
        cylinders: cylinders,
        totalCount: response['totalCount'] ?? 0,
        currentPage: response['currentPage'] ?? 1,
        totalPages: response['totalPages'] ?? 1,
        selectedCylinders: [], // Clear selection on new data load
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load cylinders for inspection: ${e.toString()}',
      );
    }
  }

  // Get cylinder inspection details
  Future<Map<String, dynamic>> getCylinderInspectionDetails(int id) async {
    try {
      final response = await _apiService.get('inspection/cylinders/$id');
      return {
        'cylinder': Cylinder.fromJson(response['cylinder']),
        'fillingHistory': response['fillingHistory'],
      };
    } catch (e) {
      throw Exception('Failed to load cylinder inspection details: ${e.toString()}');
    }
  }

  // Approve cylinder
  Future<Cylinder> approveCylinder(int id, {String? notes}) async {
    try {
      final response = await _apiService.patch(
        'inspection/cylinders/$id/approve',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
      
      // Remove approved cylinder from state
      final updatedCylinders = state.cylinders.where((c) => c['id'] != id).toList();
      state = state.copyWith(
        cylinders: updatedCylinders,
        totalCount: state.totalCount - 1,
      );
      
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      throw Exception('Failed to approve cylinder: ${e.toString()}');
    }
  }

  // Reject cylinder
  Future<Cylinder> rejectCylinder(int id, String reason, {String? notes}) async {
    try {
      final response = await _apiService.patch(
        'inspection/cylinders/$id/reject',
        data: {
          'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
      
      // Remove rejected cylinder from state
      final updatedCylinders = state.cylinders.where((c) => c['id'] != id).toList();
      state = state.copyWith(
        cylinders: updatedCylinders,
        totalCount: state.totalCount - 1,
      );
      
      return Cylinder.fromJson(response['cylinder']);
    } catch (e) {
      throw Exception('Failed to reject cylinder: ${e.toString()}');
    }
  }

  // Toggle cylinder selection for batch operations
  void toggleCylinderSelection(int id) {
    final selectedCylinders = [...state.selectedCylinders];
    
    if (selectedCylinders.contains(id)) {
      selectedCylinders.remove(id);
    } else {
      selectedCylinders.add(id);
    }
    
    state = state.copyWith(selectedCylinders: selectedCylinders);
  }

  // Clear cylinder selection
  void clearSelection() {
    state = state.copyWith(selectedCylinders: []);
  }

  // Select all displayed cylinders
  void selectAllDisplayed() {
    final cylinderIds = state.cylinders.map((c) => c['id'] as int).toList();
    state = state.copyWith(selectedCylinders: cylinderIds);
  }

  // Batch approve cylinders
  Future<void> batchApproveCylinders({String? notes}) async {
    try {
      if (state.selectedCylinders.isEmpty) {
        throw Exception('No cylinders selected');
      }
      
      await _apiService.post(
        'inspection/cylinders/batch-approve',
        data: {
          'cylinderIds': state.selectedCylinders,
          if (notes != null) 'notes': notes,
        },
      );
      
      // Refresh data after batch approval
      await getCylindersForInspection(page: state.currentPage);
    } catch (e) {
      throw Exception('Failed to approve cylinders: ${e.toString()}');
    }
  }

  // Batch reject cylinders
  Future<void> batchRejectCylinders(String reason, {String? notes}) async {
    try {
      if (state.selectedCylinders.isEmpty) {
        throw Exception('No cylinders selected');
      }
      
      await _apiService.post(
        'inspection/cylinders/batch-reject',
        data: {
          'cylinderIds': state.selectedCylinders,
          'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
      
      // Refresh data after batch rejection
      await getCylindersForInspection(page: state.currentPage);
    } catch (e) {
      throw Exception('Failed to reject cylinders: ${e.toString()}');
    }
  }
}

// Inspection provider
final inspectionProvider = StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InspectionNotifier(apiService);
});
