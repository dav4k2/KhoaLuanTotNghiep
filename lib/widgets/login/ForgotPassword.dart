// lib/widgets/login/ForgotPassword.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/forgot_password/forgot_password_notifier.dart';
import '../../logic/forgot_password/forgot_password_state.dart';
import '../../logic/validate/Validate.dart';

class ForgotPassword extends ConsumerStatefulWidget {
  const ForgotPassword({super.key});

  @override
  ConsumerState<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends ConsumerState<ForgotPassword> {
  final _emailFormKey      = GlobalKey<FormState>();
  final _otpFormKey        = GlobalKey<FormState>();
  final _passwordFormKey   = GlobalKey<FormState>();

  final _emailController      = TextEditingController();
  final _otpController        = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscure        = true;
  bool _isConfirmObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Reset state mỗi khi màn hình được mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forgotPasswordProvider.notifier).reset();
    });
  }

  void _onStateChanged(ForgotPasswordState state) {
    if (state.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
    }
    // Bước success cuối → điều hướng về Login
    if (state.step == ForgotPasswordStep.success && state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (_, next) =>
        _onStateChanged(next));

    final state        = ref.watch(forgotPasswordProvider);
    const primaryGreen = Color(0xFF266E35);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _buildCurrentStep(state, primaryGreen),
        ),
      ),
    );
  }

  // ── Render đúng bước hiện tại ─────────────────────────────

  Widget _buildCurrentStep(ForgotPasswordState state, Color primaryGreen) {
    switch (state.step) {
      case ForgotPasswordStep.enterEmail:
        return _buildEnterEmailStep(state, primaryGreen);
      case ForgotPasswordStep.enterOTP:
        return _buildEnterOTPStep(state, primaryGreen);
      case ForgotPasswordStep.enterNewPassword:
        return _buildEnterNewPasswordStep(state, primaryGreen);
      case ForgotPasswordStep.success:
        return _buildSuccessStep(primaryGreen);
    }
  }

  // ── Bước 1: Nhập email ────────────────────────────────────

  Widget _buildEnterEmailStep(ForgotPasswordState state, Color primaryGreen) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_reset, size: 64, color: Color(0xFF266E35)),
          const SizedBox(height: 20),
          const Text(
            'Nhập email của bạn',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chúng tôi sẽ gửi mã OTP 6 số đến email của bạn.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !state.isLoading,
            decoration: _inputDecoration(
              hint: 'Email của bạn',
              primaryGreen: primaryGreen,
            ),
            validator: AppValidators.validateEmail,
          ),
          const SizedBox(height: 32),
          _buildButton(
            label: 'Gửi mã OTP',
            isLoading: state.isLoading,
            primaryGreen: primaryGreen,
            onPressed: () {
              if (_emailFormKey.currentState!.validate()) {
                ref.read(forgotPasswordProvider.notifier)
                    .sendOTP(_emailController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Bước 2: Nhập OTP ─────────────────────────────────────

  Widget _buildEnterOTPStep(ForgotPasswordState state, Color primaryGreen) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.mark_email_read_outlined,
              size: 64, color: Color(0xFF266E35)),
          const SizedBox(height: 20),
          const Text(
            'Nhập mã OTP',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã OTP đã được gửi đến\n${state.email}',
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !state.isLoading,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
            ),
            decoration: _inputDecoration(
              hint: '000000',
              primaryGreen: primaryGreen,
            ).copyWith(counterText: ''),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mã OTP';
              if (v.length != 6) return 'Mã OTP phải gồm 6 chữ số';
              return null;
            },
          ),
          const SizedBox(height: 12),
          // Gửi lại OTP
          Center(
            child: TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                ref.read(forgotPasswordProvider.notifier)
                    .sendOTP(state.email!);
                _otpController.clear();
              },
              child: const Text(
                'Gửi lại mã OTP',
                style: TextStyle(color: Color(0xFF266E35)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildButton(
            label: 'Xác nhận',
            isLoading: state.isLoading,
            primaryGreen: primaryGreen,
            onPressed: () {
              if (_otpFormKey.currentState!.validate()) {
                ref.read(forgotPasswordProvider.notifier)
                    .verifyOTP(_otpController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Bước 3: Nhập mật khẩu mới ────────────────────────────

  Widget _buildEnterNewPasswordStep(
      ForgotPasswordState state, Color primaryGreen) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFF266E35)),
          const SizedBox(height: 20),
          const Text(
            'Mật khẩu mới',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập mật khẩu mới cho tài khoản của bạn.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Mật khẩu mới
          TextFormField(
            controller: _newPasswordController,
            obscureText: _isObscure,
            enabled: !state.isLoading,
            decoration: _inputDecoration(
              hint: 'Mật khẩu mới',
              primaryGreen: primaryGreen,
              suffixIcon: _visibilityIcon(
                isObscure: _isObscure,
                onTap: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
            validator: AppValidators.validatePassword,
          ),
          const SizedBox(height: 20),
          // Xác nhận mật khẩu
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isConfirmObscure,
            enabled: !state.isLoading,
            decoration: _inputDecoration(
              hint: 'Xác nhận mật khẩu mới',
              primaryGreen: primaryGreen,
              suffixIcon: _visibilityIcon(
                isObscure: _isConfirmObscure,
                onTap: () =>
                    setState(() => _isConfirmObscure = !_isConfirmObscure),
              ),
            ),
            validator: (v) => AppValidators.validateConfirmPassword(
                v, _newPasswordController.text),
          ),
          const SizedBox(height: 32),
          _buildButton(
            label: 'Đặt lại mật khẩu',
            isLoading: state.isLoading,
            primaryGreen: primaryGreen,
            onPressed: () {
              if (_passwordFormKey.currentState!.validate()) {
                ref.read(forgotPasswordProvider.notifier).resetPassword(
                  _otpController.text.trim(),
                  _newPasswordController.text,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Bước 4: Thành công ────────────────────────────────────

  Widget _buildSuccessStep(Color primaryGreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.check_circle_outline,
              size: 80, color: primaryGreen),
          const SizedBox(height: 24),
          const Text(
            'Thành công!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mật khẩu đã được đặt lại.\nĐang chuyển về trang đăng nhập...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 15),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Color(0xFF266E35)),
        ],
      ),
    );
  }

  // ── UI Helpers ────────────────────────────────────────────

  Widget _buildButton({
    required String label,
    required bool isLoading,
    required Color primaryGreen,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: primaryGreen.withOpacity(0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        )
            : Text(
          label,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color primaryGreen,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: primaryGreen, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: primaryGreen, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _visibilityIcon({
    required bool isObscure,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.black45,
        ),
        onPressed: onTap,
      ),
    );
  }
}