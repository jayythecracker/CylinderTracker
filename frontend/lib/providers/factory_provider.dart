import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/factory.dart';
import '../services/api_service.dart';

// State class for factory list
class FactoriesState {
  final bool isLoading;
  final List<Factory> factories;
  final String? errorMessage;

  const FactoriesState({
    this.isLoading = false,
    this.factories = const [],
    this.errorMessage,
  });

  // Copy with method for immutability
  FactoriesState copyWith({
    bool? isLoading,
    List<Factory>? factories,
    String? errorMessage,
  }) {
    return FactoriesState(
      isLoading: isLoading ?? this.isLoading,
      factories: factories ?? this.factories,
      errorMessage: errorMessage,
    );
  }
}

// Factory notifier to handle factory list state
class FactoryNotifier extends StateNotifier<FactoriesState> {
  final ApiService _apiService;

  FactoryNotifier(this._apiService) : super(const FactoriesState());

  // Get all factories
  Future<void> getFactories({String? search}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'factories',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final List<Factory> factories = (response['factories'] as List)
          .map((json) => Factory.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        factories: factories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load factories: ${e.toString()}',
      );
    }
  }

  // Get factory by ID
  Future<Map<String, dynamic>> getFactoryById(int id) async {
    try {
      final response = await _apiService.get('factories/$id');
      return {
        'factory': Factory.fromJson(response['factory']),
        'cylinderCount': response['cylinderCount'],
      };
    } catch (e) {
      throw Exception('Failed to load factory: ${e.toString()}');
    }
  }

  // Create factory
  Future<Factory> createFactory(Map<String, dynamic> factoryData) async {
    try {
      final response = await _apiService.post('factories', data: factoryData);
      final factory = Factory.fromJson(response['factory']);
      
      // Update state with new factory
      state = state.copyWith(
        factories: [...state.factories, factory],
      );
      
      return factory;
    } catch (e) {
      throw Exception('Failed to create factory: ${e.toString()}');
    }
  }

  // Update factory
  Future<Factory> updateFactory(int id, Map<String, dynamic> factoryData) async {
    try {
      final response = await _apiService.put('factories/$id', data: factoryData);
      final updatedFactory = Factory.fromJson(response['factory']);
      
      // Update state with updated factory
      final index = state.factories.indexWhere((f) => f.id == id);
      if (index >= 0) {
        final updatedFactories = [...state.factories];
        updatedFactories[index] = updatedFactory;
        state = state.copyWith(factories: updatedFactories);
      }
      
      return updatedFactory;
    } catch (e) {
      throw Exception('Failed to update factory: ${e.toString()}');
    }
  }

  // Delete factory
  Future<void> deleteFactory(int id) async {
    try {
      await _apiService.delete('factories/$id');
      
      // Update state by removing deleted factory
      final updatedFactories = state.factories.where((f) => f.id != id).toList();
      state = state.copyWith(factories: updatedFactories);
    } catch (e) {
      throw Exception('Failed to delete factory: ${e.toString()}');
    }
  }

  // Get factory statistics
  Future<Map<String, dynamic>> getFactoryStats(int id) async {
    try {
      final response = await _apiService.get('factories/$id/stats');
      return response;
    } catch (e) {
      throw Exception('Failed to load factory statistics: ${e.toString()}');
    }
  }
}

// Factory providers
final factoryProvider = StateNotifierProvider<FactoryNotifier, FactoriesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FactoryNotifier(apiService);
});

// Provider for current factory (for details page)
final currentFactoryProvider = StateProvider<Factory?>((ref) => null);
