import 'package:flutter/material.dart';

/// GemScan's visual identity — warm indigo/lavender, inspired by consumer
/// health-app design language (soft cards, pill-shaped buttons, pastel
/// accent circles), kept a shade more clinical since this tool carries
/// real medical warnings, not just reminders.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF5B52E0);
  static const primaryDark = Color(0xFF4239C4);
  static const primaryLight = Color(0xFFEDEBFF);
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63F5), Color(0xFF4239C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const background = Color(0xFFF7F7FC);
  static const surface = Colors.white;

  static const textPrimary = Color(0xFF1F1B4D);
  static const textSecondary = Color(0xFF8A87A6);

  static const danger = Color(0xFFFF6B6B);
  static const dangerBg = Color(0xFFFFEDED);
  static const warning = Color(0xFFFFB84D);
  static const warningBg = Color(0xFFFFF6E8);
  static const info = Color(0xFF4FA8E0);
  static const infoBg = Color(0xFFEAF6FF);
  static const success = Color(0xFF4CC38A);
  static const successBg = Color(0xFFE8F9F1);

  static const accentPeach = Color(0xFFFFD9D2);
  static const accentBlue = Color(0xFFD8E8FF);
  static const accentMint = Color(0xFFD7F5E9);
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2,
        ),
        titleLarge: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 15, color: AppColors.textPrimary, height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 13, color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.primaryLight,
        labelStyle: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}