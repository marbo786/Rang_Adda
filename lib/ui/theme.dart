import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Minimalist Colors
  static const Color backgroundPrimary = Color(0xFF0F1115);
  static const Color backgroundSecondary = Color(0xFF171A21);
  static const Color surface = Color(0xFF1E232D);
  
  static const Color accentPrimary = Color(0xFF5B8CFF);
  static const Color accentSecondary = Color(0xFF7C5CFF);
  
  static const Color statusSuccess = Color(0xFF32D583);
  static const Color statusWarning = Color(0xFFF5B942);
  static const Color statusError = Color(0xFFF04438);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA7B0BE);
  static const Color textDisabled = Color(0xFF6C7380);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundPrimary,
    primaryColor: accentPrimary,
    colorScheme: const ColorScheme.dark(
      primary: accentPrimary,
      secondary: accentSecondary,
      surface: surface,
      background: backgroundPrimary,
      error: statusError,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textSecondary,
      displayColor: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundSecondary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  );
}
