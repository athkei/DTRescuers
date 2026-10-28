import 'package:flutter/material.dart';

class AppColors {
  // Web app color palette
  static const brandy = Color(0xFF8F250C); // Deep reddish-brown - primary
  static const tuscanSun = Color(0xFFF2C14E); // Warm golden yellow - accent
  static const jetBlack = Color(0xFF2A2D34); // Dark charcoal - text
  static const brightSnow = Color(0xFFFAF8F5); // Off-white cream - background
  static const blueSlate = Color(0xFF5C6B7A); // Muted blue-gray - secondary

  // Semantic color aliases for easier use
  static const primary = brandy;
  static const primaryDark =
      Color(0xFF6B1B09); // Darker shade for pressed states
  static const accent = tuscanSun;
  static const ink = jetBlack;
  static const muted = blueSlate;
  static const surface = brightSnow;
  static const success = Color(0xFF2E7D32); // Green for resolved/completed
  static const warning = tuscanSun; // Yellow for warnings
  static const error = brandy; // Red-brown for errors
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandy,
    primary: AppColors.brandy,
    secondary: AppColors.tuscanSun,
    surface: AppColors.brightSnow,
    onSurface: AppColors.jetBlack,
    brightness: Brightness.light,
  );

  OutlineInputBorder border([Color? c]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c ?? const Color(0xFFD5D9E0)),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.brightSnow,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.jetBlack,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border(),
      enabledBorder: border(),
      focusedBorder: border(AppColors.brandy),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandy,
        side: const BorderSide(color: AppColors.brandy),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.brightSnow,
      selectedColor: AppColors.brandy.withValues(alpha: 0.12),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
