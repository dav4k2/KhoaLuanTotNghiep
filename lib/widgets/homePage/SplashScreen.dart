// lib/widgets/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/screen/app/app_startup_notifier.dart';


class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primaryGreen = Color(0xFF266E35);

    ref.listen<AsyncValue<StartupStatus>>(appStartupProvider, (_, next) {
      next.whenData((status) {
        if (status == StartupStatus.authenticated) {
          // Token hợp lệ → vào thẳng Home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Chưa đăng nhập → qua màn hình Introduce trước
          Navigator.pushReplacementNamed(context, '/introduce');
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Icon_preview_rev_1.png',
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: primaryGreen,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}