import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourierColors {
  static const bg = Color(0xFF0E0F12);
  static const surface = Color(0xFF181A20);
  static const surface2 = Color(0xFF23262E);
  static const border = Color(0xFF2A2D36);
  static const borderSoft = Color(0xFF1F2128);
  static const text = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFA6A9B3);
  static const textSubtle = Color(0xFF6E7280);
  static const primary = Color(0xFFFF6B35);
  static const primaryDark = Color(0xFFE8572A);
  static const primaryTint = Color(0xFF3A1E14);
  static const online = Color(0xFF22D38A);
  static const onlineTint = Color(0xFF0F2A1E);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5252);
  static const cash = Color(0xFF22D38A);
  static const onOnline = Color(0xFF06241A);
  static const dangerTint = Color(0xFF3A1A1E);
}

ThemeData buildCourierTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: CourierColors.text,
    displayColor: CourierColors.text,
  );

  return base.copyWith(
    scaffoldBackgroundColor: CourierColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: CourierColors.primary,
      onPrimary: Colors.white,
      secondary: CourierColors.online,
      onSecondary: CourierColors.onOnline,
      surface: CourierColors.surface,
      onSurface: CourierColors.text,
      error: CourierColors.danger,
      onError: Colors.white,
    ),
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: CourierColors.bg,
      foregroundColor: CourierColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: CourierColors.text),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}
