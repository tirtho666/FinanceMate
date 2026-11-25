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

  /// Tokens taken from the authentication design reference
  /// (`assets/login_ui.png`). Kept separate from the app-wide palette so the
  /// auth screens can match the reference without restyling every other screen.
  static const Color authNavy = Color(0xFF0B2C4D);
  static const Color authWaveBack = Color(0xFF8EC5EA);
  static const Color authWaveFront = Color(0xFF1E438A);
  static const Color authLogoGreen = Color(0xFF2E9E5B);
  static const Color authSubtitle = Color(0xFF64748B);
  static const Color authFieldFill = Color(0xFFF8FAFC);
  static const Color authFieldBorder = Color(0xFFCBD5E1);
}
