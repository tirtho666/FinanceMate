import 'package:flutter/material.dart';

import 'app_palette.dart';

abstract final class AppButtonStyles {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 14,
  );

  static final RoundedRectangleBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static const TextStyle _label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static ButtonStyle elevated({
    Color background = AppPalette.primary,
    Color foreground = AppPalette.onPrimary,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.4),
      disabledForegroundColor: foreground.withValues(alpha: 0.7),
      padding: _padding,
      shape: _shape,
      textStyle: _label,
    );
  }

  static ButtonStyle outlined({
    Color color = AppPalette.primary,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      padding: _padding,
      shape: _shape,
      textStyle: _label,
      side: BorderSide(color: color, width: 1.5),
    );
  }

  static ButtonStyle text({
    Color color = AppPalette.primary,
  }) {
    return TextButton.styleFrom(
      foregroundColor: color,
      padding: _padding,
      shape: _shape,
      textStyle: _label,
    );
  }

  static ButtonStyle filled({
    Color background = AppPalette.primary,
    Color foreground = AppPalette.onPrimary,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.4),
      disabledForegroundColor: foreground.withValues(alpha: 0.7),
      padding: _padding,
      shape: _shape,
      textStyle: _label,
    );
  }

  static final ButtonStyle primaryElevated = elevated();
  static final ButtonStyle primaryOutlined = outlined();
  static final ButtonStyle primaryText = text();
  static final ButtonStyle primaryFilled = filled();

  static final ButtonStyle income = elevated(background: AppPalette.income);
  static final ButtonStyle expense = elevated(background: AppPalette.expense);
}
