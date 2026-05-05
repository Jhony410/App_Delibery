import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFFF6B35);
  static const primaryDark = Color(0xFFE8572A);
  static const primaryTint = Color(0xFFFFF1EB);
  static const secondary = Color(0xFF06A77D);
  static const secondaryTint = Color(0xFFE3F6F0);
  static const appText = Color(0xFF1A1A1F);
  static const textMuted = Color(0xFF6B6B73);
  static const textSubtle = Color(0xFF9A9AA3);
  static const border = Color(0xFFECECEF);
  static const bg = Color(0xFFF7F7F5);
  static const bgAlt = Color(0xFFF0EFEB);
  static const star = Color(0xFFF5B301);
  static const danger = Color(0xFFE23D3D);
}

ThemeData buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.appText,
      displayColor: AppColors.appText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
