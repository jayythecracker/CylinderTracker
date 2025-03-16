import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

// Provider for sales list state
final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});

// Provider for selected sale
final selectedSaleProvider = StateProvider<Sale?>((ref) => null);

// Provider for sale filter parameters
final saleFilterProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'status': null,
    'customerId': null,
    'sellerId': null,
    'deliveryType': null,
    'paymentStatus': null,
    'startDate': null,
    'endDate': null,
    'page': 1,
    'limit': AppConfig.defaultPageSize,
  };
});

// Provider for sales pagination info
final salePaginationProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'totalCount': 0,
    'currentPage': 1,
    'totalPages': 1,
  };
});

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  late ApiService _apiService;
  
  @override
  Future<List<Sale>> build() async {
    _apiService = ref.read(apiServiceProvider);
    return [];
  }
  
  // Get all sales with optional filters
  Future<void> getSales({Map<String, dynamic>? filters}) async {
    state = const AsyncValue.loading();
    
    try {
      final currentFilters = ref.read(saleFilterProvider);
      final queryParams = filters ?? currentFilters;
      
      // Update filter provider if new filters are provided
      if (filters != null) {
        ref.read(saleFilterProvider.notifier).state = {
          ...currentFilters,
          ...filters,
        };
      }
      
      final response = await _apiService.get(
        AppConfig.salesEndpoint,
        queryParams: queryParams,
      );
      
      final List<Sale> sales = (response['sales'] as List)
          .map((saleData) => Sale.fromJson(saleData))
          .toList();
      
      // Update pagination info
      ref.read(salePaginationProvider.notifier).state = {
        'totalCount': response['totalCount'],
        'currentPage': response['currentPage'],
        'totalPages': response['totalPages'],
      };
      
      state = AsyncValue.data(sales);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // Get sale by ID
  Future<Sale> getSaleById(int id) async {
    try {
      final response = await _apiService.get('${AppConfig.salesEndpoint}/$id');
      return Sale.fromJson(response['sale']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Create new sale
  Future<Sale> createSale(Sale sale) async {
    try {
      final response = await _apiService.post(
        AppConfig.salesEndpoint,
        data: sale.toCreateJson(),
      );
      
      final newSale = Sale.fromJson(response['sale']);
      
      // Update state with new sale
      state = AsyncValue.data([...state.value ?? [], newSale]);
      
      return newSale;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update sale status
  Future<Sale> updateSaleStatus(int id, String status, String? customerSignature, DateTime? deliveryDate) async {
    try {
      final sale = Sale(
        id: id,
        invoiceNumber: '',
        saleDate: DateTime.now(),
        customerId: 0,
        sellerId: 0,
        deliveryType: '',
        status: status,
        totalAmount: 0,
        paidAmount: 0,
        paymentStatus: '',
        paymentMethod: '',
        customerSignature: customerSignature,
        deliveryDate: deliveryDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final response = await _apiService.put(
        '${AppConfig.salesEndpoint}/$id/status',
        data: sale.toUpdateStatusJson(),
      );
      
      final updatedSale = Sale.fromJson(response['sale']);
      
      // Update state with updated sale
      state = AsyncValue.data(
        state.value?.map((s) => s.id == id ? updatedSale : s).toList() ?? [],
      );
      
      return updatedSale;
    } catch (e) {
      rethrow;
    }
  }
  
  // Record cylinder return
  Future<SaleItem> recordCylinderReturn(int itemId) async {
    try {
      final saleItem = SaleItem(
        id: itemId,
        saleId: 0,
        cylinderId: 0,
        price: 0,
        returnedEmpty: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final response = await _apiService.put(
        '${AppConfig.salesEndpoint}/items/$itemId/return',
        data: saleItem.toReturnJson(),
      );
      
      return SaleItem.fromJson(response['saleItem']);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update sale payment
  Future<Sale> updateSalePayment(int id, double paidAmount, String paymentMethod, String? notes) async {
    try {
      final sale = Sale(
        id: id,
        invoiceNumber: '',
        saleDate: DateTime.now(),
        customerId: 0,
        sellerId: 0,
        deliveryType: '',
        status: '',
        totalAmount: 0,
        paidAmount: 0,
        paymentStatus: '',
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final response = await _apiService.put(
        '${AppConfig.salesEndpoint}/$id/payment',
        data: sale.toUpdatePaymentJson(paidAmount),
      );
      
      final updatedSale = Sale.fromJson(response['sale']);
      
      // Update state with updated sale
      state = AsyncValue.data(
        state.value?.map((s) => s.id == id ? updatedSale : s).toList() ?? [],
      );
      
      return updatedSale;
    } catch (e) {
      rethrow;
    }
  }
}
