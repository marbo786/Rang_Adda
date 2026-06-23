import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Futuristic Dark-Neon Colors
  static const Color backgroundPrimary = Color(0xFF060A0F);
  static const Color backgroundSecondary = Color(0xFF0B1018);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1A2332);

  static const Color accentPrimary = Color(0xFF00FF88);
  static const Color accentSecondary = Color(0xFF00CCFF);
  static const Color accentTertiary = Color(0xFF7B61FF);

  static const Color statusSuccess = Color(0xFF00FF88);
  static const Color statusWarning = Color(0xFFFFB800);
  static const Color statusError = Color(0xFFFF3D5A);

  static const Color textPrimary = Color(0xFFF0F6FF);
  static const Color textSecondary = Color(0xFF8BA3BE);
  static const Color textDisabled = Color(0xFF3D5166);

  static Color get neonGlow => const Color(0xFF00FF88).withValues(alpha: 0.35);
  static Color get cyanGlow => const Color(0xFF00CCFF).withValues(alpha: 0.30);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundPrimary,
    primaryColor: accentPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      onPrimary: backgroundPrimary,
      secondary: accentSecondary,
      onSecondary: backgroundPrimary,
      tertiary: accentTertiary,
      onTertiary: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceElevated,
      error: statusError,
      onError: textPrimary,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
      decorationColor: accentPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPrimary,
        foregroundColor: backgroundPrimary,
        shadowColor: Colors.transparent,
      ),
    ),
  );
}
