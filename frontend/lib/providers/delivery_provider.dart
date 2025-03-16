import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery.dart';
import '../services/api_service.dart';

class DeliveriesState {
  final List<Delivery> deliveries;
  final bool isLoading;
  final String? error;
  final DeliveryStatus? statusFilter;
  final DeliveryType? typeFilter;
  final int? customerIdFilter;

  DeliveriesState({
    this.deliveries = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.typeFilter,
    this.customerIdFilter,
  });

  DeliveriesState copyWith({
    List<Delivery>? deliveries,
    bool? isLoading,
    String? error,
    DeliveryStatus? statusFilter,
    DeliveryType? typeFilter,
    int? customerIdFilter,
  }) {
    return DeliveriesState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
      customerIdFilter: customerIdFilter,
    );
  }

  List<Delivery> get filteredDeliveries {
    return deliveries.where((delivery) {
      bool matchesStatus = statusFilter == null || delivery.status == statusFilter;
      bool matchesType = typeFilter == null || delivery.deliveryType == typeFilter;
      bool matchesCustomer = customerIdFilter == null || delivery.customerId == customerIdFilter;
      
      return matchesStatus && matchesType && matchesCustomer;
    }).toList();
  }
}

class DeliveryNotifier extends StateNotifier<DeliveriesState> {
  final ApiService _apiService;

  DeliveryNotifier(this._apiService) : super(DeliveriesState()) {
    fetchDeliveries();
  }

  Future<void> fetchDeliveries({
    String? status,
    String? deliveryType,
    int? customerId,
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deliveries = await _apiService.getDeliveries(
        status: status,
        deliveryType: deliveryType,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        deliveries: deliveries,
        isLoading: false,
        statusFilter: status != null ? _parseDeliveryStatus(status) : null,
        typeFilter: deliveryType == 'Truck' ? DeliveryType.Truck :
                   deliveryType == 'CustomerPickup' ? DeliveryType.CustomerPickup : null,
        customerIdFilter: customerId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  DeliveryStatus _parseDeliveryStatus(String status) {
    switch (status) {
      case 'InTransit':
        return DeliveryStatus.InTransit;
      case 'Delivered':
        return DeliveryStatus.Delivered;
      case 'Cancelled':
        return DeliveryStatus.Cancelled;
      case 'Pending':
      default:
        return DeliveryStatus.Pending;
    }
  }

  Future<Delivery?> getDeliveryById(int id) async {
    try {
      return await _apiService.getDeliveryById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> createDelivery(Map<String, dynamic> deliveryData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.createDelivery(deliveryData);
      await fetchDeliveries(
        status: state.statusFilter?.toString().split('.').last,
        deliveryType: state.typeFilter?.toString().split('.').last,
        customerId: state.customerIdFilter,
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

  Future<bool> completeDelivery(int id, Map<String, dynamic> deliveryData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.completeDelivery(id, deliveryData);
      await fetchDeliveries(
        status: state.statusFilter?.toString().split('.').last,
        deliveryType: state.typeFilter?.toString().split('.').last,
        customerId: state.customerIdFilter,
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

  Future<bool> cancelDelivery(int id, String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.cancelDelivery(id, reason);
      await fetchDeliveries(
        status: state.statusFilter?.toString().split('.').last,
        deliveryType: state.typeFilter?.toString().split('.').last,
        customerId: state.customerIdFilter,
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
    DeliveryStatus? statusFilter,
    DeliveryType? typeFilter,
    int? customerIdFilter,
  }) {
    state = state.copyWith(
      statusFilter: statusFilter,
      typeFilter: typeFilter,
      customerIdFilter: customerIdFilter,
    );

    fetchDeliveries(
      status: statusFilter?.toString().split('.').last,
      deliveryType: typeFilter?.toString().split('.').last,
      customerId: customerIdFilter,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      typeFilter: null,
      customerIdFilter: null,
    );
    fetchDeliveries();
  }
}

final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveriesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DeliveryNotifier(apiService);
});
