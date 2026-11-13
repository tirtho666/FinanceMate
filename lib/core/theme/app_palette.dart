import 'package:flutter/material.dart';

/// Canonical FinanceMate color tokens. Prefer [BuildContext] accessors
/// (`context.appColors`) in widgets instead of using these constants directly.
abstract final class AppPalette {
  static const Color background = Color(0xFFF5F6FA);
  static const Color primary = Color(0xFF0B3C61);
  static const Color income = Color(0xFF4DB6AC);
  static const Color expense = Color(0xFFE57373);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF0B3C61);
}
