import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_button_styles.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_text_theme.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.primary,
      onPrimary: AppPalette.onPrimary,
      primaryContainer: Color(0xFFD6E4EF),
      onPrimaryContainer: AppPalette.primary,
      secondary: AppPalette.income,
      onSecondary: AppPalette.onPrimary,
      secondaryContainer: Color(0xFFD4F0ED),
      onSecondaryContainer: Color(0xFF0B3C61),
      tertiary: AppPalette.expense,
      onTertiary: AppPalette.onPrimary,
      tertiaryContainer: Color(0xFFF8D9D9),
      onTertiaryContainer: Color(0xFF5C1D1D),
      error: AppPalette.expense,
      onError: AppPalette.onPrimary,
      errorContainer: Color(0xFFF8D9D9),
      onErrorContainer: Color(0xFF5C1D1D),
      surface: AppPalette.background,
      onSurface: AppPalette.onBackground,
      onSurfaceVariant: Color(0xFF4A5B68),
      outline: Color(0xFFB7C2CC),
      outlineVariant: Color(0xFFD9E0E6),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppPalette.primary,
      onInverseSurface: AppPalette.background,
      inversePrimary: Color(0xFF8BB8D9),
      surfaceTint: AppPalette.primary,
    );

    final textTheme = AppTextTheme.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: AppPalette.onPrimary,
        displayColor: AppPalette.onPrimary,
      ),
      scaffoldBackgroundColor: AppPalette.background,
      canvasColor: AppPalette.background,
      dividerColor: colorScheme.outlineVariant,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppPalette.onPrimary,
        ),
        iconTheme: const IconThemeData(color: AppPalette.onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.primaryElevated,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.primaryFilled,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.primaryOutlined,
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppButtonStyles.primaryText,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.onPrimary,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppPalette.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppPalette.expense),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppPalette.expense, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.onPrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppPalette.onPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
