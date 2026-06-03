// lib/widgets/login/Login.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khoa_luan_tot_nghiep/widgets/signUp/SignUp.dart';

import '../../logic/auth/auth_notifier.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/validate/Validate.dart';
import 'ForgotPassword.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  bool _isObscure = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _onStateChanged(AuthState state) {
    if (state.isSuccess) {
      ref.read(authNotifierProvider.notifier).reset();
      Navigator.pushReplacementNamed(context, '/home');
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

  // ── Mở màn hình Đăng ký ──────────────────────────────────
  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Signup()),
    ).then((_) {
      // ✅ Khi quay về từ SignUp (dù thành công hay bấm back)
      // form tự động clear để user đăng nhập mới
      _emailController.clear();
      _passwordController.clear();
      // Reset form validation
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider,
            (_, next) => _onStateChanged(next));

    final isLoading   = ref.watch(authNotifierProvider).isLoading;
    final screenWidth = MediaQuery.of(context).size.width;
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
                const SizedBox(width: double.infinity),
                const SizedBox(height: 30),

                Image.asset(
                  'assets/Icon_preview_rev_1.png',
                  width: screenWidth * 0.45,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // ── Segmented control Đăng nhập / Đăng ký ────
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color:        const Color(0xFF81C784).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      // Tab Đăng nhập (active)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color:        primaryGreen,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize:   16,
                            ),
                          ),
                        ),
                      ),
                      // Tab Đăng ký → điều hướng sang SignUp
                      Expanded(
                        child: GestureDetector(
                          onTap: isLoading ? null : _goToSignUp,
                          child: Container(
                            decoration: BoxDecoration(
                              color:        Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Đăng ký',
                              style: TextStyle(
                                color:      primaryGreen.withOpacity(0.6),
                                fontWeight: FontWeight.normal,
                                fontSize:   16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Email
                TextFormField(
                  controller:   _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled:      !isLoading,
                  decoration:   InputDecoration(
                    hintText:  'Email',
                    hintStyle: const TextStyle(color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: primaryGreen, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  validator: AppValidators.validateEmail,
                ),

                const SizedBox(height: 20),

                // Mật khẩu
                TextFormField(
                  controller:  _passwordController,
                  obscureText: _isObscure,
                  enabled:     !isLoading,
                  decoration:  InputDecoration(
                    hintText:  'Mật khẩu',
                    hintStyle: const TextStyle(color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: primaryGreen, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: primaryGreen, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(
                          _isObscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black45,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _isObscure = !_isObscure),
                      ),
                    ),
                  ),
                  validator: AppValidators.validatePassword,
                ),

                const SizedBox(height: 30),

                // Nút Đăng nhập
                SizedBox(
                  width:  double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:        primaryGreen,
                      disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width:  24,
                      height: 24,
                      child:  CircularProgressIndicator(
                        color:       Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.bold,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quên mật khẩu
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPassword()),
                  ),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color:      primaryGreen,
                      fontSize:   15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(color: Colors.black12, thickness: 1),
                const SizedBox(height: 15),

                // Chưa có tài khoản
                GestureDetector(
                  onTap: isLoading ? null : _goToSignUp,
                  child: RichText(
                    text: const TextSpan(
                      text:  'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                      children: [
                        TextSpan(
                          text:  'Đăng ký ngay',
                          style: TextStyle(
                            color:      primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
}