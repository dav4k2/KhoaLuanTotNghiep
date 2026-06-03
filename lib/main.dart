// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khoa_luan_tot_nghiep/widgets/homePage/HomePage.dart';
import 'package:khoa_luan_tot_nghiep/widgets/homePage/SplashScreen.dart';

import 'widgets/introduce/Introduce.dart';
import 'widgets/login/Login.dart';
import 'widgets/signUp/SignUp.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khóa Luận Tốt Nghiệp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF266E35),
        useMaterial3: true,
      ),
      initialRoute: '/',   // ← luôn bắt đầu từ Splash
      routes: {
        '/':          (_) => const SplashScreen(), // ← kiểm tra token ở đây
        '/introduce': (_) => const Introduce(),
        '/login':     (_) => const Login(),
        '/signup':    (_) => const Signup(),
        '/home':      (_) => const Homepage(),
      },
    );
  }
}