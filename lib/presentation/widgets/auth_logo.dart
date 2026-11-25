import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// FinanceMate brand mark drawn as vectors: a navy rounded-square badge with a
/// bold `F` and a green growth arrow, followed by the wordmark.
///
/// Drawn in code so the mark stays crisp at every size and keeps a transparent
/// background. [iconSize], [fontSize], [showText] and [isHorizontal] let the
/// same mark serve the auth screens, the splash screen and compact headers.
class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.iconSize = 76,
    this.fontSize = 26,
    this.showText = true,
    this.isHorizontal = false,
  });

  final double iconSize;
  final double fontSize;
  final bool showText;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    final icon = CustomPaint(
      size: Size.square(iconSize),
      painter: const _AuthLogoPainter(),
    );

    if (!showText) return icon;

    final wordmark = Text(
      'FinanceMate',
      style: TextStyle(
        color: AppPalette.authNavy,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 10), wordmark],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [icon, const SizedBox(height: 8), wordmark],
    );
  }
}

class _AuthLogoPainter extends CustomPainter {
  const _AuthLogoPainter();

  /// The badge is authored against a 76x76 box and then scaled to the
  /// requested icon size, so strokes stay proportional at every size.
  static const double _designSize = 76;
  static const double _outlineStroke = 6.5;
  static const double _arrowStroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _designSize);

    // Rounded-square outline, inset by half the stroke so it stays inside.
    final inset = _outlineStroke / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          _designSize - _outlineStroke,
          _designSize - _outlineStroke,
        ),
        const Radius.circular(16),
      ),
      Paint()
        ..color = AppPalette.authNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineStroke
        ..strokeJoin = StrokeJoin.round,
    );

    // Bold `F`.
    canvas.drawPath(
      Path()
        ..addRect(const Rect.fromLTWH(24, 22, 28, 8))
        ..addRect(const Rect.fromLTWH(24, 35, 22, 8))
        ..addRect(const Rect.fromLTWH(24, 22, 8, 32)),
      Paint()..color = AppPalette.authNavy,
    );

    // Upward zig-zag growth arrow cutting from bottom-left to top-right.
    canvas.drawPath(
      Path()
        ..moveTo(14, 58)
        ..lineTo(28, 44)
        ..lineTo(36, 51)
        ..lineTo(58, 24)
        ..lineTo(44, 24)
        ..moveTo(58, 24)
        ..lineTo(58, 38),
      Paint()
        ..color = AppPalette.authLogoGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = _arrowStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AuthLogoPainter oldDelegate) => false;
}
