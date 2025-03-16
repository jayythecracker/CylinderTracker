import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance.dart';
import '../services/api_service.dart';

class MaintenancesState {
  final List<Maintenance> maintenances;
  final bool isLoading;
  final String? error;
  final MaintenanceStatus? statusFilter;
  final int? cylinderIdFilter;

  MaintenancesState({
    this.maintenances = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.cylinderIdFilter,
  });

  MaintenancesState copyWith({
    List<Maintenance>? maintenances,
    bool? isLoading,
    String? error,
    MaintenanceStatus? statusFilter,
    int? cylinderIdFilter,
  }) {
    return MaintenancesState(
      maintenances: maintenances ?? this.maintenances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter,
      cylinderIdFilter: cylinderIdFilter,
    );
  }

  List<Maintenance> get filteredMaintenances {
    return maintenances.where((maintenance) {
      bool matchesStatus = statusFilter == null || maintenance.status == statusFilter;
      bool matchesCylinder = cylinderIdFilter == null || maintenance.cylinderId == cylinderIdFilter;
      
      return matchesStatus && matchesCylinder;
    }).toList();
  }
}

class MaintenanceNotifier extends StateNotifier<MaintenancesState> {
  final ApiService _apiService;

  MaintenanceNotifier(this._apiService) : super(MaintenancesState()) {
    fetchMaintenances();
  }

  Future<void> fetchMaintenances({
    String? status,
    int? cylinderId,
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final maintenances = await _apiService.getMaintenances(
        status: status,
        cylinderId: cylinderId,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        maintenances: maintenances,
        isLoading: false,
        statusFilter: status != null ? _parseMaintenanceStatus(status) : null,
        cylinderIdFilter: cylinderId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  MaintenanceStatus _parseMaintenanceStatus(String status) {
    switch (status) {
      case 'InProgress':
        return MaintenanceStatus.InProgress;
      case 'Completed':
        return MaintenanceStatus.Completed;
      case 'Unrepairable':
        return MaintenanceStatus.Unrepairable;
      case 'Pending':
      default:
        return MaintenanceStatus.Pending;
    }
  }

  Future<Maintenance?> getMaintenanceById(int id) async {
    try {
      return await _apiService.getMaintenanceById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createMaintenance(Map<String, dynamic> maintenanceData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createMaintenance(maintenanceData);
      await fetchMaintenances(
        status: state.statusFilter?.toString().split('.').last,
        cylinderId: state.cylinderIdFilter,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateMaintenance(int id, Map<String, dynamic> maintenanceData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.updateMaintenance(id, maintenanceData);
      await fetchMaintenances(
        status: state.statusFilter?.toString().split('.').last,
        cylinderId: state.cylinderIdFilter,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> completeMaintenance(int id, Map<String, dynamic> maintenanceData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.completeMaintenance(id, maintenanceData);
      await fetchMaintenances(
        status: state.statusFilter?.toString().split('.').last,
        cylinderId: state.cylinderIdFilter,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> markUnrepairable(int id, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.markUnrepairable(id, reason);
      await fetchMaintenances(
        status: state.statusFilter?.toString().split('.').last,
        cylinderId: state.cylinderIdFilter,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void setFilters({
    MaintenanceStatus? statusFilter,
    int? cylinderIdFilter,
  }) {
    state = state.copyWith(
      statusFilter: statusFilter,
      cylinderIdFilter: cylinderIdFilter,
    );

    fetchMaintenances(
      status: statusFilter?.toString().split('.').last,
      cylinderId: cylinderIdFilter,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      cylinderIdFilter: null,
    );
    fetchMaintenances();
  }
}

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, MaintenancesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MaintenanceNotifier(apiService);
});
