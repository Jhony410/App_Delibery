import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin design system colours (Stripe / Linear / Vercel inspired).
class AdminColors {
  // Surfaces
  static const bg = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFF0B0C0F);
  static const sidebarText = Color(0xFFA1A1AA);
  static const sidebarHover = Color(0xFF1C1D21);

  // Text
  static const text = Color(0xFF0B0C0F);
  static const textMuted = Color(0xFF52525B);
  static const textSubtle = Color(0xFFA1A1AA);

  // Borders
  static const border = Color(0xFFE4E4E7);
  static const borderStrong = Color(0xFFD4D4D8);

  // Brand
  static const primary = Color(0xFFFF6B35);
  static const primaryTint = Color(0xFFFFF1EA);

  // Status
  static const green = Color(0xFF16A34A);
  static const greenTint = Color(0xFFDCFCE7);
  static const amber = Color(0xFFD97706);
  static const amberTint = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redTint = Color(0xFFFEE2E2);
  static const blue = Color(0xFF2563EB);
  static const blueTint = Color(0xFFDBEAFE);
  static const purple = Color(0xFF7C3AED);
  static const purpleTint = Color(0xFFEDE9FE);
  static const grayTint = Color(0xFFF4F4F5);

  // Avatar gradients (used by Avatar widget)
  static const Map<String, List<Color>> avatarGradients = {
    'coral': [Color(0xFFFF6B35), Color(0xFFFFAA80)],
    'blue': [Color(0xFF2563EB), Color(0xFF6FA8FF)],
    'green': [Color(0xFF16A34A), Color(0xFF5EE599)],
    'purple': [Color(0xFF7C3AED), Color(0xFFB89DFF)],
    'amber': [Color(0xFFD97706), Color(0xFFFFB35E)],
  };
}

ThemeData buildAdminTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AdminColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AdminColors.primary,
      onPrimary: Colors.white,
      secondary: AdminColors.text,
      onSecondary: Colors.white,
      surface: AdminColors.surface,
      onSurface: AdminColors.text,
      error: AdminColors.red,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AdminColors.text,
      displayColor: AdminColors.text,
    ),
    dividerColor: AdminColors.border,
    cardColor: AdminColors.surface,
  );
}
