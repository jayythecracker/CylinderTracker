import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Auth state class to represent different authentication states
abstract class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthStateAuthenticated({
    required this.user,
    required this.token,
  });
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;

  const AuthStateError(this.message);
}

// Auth notifier to handle authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthStateInitial()) {
    // Check if user is already logged in
    checkAuth();
  }

  // Check authentication status
  Future<void> checkAuth() async {
    try {
      final token = await _authService.getToken();
      
      if (token != null) {
        // Token exists, get current user
        state = const AuthStateLoading();
        final user = await _authService.getCurrentUser();
        state = AuthStateAuthenticated(user: user, token: token);
      } else {
        state = const AuthStateUnauthenticated();
      }
    } catch (e) {
      // Error or invalid token
      await _authService.logout();
      state = AuthStateError(e.toString());
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    try {
      state = const AuthStateLoading();
      final loginResult = await _authService.login(email, password);
      state = AuthStateAuthenticated(
        user: loginResult.user,
        token: loginResult.token,
      );
    } catch (e) {
      state = AuthStateError(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AuthStateUnauthenticated();
    } catch (e) {
      state = AuthStateError(e.toString());
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (state is! AuthStateAuthenticated) {
        throw Exception('Not authenticated');
      }
      
      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(storageService);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Import the storage service provider
import '../services/storage_service.dart';
