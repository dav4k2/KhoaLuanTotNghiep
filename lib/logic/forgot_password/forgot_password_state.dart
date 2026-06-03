// lib/logic/forgot_password/forgot_password_state.dart

enum ForgotPasswordStep { enterEmail, enterOTP, enterNewPassword, success }
enum ForgotPasswordStatus { idle, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final ForgotPasswordStatus status;
  final String? errorMessage;
  final String? email; // Lưu email qua các bước

  const ForgotPasswordState({
    this.step    = ForgotPasswordStep.enterEmail,
    this.status  = ForgotPasswordStatus.idle,
    this.errorMessage,
    this.email,
  });

  bool get isLoading => status == ForgotPasswordStatus.loading;
  bool get isError   => status == ForgotPasswordStatus.error;
  bool get isSuccess => status == ForgotPasswordStatus.success;

  ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    ForgotPasswordStatus? status,
    String? errorMessage,
    String? email,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      status: status ?? this.status,
      errorMessage: errorMessage,
      email: email ?? this.email,
    );
  }
}