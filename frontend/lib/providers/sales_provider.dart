import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

// State class for sales list
class SalesState {
  final bool isLoading;
  final List<Sale> sales;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const SalesState({
    this.isLoading = false,
    this.sales = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  // Copy with method for immutability
  SalesState copyWith({
    bool? isLoading,
    List<Sale>? sales,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return SalesState(
      isLoading: isLoading ?? this.isLoading,
      sales: sales ?? this.sales,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Sale notifier to handle sales list state
class SaleNotifier extends StateNotifier<SalesState> {
  final ApiService _apiService;

  SaleNotifier(this._apiService) : super(const SalesState());

  // Get sales with pagination and filters
  Future<void> getSales({
    int page = 1,
    int limit = 20,
    String? status,
    int? customerId,
    String? deliveryType,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'sales',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': status,
          if (customerId != null) 'customerId': customerId.toString(),
          if (deliveryType != null) 'deliveryType': deliveryType,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List<Sale> sales = (response['sales'] as List)
          .map((json) => Sale.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        sales: sales,
        totalCount: response['totalCount'] ?? 0,
        currentPage: response['currentPage'] ?? 1,
        totalPages: response['totalPages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load sales: ${e.toString()}',
      );
    }
  }

  // Get sale by ID
  Future<Sale> getSaleById(int id) async {
    try {
      final response = await _apiService.get('sales/$id');
      return Sale.fromJson(response['sale']);
    } catch (e) {
      throw Exception('Failed to load sale: ${e.toString()}');
    }
  }

  // Create sale
  Future<Sale> createSale(Map<String, dynamic> saleData) async {
    try {
      final response = await _apiService.post('sales', data: saleData);
      final sale = Sale.fromJson(response['sale']);
      
      // Update state with new sale
      state = state.copyWith(
        sales: [sale, ...state.sales],
        totalCount: state.totalCount + 1,
      );
      
      return sale;
    } catch (e) {
      throw Exception('Failed to create sale: ${e.toString()}');
    }
  }

  // Update sale status
  Future<Sale> updateSaleStatus(
    int id, 
    String status, 
    {double? paidAmount, bool? customerSignature, String? notes}
  ) async {
    try {
      final response = await _apiService.patch(
        'sales/$id/status',
        data: {
          'status': status,
          if (paidAmount != null) 'paidAmount': paidAmount,
          if (customerSignature != null) 'customerSignature': customerSignature,
          if (notes != null) 'notes': notes,
        },
      );
      
      final updatedSale = Sale.fromJson(response['sale']);
      
      // Update state with updated sale
      final index = state.sales.indexWhere((s) => s.id == id);
      if (index >= 0) {
        final updatedSales = [...state.sales];
        updatedSales[index] = updatedSale;
        state = state.copyWith(sales: updatedSales);
      }
      
      return updatedSale;
    } catch (e) {
      throw Exception('Failed to update sale status: ${e.toString()}');
    }
  }

  // Add cylinder returns
  Future<Sale> addCylinderReturns(int id, List<int> cylinderIds, {String? notes}) async {
    try {
      final response = await _apiService.post(
        'sales/$id/returns',
        data: {
          'cylinderIds': cylinderIds,
          if (notes != null) 'notes': notes,
        },
      );
      
      // Get updated sale after adding returns
      return await getSaleById(id);
    } catch (e) {
      throw Exception('Failed to add cylinder returns: ${e.toString()}');
    }
  }

  // Cancel sale
  Future<Sale> cancelSale(int id, String reason) async {
    try {
      final response = await _apiService.patch(
        'sales/$id/cancel',
        data: {
          'reason': reason,
        },
      );
      
      final updatedSale = Sale.fromJson(response['sale']);
      
      // Update state with cancelled sale
      final index = state.sales.indexWhere((s) => s.id == id);
      if (index >= 0) {
        final updatedSales = [...state.sales];
        updatedSales[index] = updatedSale;
        state = state.copyWith(sales: updatedSales);
      }
      
      return updatedSale;
    } catch (e) {
      throw Exception('Failed to cancel sale: ${e.toString()}');
    }
  }
}

// Sale providers
final saleProvider = StateNotifierProvider<SaleNotifier, SalesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SaleNotifier(apiService);
});

// Provider for current sale (for details page)
final currentSaleProvider = StateProvider<Sale?>((ref) => null);
