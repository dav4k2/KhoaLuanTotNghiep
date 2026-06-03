// lib/logic/forgot_password/forgot_password_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'forgot_password_state.dart';

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  late final ApiClient _apiClient = ApiClient();

  // ── Bước 1: Gửi OTP ──────────────────────────────────────

  Future<void> sendOTP(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);
    try {
      await _apiClient.post(
        endpoint: '/auth/forgot-password',
        body: {'email': email},
      );
      state = state.copyWith(
        status: ForgotPasswordStatus.success,
        step: ForgotPasswordStep.enterOTP,
        email: email,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.userFriendlyMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }

  // ── Bước 2: Xác nhận OTP ─────────────────────────────────

  Future<void> verifyOTP(String otpCode) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);
    try {
      await _apiClient.post(
        endpoint: '/auth/verify-otp',
        body: {'email': state.email, 'otp_code': otpCode},
      );
      state = state.copyWith(
        status: ForgotPasswordStatus.success,
        step: ForgotPasswordStep.enterNewPassword,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.userFriendlyMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }

  // ── Bước 3: Đặt lại mật khẩu ─────────────────────────────

  Future<void> resetPassword(String otpCode, String newPassword) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading);
    try {
      await _apiClient.post(
        endpoint: '/auth/reset-password',
        body: {
          'email': state.email,
          'otp_code': otpCode,
          'new_password': newPassword,
        },
      );
      state = state.copyWith(
        status: ForgotPasswordStatus.success,
        step: ForgotPasswordStep.success,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: e.userFriendlyMessage,
      );
    } catch (_) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }

  void reset() => state = const ForgotPasswordState();
}

// ── Provider ──────────────────────────────────────────────────

final forgotPasswordProvider =
NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
  ForgotPasswordNotifier.new,
);