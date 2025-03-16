import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Report notifier class
class ReportNotifier extends StateNotifier<bool> {
  final ApiService _apiService;

  ReportNotifier(this._apiService) : super(false);

  // Get daily sales report
  Future<Map<String, dynamic>> getDailySalesReport({String? date}) async {
    try {
      state = true;

      final response = await _apiService.get(
        'reports/sales/daily',
        queryParameters: {
          if (date != null) 'date': date,
        },
      );

      state = false;
      return response;
    } catch (e) {
      state = false;
      throw Exception('Failed to load daily sales report: ${e.toString()}');
    }
  }

  // Get monthly sales report
  Future<Map<String, dynamic>> getMonthlySalesReport({int? year, int? month}) async {
    try {
      state = true;

      final response = await _apiService.get(
        'reports/sales/monthly',
        queryParameters: {
          if (year != null) 'year': year.toString(),
          if (month != null) 'month': month.toString(),
        },
      );

      state = false;
      return response;
    } catch (e) {
      state = false;
      throw Exception('Failed to load monthly sales report: ${e.toString()}');
    }
  }

  // Get cylinder status report
  Future<Map<String, dynamic>> getCylinderStatusReport() async {
    try {
      state = true;

      final response = await _apiService.get('reports/cylinders/status');

      state = false;
      return response;
    } catch (e) {
      state = false;
      throw Exception('Failed to load cylinder status report: ${e.toString()}');
    }
  }

  // Get filling activity report
  Future<Map<String, dynamic>> getFillingActivityReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      state = true;

      final response = await _apiService.get(
        'reports/filling/activity',
        queryParameters: {
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );

      state = false;
      return response;
    } catch (e) {
      state = false;
      throw Exception('Failed to load filling activity report: ${e.toString()}');
    }
  }

  // Get customer activity report
  Future<Map<String, dynamic>> getCustomerActivityReport({
    required int customerId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      state = true;

      final response = await _apiService.get(
        'reports/customers/activity',
        queryParameters: {
          'customerId': customerId.toString(),
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );

      state = false;
      return response;
    } catch (e) {
      state = false;
      throw Exception('Failed to load customer activity report: ${e.toString()}');
    }
  }
}

// Report provider
final reportProvider = StateNotifierProvider<ReportNotifier, bool>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportNotifier(apiService);
});
