// lib/logic/auth/auth_state.dart

import 'auth_model.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final AuthResponse? authResponse;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.authResponse,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isSuccess => status == AuthStatus.success;
  bool get isError   => status == AuthStatus.error;

  factory AuthState.initial() => const AuthState(status: AuthStatus.idle);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.success(AuthResponse response) =>
      AuthState(status: AuthStatus.success, authResponse: response);
  factory AuthState.failure(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}