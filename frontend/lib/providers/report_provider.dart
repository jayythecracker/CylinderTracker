import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ReportData {
  final Map<String, dynamic> data;
  final bool isLoading;
  final String? error;

  ReportData({
    required this.data,
    this.isLoading = false,
    this.error,
  });

  ReportData copyWith({
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return ReportData(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReportNotifier extends StateNotifier<Map<String, ReportData>> {
  final ApiService _apiService;

  ReportNotifier(this._apiService) : super({
    'cylinderStatus': ReportData(data: {}),
    'filling': ReportData(data: {}),
    'inspection': ReportData(data: {}),
    'delivery': ReportData(data: {}),
    'customerDelivery': ReportData(data: {}),
    'maintenance': ReportData(data: {}),
  });

  Future<void> getCylinderStatusReport() async {
    state = {
      ...state,
      'cylinderStatus': state['cylinderStatus']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getCylinderStatusReport();
      state = {
        ...state,
        'cylinderStatus': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'cylinderStatus': state['cylinderStatus']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> getFillingReport({String? startDate, String? endDate}) async {
    state = {
      ...state,
      'filling': state['filling']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getFillingReport(startDate: startDate, endDate: endDate);
      state = {
        ...state,
        'filling': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'filling': state['filling']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> getInspectionReport({String? startDate, String? endDate}) async {
    state = {
      ...state,
      'inspection': state['inspection']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getInspectionReport(startDate: startDate, endDate: endDate);
      state = {
        ...state,
        'inspection': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'inspection': state['inspection']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> getDeliveryReport({String? startDate, String? endDate}) async {
    state = {
      ...state,
      'delivery': state['delivery']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getDeliveryReport(startDate: startDate, endDate: endDate);
      state = {
        ...state,
        'delivery': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'delivery': state['delivery']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> getCustomerDeliveryReport({String? startDate, String? endDate}) async {
    state = {
      ...state,
      'customerDelivery': state['customerDelivery']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getCustomerDeliveryReport(startDate: startDate, endDate: endDate);
      state = {
        ...state,
        'customerDelivery': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'customerDelivery': state['customerDelivery']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  Future<void> getMaintenanceReport({String? startDate, String? endDate}) async {
    state = {
      ...state,
      'maintenance': state['maintenance']!.copyWith(isLoading: true, error: null),
    };

    try {
      final report = await _apiService.getMaintenanceReport(startDate: startDate, endDate: endDate);
      state = {
        ...state,
        'maintenance': ReportData(
          data: report,
          isLoading: false,
        ),
      };
    } catch (e) {
      state = {
        ...state,
        'maintenance': state['maintenance']!.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  // Load all reports at once
  Future<void> loadAllReports({String? startDate, String? endDate}) async {
    await Future.wait([
      getCylinderStatusReport(),
      getFillingReport(startDate: startDate, endDate: endDate),
      getInspectionReport(startDate: startDate, endDate: endDate),
      getDeliveryReport(startDate: startDate, endDate: endDate),
      getCustomerDeliveryReport(startDate: startDate, endDate: endDate),
      getMaintenanceReport(startDate: startDate, endDate: endDate),
    ]);
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, Map<String, ReportData>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportNotifier(apiService);
});
