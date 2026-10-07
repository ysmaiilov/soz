import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF2E7D32);
  static const secondary = Color(0xFF66BB6A);
  static const accent = Color(0xFFA5D6A7);
  static const background = Color(0xFFF7F8FA);
  static const card = Colors.white;
  static const correct = Color(0xFFFFD54F);
  static const wrong = Color(0xFFEF5350);
  static const success = Color(0xFF43A047);
  static const textPrimary = Color(0xFF1C1C1C);
  static const textSecondary = Color(0xFF666666);
  static const border = Color(0xFFE6E6E6);
}

class AppSpacing {
  const AppSpacing._();

  static const horizontal = 20.0;
  static const vertical = 12.0;
  static const cardPadding = 16.0;
  static const radius = 16.0;
  static const dialogRadius = 24.0;
  static const buttonHeight = 56.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.card,
      error: AppColors.wrong,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    );
    final roundedRectangle = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: roundedRectangle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: roundedRectangle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: roundedRectangle,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.dialogRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      textTheme: Typography.material2021().black.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
