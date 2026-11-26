import 'package:flutter/material.dart';

/// FasalMitra theme, colors sampled from the Figma design (complition.pdf).
/// Font: the PDF has no readable font name. Check it in Figma, add it to
/// pubspec.yaml (or google_fonts), then set [fontFamily] below.
abstract final class AppColors {
  static const background = Color(0xFFB8D1BB); // page background
  static const surface = Color(0xFFDBE8DD); // cards, inputs
  static const primary = Color(0xFF3F8347); // buttons, active icons
  static const border = Color(0xFF4A4E4A); // input outline
  static const mutedText = Color(0xFF6F736F); // hints, helper text
  static const circle = Color(0x2B3F8347); // decorative corner circle
}

abstract final class AppTheme {
  static const String? fontFamily = null; // e.g. 'Inter' once added

  static ThemeData light() {
    final radius = BorderRadius.circular(16);
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.mutedText),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
      ),
    );
  }
}
