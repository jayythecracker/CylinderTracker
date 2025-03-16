import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filling_line.dart';
import '../services/api_service.dart';

// State class for filling lines list
class FillingLinesState {
  final bool isLoading;
  final List<FillingLine> fillingLines;
  final String? errorMessage;
  
  const FillingLinesState({
    this.isLoading = false,
    this.fillingLines = const [],
    this.errorMessage,
  });

  // Copy with method for immutability
  FillingLinesState copyWith({
    bool? isLoading,
    List<FillingLine>? fillingLines,
    String? errorMessage,
  }) {
    return FillingLinesState(
      isLoading: isLoading ?? this.isLoading,
      fillingLines: fillingLines ?? this.fillingLines,
      errorMessage: errorMessage,
    );
  }
}

// State class for filling sessions list
class FillingSessionsState {
  final bool isLoading;
  final List<FillingSession> sessions;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  
  const FillingSessionsState({
    this.isLoading = false,
    this.sessions = const [],
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  // Copy with method for immutability
  FillingSessionsState copyWith({
    bool? isLoading,
    List<FillingSession>? sessions,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
  }) {
    return FillingSessionsState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// Filling line notifier to handle filling lines state
class FillingLineNotifier extends StateNotifier<FillingLinesState> {
  final ApiService _apiService;

  FillingLineNotifier(this._apiService) : super(const FillingLinesState());

  // Get all filling lines
  Future<void> getFillingLines() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get('filling/lines');

      final List<FillingLine> fillingLines = (response['fillingLines'] as List)
          .map((json) => FillingLine.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        fillingLines: fillingLines,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load filling lines: ${e.toString()}',
      );
    }
  }

  // Get filling line by ID
  Future<Map<String, dynamic>> getFillingLineById(int id) async {
    try {
      final response = await _apiService.get('filling/lines/$id');
      return {
        'fillingLine': FillingLine.fromJson(response['fillingLine']),
        'activeSession': response['activeSession'] != null 
            ? FillingSession.fromJson(response['activeSession']) 
            : null,
      };
    } catch (e) {
      throw Exception('Failed to load filling line: ${e.toString()}');
    }
  }

  // Create filling line
  Future<FillingLine> createFillingLine(Map<String, dynamic> lineData) async {
    try {
      final response = await _apiService.post('filling/lines', data: lineData);
      final fillingLine = FillingLine.fromJson(response['fillingLine']);
      
      // Update state with new filling line
      state = state.copyWith(
        fillingLines: [...state.fillingLines, fillingLine],
      );
      
      return fillingLine;
    } catch (e) {
      throw Exception('Failed to create filling line: ${e.toString()}');
    }
  }

  // Update filling line
  Future<FillingLine> updateFillingLine(int id, Map<String, dynamic> lineData) async {
    try {
      final response = await _apiService.put('filling/lines/$id', data: lineData);
      final updatedLine = FillingLine.fromJson(response['fillingLine']);
      
      // Update state with updated filling line
      final index = state.fillingLines.indexWhere((f) => f.id == id);
      if (index >= 0) {
        final updatedLines = [...state.fillingLines];
        updatedLines[index] = updatedLine;
        state = state.copyWith(fillingLines: updatedLines);
      }
      
      return updatedLine;
    } catch (e) {
      throw Exception('Failed to update filling line: ${e.toString()}');
    }
  }
}

// Filling session notifier to handle filling sessions state
class FillingSessionNotifier extends StateNotifier<FillingSessionsState> {
  final ApiService _apiService;

  FillingSessionNotifier(this._apiService) : super(const FillingSessionsState());

  // Get filling sessions list
  Future<void> getFillingSessionsList({
    int page = 1,
    int limit = 20,
    int? fillingLineId,
    String? status,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.get(
        'filling/sessions',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (fillingLineId != null) 'fillingLineId': fillingLineId.toString(),
          if (status != null) 'status': status,
        },
      );

      final List<FillingSession> sessions = (response['sessions'] as List)
          .map((json) => FillingSession.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        sessions: sessions,
        totalCount: response['totalCount'] ?? 0,
        currentPage: response['currentPage'] ?? 1,
        totalPages: response['totalPages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load filling sessions: ${e.toString()}',
      );
    }
  }

  // Get session details
  Future<FillingSession> getSessionDetails(int id) async {
    try {
      final response = await _apiService.get('filling/sessions/$id');
      return FillingSession.fromJson(response['session']);
    } catch (e) {
      throw Exception('Failed to load session details: ${e.toString()}');
    }
  }

  // Start filling session
  Future<FillingSession> startFillingSession(int fillingLineId) async {
    try {
      final response = await _apiService.post(
        'filling/sessions',
        data: {
          'fillingLineId': fillingLineId,
        },
      );
      
      return FillingSession.fromJson(response['fillingSession']);
    } catch (e) {
      throw Exception('Failed to start filling session: ${e.toString()}');
    }
  }

  // Add cylinder to filling session
  Future<FillingSessionCylinder> addCylinderToSession(
    int sessionId,
    int cylinderId,
    {double? pressureBeforeFilling}
  ) async {
    try {
      final response = await _apiService.post(
        'filling/sessions/cylinders',
        data: {
          'sessionId': sessionId,
          'cylinderId': cylinderId,
          if (pressureBeforeFilling != null) 'pressureBeforeFilling': pressureBeforeFilling,
        },
      );
      
      return FillingSessionCylinder.fromJson(response['sessionCylinder']);
    } catch (e) {
      throw Exception('Failed to add cylinder to session: ${e.toString()}');
    }
  }

  // Update cylinder filling status
  Future<FillingSessionCylinder> updateCylinderFilling(
    int id,
    String status,
    {double? pressureAfterFilling, String? notes}
  ) async {
    try {
      final response = await _apiService.patch(
        'filling/sessions/cylinders/$id',
        data: {
          'status': status,
          if (pressureAfterFilling != null) 'pressureAfterFilling': pressureAfterFilling,
          if (notes != null) 'notes': notes,
        },
      );
      
      return FillingSessionCylinder.fromJson(response['sessionCylinder']);
    } catch (e) {
      throw Exception('Failed to update cylinder filling status: ${e.toString()}');
    }
  }

  // End filling session
  Future<FillingSession> endFillingSession(int id, {String? notes}) async {
    try {
      final response = await _apiService.patch(
        'filling/sessions/$id/end',
        data: {
          if (notes != null) 'notes': notes,
        },
      );
      
      return FillingSession.fromJson(response['session']);
    } catch (e) {
      throw Exception('Failed to end filling session: ${e.toString()}');
    }
  }
}

// Filling providers
final fillingLineProvider = StateNotifierProvider<FillingLineNotifier, FillingLinesState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FillingLineNotifier(apiService);
});

final fillingSessionProvider = StateNotifierProvider<FillingSessionNotifier, FillingSessionsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FillingSessionNotifier(apiService);
});

// Provider for current filling session (for session details page)
final currentFillingSessionProvider = StateProvider<FillingSession?>((ref) => null);
