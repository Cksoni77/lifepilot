import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug: confirm SplashScreen build
    // ignore: avoid_print
    debugPrint('SplashScreen: build');
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // AI Icon Container
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x26FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),

                // larger gap to avoid notch overlap
                SizedBox(height: 24),

                // App Name
                Text(
                  'LifePilot',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.48,
                  ),
                ),

                // gap between title and subtitle
                SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your day, gently organized',
                  style: GoogleFonts.manrope(
                    color: Color(0xBFFFFFFF),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}