// lib/logic/auth/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'auth_model.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial();

  late final AuthRepositoryBase _repository =
  ref.read(authRepositoryProvider);

  // ── Đăng ký — thêm fullName ───────────────────────────────

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      await _repository.signUp(
        SignUpRequest(fullName: fullName, email: email, password: password),
      );
      state = AuthState.signUpSuccess(); // ← THAY ĐỔI: không có token
    } on ApiException catch (e) {
      state = AuthState.failure(e.userFriendlyMessage);
    } catch (_) {
      state = AuthState.failure('Có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  // ── Đăng nhập ─────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState.success(response);
    } on ApiException catch (e) {
      state = AuthState.failure(e.userFriendlyMessage);
    } catch (_) {
      state = AuthState.failure('Có lỗi xảy ra. Vui lòng thử lại.');
    }
  }

  // ── Đăng xuất ─────────────────────────────────────────────

  Future<void> logout() async {
    await TokenStorage.clearAll();
    state = AuthState.initial();
  }

  void reset() => state = AuthState.initial();
}

// ── Providers ─────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepositoryBase>(
      (ref) => AuthRepository(),
);

final authNotifierProvider =
NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);