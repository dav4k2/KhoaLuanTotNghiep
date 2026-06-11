// lib/widgets/signUp/SignUp.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/auth/auth_notifier.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/validate/Validate.dart';

class Signup extends ConsumerStatefulWidget {
  const Signup({super.key});

  @override
  ConsumerState<Signup> createState() => _SignupState();
}

class _SignupState extends ConsumerState<Signup> {
  final _formKey             = GlobalKey<FormState>();
  bool _isObscure            = true;
  bool _isConfirmObscure     = true;

  final _fullNameController        = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
      fullName: _fullNameController.text.trim(),
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _onStateChanged(AuthState state) {
    if (state.isSignUpSuccess) { // ← THAY ĐỔI
      ref.read(authNotifierProvider.notifier).reset();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Đăng ký thành công! Vui lòng đăng nhập.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Color(0xFF266E35),
            behavior:        SnackBarBehavior.floating,
            duration:        Duration(seconds: 2),
          ),
        );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (state.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content:         Text(state.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior:        SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider,
            (_, next) => _onStateChanged(next));

    final isLoading    = ref.watch(authNotifierProvider).isLoading;
    final screenWidth  = MediaQuery.of(context).size.width;
    const primaryGreen = Color(0xFF266E35);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: double.infinity, height: 30),

                Image.asset(
                  'assets/Icon_preview_rev_1.png',
                  width: screenWidth * 0.45,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Segmented control
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isLoading ? null : () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color:      primaryGreen.withOpacity(0.6),
                                fontWeight: FontWeight.normal,
                                fontSize:   16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color:        primaryGreen,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:   16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Họ và tên
                TextFormField(
                  controller:           _fullNameController,
                  keyboardType:         TextInputType.name,
                  textCapitalization:   TextCapitalization.words,
                  enabled:              !isLoading,
                  decoration: _inputDecoration(
                    hint:        'Họ và tên',
                    primaryGreen: primaryGreen,
                    prefixIcon:   const Icon(Icons.person_outline,
                        color: Colors.black45),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (v.trim().length < 2) {
                      return 'Họ tên phải có ít nhất 2 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller:  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled:     !isLoading,
                  decoration:  _inputDecoration(
                    hint:         'Email/Số điện thoại',
                    primaryGreen: primaryGreen,
                  ),
                  validator: AppValidators.validateEmail,
                ),

                const SizedBox(height: 20),

                // Mật khẩu
                TextFormField(
                  controller:  _passwordController,
                  obscureText: _isObscure,
                  enabled:     !isLoading,
                  decoration:  _inputDecoration(
                    hint:         'Mật khẩu',
                    primaryGreen: primaryGreen,
                    suffixIcon:   _visibilityIcon(
                      isObscure: _isObscure,
                      onTap: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  validator: AppValidators.validatePassword,
                ),

                const SizedBox(height: 20),

                // Xác nhận mật khẩu
                TextFormField(
                  controller:  _confirmPasswordController,
                  obscureText: _isConfirmObscure,
                  enabled:     !isLoading,
                  decoration:  _inputDecoration(
                    hint:         'Xác nhận mật khẩu',
                    primaryGreen: primaryGreen,
                    suffixIcon:   _visibilityIcon(
                      isObscure: _isConfirmObscure,
                      onTap: () => setState(
                              () => _isConfirmObscure = !_isConfirmObscure),
                    ),
                  ),
                  validator: (v) => AppValidators.validateConfirmPassword(
                      v, _passwordController.text),
                ),

                const SizedBox(height: 30),

                // Nút Đăng ký
                SizedBox(
                  width:  double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:        primaryGreen,
                      disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width:  24,
                      height: 24,
                      child:  CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Text('Đăng ký',
                        style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.bold,
                            color:      Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color  primaryGreen,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText:       hint,
      hintStyle:      const TextStyle(color: Colors.black54),
      prefixIcon:     prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide(color: primaryGreen, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   BorderSide(color: primaryGreen, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide:   const BorderSide(color: Colors.red, width: 2)),
      suffixIcon: suffixIcon,
    );
  }

  Widget _visibilityIcon({
    required bool     isObscure,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IconButton(
        icon: Icon(
          isObscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.black45,
        ),
        onPressed: onTap,
      ),
    );
  }
}