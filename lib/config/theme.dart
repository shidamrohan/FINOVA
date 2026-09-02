import 'package:flutter/material.dart';

class AppTheme {
  // Colors matching the HTML reference
  static const Color primary = Color(0xFF13EC5B); // Bright green!
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102216); // Dark green-tinted
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1C2E22); // Lighter dark green
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textMutedDark = Color(0xFF9DB9A6);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF3B82F6);

  // Spacing
  static const double spacing = 8.0;
  static const double radiusCard = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusBottomSheet = 20.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: surfaceLight,
        error: danger,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: backgroundDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: surfaceLight,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surfaceDark,
        error: danger,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: backgroundDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: textMutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: surfaceDark,
        selectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
        bodySmall: TextStyle(color: textMutedDark),
        titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        filled: true,
        fillColor: surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
