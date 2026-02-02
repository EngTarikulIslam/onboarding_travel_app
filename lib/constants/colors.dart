import 'package:flutter/material.dart';

class AppColors {
  // Gradient Colors
  static const Color gradientStart = Color(0xFF0B0024); // #0B0024
  static const Color gradientEnd = Color(0xFF082257);   // #082257

  // Purple Color
  static const Color primaryPurple = Color(0xFF5200FF); // #5200FF

  // **FIXED: Smooth Gradient with intermediate colors**
  static BoxDecoration get backgroundGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0B0024), // Dark Blue/Purple
          Color(0xFF0D0034), // Intermediate 1
          Color(0xFF0F0145), // Intermediate 2
          Color(0xFF082257), // Lighter Blue
        ],
        stops: [0.0, 0.4, 0.7, 1.0],
        tileMode: TileMode.clamp,
      ),
    );
  }

  // Alternative: Even smoother with more stops
  static BoxDecoration get smoothBackgroundGradient {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0B0024),
          const Color(0xFF0B0024).withOpacity(0.9),
          const Color(0xFF082257).withOpacity(0.7),
          const Color(0xFF082257),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  // Component Colors
  static const Color primaryColor = Colors.white;
  static const Color buttonBackground = primaryPurple; // #5200FF
  static const Color buttonText = Colors.white;
  static const Color dotActive = primaryPurple; // #5200FF
  static const Color dotInactive = Color(0x335200FF); // #5200FF with 20% opacity
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCFFFFFF); // 80% opacity
  static const Color skipButtonBg = Colors.transparent;

  static const Color cardBackground = Color(0x1AFFFFFF); // 10% opacity
  static const Color cardIconBg = Color(0x33FFFFFF); // 20% opacity
}