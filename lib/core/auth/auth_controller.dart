import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qaari_sl_staff/core/constants/app_constants.dart';
import 'package:qaari_sl_staff/core/data/staff_repository.dart';
import 'package:qaari_sl_staff/core/models/staff_user.dart';
import 'package:qaari_sl_staff/core/network/api_client.dart';

enum AuthStatus { unknown, guest, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  final AuthStatus status;
  final StaffUser? user;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    StaffUser? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.watch(staffRepositoryProvider));
  ref.listen<int>(sessionInvalidatedProvider, (previous, next) {
    if (previous != null && previous != next) {
      controller.handleUnauthorized();
    }
  });
  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    restoreSession();
  }

  final StaffRepository _repo;

  Future<void> restoreSession() async {
    try {
      final token = await _repo.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.guest);
        return;
      }
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _repo.clearLocalSession();
      state = const AuthState(status: AuthStatus.guest);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _repo.login(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.guest,
        clearUser: true,
        error: _friendly(error),
      );
      return false;
    }
  }

  String _friendly(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.unknown) {
        return 'Cannot reach API at ${AppConstants.apiBaseUrl}. '
            'Rebuild with --dart-define=API_BASE_URL=http://YOUR_PC_IP:8000 '
            '(USB tether: Ethernet/Samsung NDIS IP, not 10.0.2.2).';
      }
      final status = error.response?.statusCode;
      if (status == 422 || status == 401) {
        return 'Could not sign in. Check email/password (staff accounts only).';
      }
      if (status != null) {
        return 'Sign in failed (HTTP $status).';
      }
    }
    return 'Could not sign in. Use a staff account (production / admin).';
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.guest);
  }

  void handleUnauthorized() {
    state = const AuthState(status: AuthStatus.guest);
  }
}
