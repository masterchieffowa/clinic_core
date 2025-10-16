import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ============================================================================
// Providers
// ============================================================================

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: getIt<AuthLocalDataSource>(),
  );
});

// Auth State Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// Current User Provider
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

// Is Logged In Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

// ============================================================================
// Auth State
// ============================================================================

class AuthState {
  final UserEntity? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Initial state
  factory AuthState.initial() {
    return const AuthState();
  }

  // Loading state
  factory AuthState.loading() {
    return const AuthState(isLoading: true);
  }

  // Authenticated state
  factory AuthState.authenticated(UserEntity user) {
    return AuthState(
      user: user,
      isAuthenticated: true,
      isLoading: false,
    );
  }

  // Unauthenticated state
  factory AuthState.unauthenticated() {
    return const AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
    );
  }

  // Error state
  factory AuthState.error(String message) {
    return AuthState(
      user: null,
      isAuthenticated: false,
      isLoading: false,
      errorMessage: message,
    );
  }
}

// ============================================================================
// Auth Notifier
// ============================================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthentication();
  }

  // Check if user is already logged in
  Future<void> _checkAuthentication() async {
    state = AuthState.loading();
    try {
      final bool isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        final UserEntity? user = await _authRepository.getCurrentUser();
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Failed to check authentication: $e');
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    state = AuthState.loading();
    try {
      final UserEntity? user = await _authRepository.login(username, password);
      if (user != null) {
        state = AuthState.authenticated(user);
        return true;
      } else {
        state = AuthState.error('Invalid username or password');
        return false;
      }
    } catch (e) {
      state = AuthState.error('Login failed: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.unauthenticated();
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      final bool isValid = await _authRepository.validateSession();
      if (!isValid) {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error('Session validation failed: $e');
    }
  }

  // Clear error
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}
