import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Custom colors that are not fully expressed by [ColorScheme].
/// Read via `Theme.of(context).extension<AppColors>()` or `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.primary,
    required this.income,
    required this.expense,
    required this.onPrimary,
    required this.onBackground,
  });

  final Color background;
  final Color primary;
  final Color income;
  final Color expense;
  final Color onPrimary;
  final Color onBackground;

  static const AppColors light = AppColors(
    background: AppPalette.background,
    primary: AppPalette.primary,
    income: AppPalette.income,
    expense: AppPalette.expense,
    onPrimary: AppPalette.onPrimary,
    onBackground: AppPalette.onBackground,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? primary,
    Color? income,
    Color? expense,
    Color? onPrimary,
    Color? onBackground,
  }) {
    return AppColors(
      background: background ?? this.background,
      primary: primary ?? this.primary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      onPrimary: onPrimary ?? this.onPrimary,
      onBackground: onBackground ?? this.onBackground,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
    );
  }
}

extension FinanceMateThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  AppColors get appColors => theme.extension<AppColors>()!;
}
