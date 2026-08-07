import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final nunito = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forest,
        onPrimary: AppColors.cream,
        secondary: AppColors.gold,
        onSecondary: AppColors.forest,
        surface: AppColors.creamCard,
        onSurface: AppColors.ink,
        outline: AppColors.border,
        error: AppColors.danger,
      ),
      textTheme: nunito.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.cream,
        elevation: 0,
        titleTextStyle: nunito.titleLarge?.copyWith(
          color: AppColors.cream,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.cream,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.25),
        labelTextStyle: WidgetStatePropertyAll(
          nunito.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
