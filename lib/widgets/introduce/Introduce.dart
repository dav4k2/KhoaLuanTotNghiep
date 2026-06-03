// lib/widgets/introduce/Introduce.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Introduce extends StatefulWidget {
  const Introduce({super.key});

  @override
  State<Introduce> createState() => _IntroduceState();
}

class _IntroduceState extends State<Introduce> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              Image.asset(
                "assets/Icon_preview_rev_1.png",
                width: screenWidth * 0.60,
                fit: BoxFit.contain,
              ).animate()
                  .fade(duration: 800.ms)
                  .scale(curve: Curves.easeOutBack, duration: 800.ms),

              const SizedBox(height: 20),

              Text(
                "Trợ lý\nNông nghiệp\nThông minh",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF135029),
                  height: 1.2,
                ),
              ).animate()
                  .fade(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 16),

              Text(
                "Chăm sóc cây trồng của bạn\nmọi lúc, mọi nơi với AI.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: const Color(0xFF2E653F),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ).animate()
                  .fade(delay: 500.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Dùng named route thay vì import trực tiếp Login
                    // pushReplacement → không cho quay lại màn Introduce
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF287943),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Bắt đầu ngay",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate()
                  .fade(delay: 700.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}