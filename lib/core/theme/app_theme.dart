import 'package:flutter/material.dart';

/// App theme — dark palette with gradient for a premium look.
class AppTheme {
  AppTheme._();

  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color backgroundCard = Color(0xFF141929);
  static const Color gradientStart = Color(0xFF0A0E1A);
  static const Color gradientMid = Color(0xFF0D1530);
  static const Color gradientEnd = Color(0xFF1A1040);
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9B94FF);
  static const Color accent = Color(0xFF00D4FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A9BB5);
  static const Color divider = Color(0xFF1E2D45);

  static const LinearGradient loginGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
    stops: [0.0, 0.5, 1.0],
  );

  /// Dark [ThemeData] passed to [MaterialApp.theme].
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: backgroundCard,
          onPrimary: surfaceWhite,
          onSecondary: surfaceWhite,
          onSurface: textPrimary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: backgroundCard,
          contentTextStyle: TextStyle(color: textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
