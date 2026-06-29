import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1008),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  fontSize: 52,
                  color: const Color(0xFFF5ECD7),
                  height: 1,
                ),
                children: const [
                  TextSpan(text: 'Rotina'),
                  TextSpan(text: '.', style: TextStyle(color: Color(0xFFC4A882))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sua vida em um app.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Color(0xFF8A6A4A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
