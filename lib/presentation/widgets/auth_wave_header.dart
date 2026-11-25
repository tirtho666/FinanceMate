import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Body height of the wave header, measured below the status bar.
const double authWaveBodyHeight = 135;

/// Two-layer wave used by the authentication screens.
///
/// The sky-blue layer covers the top of the screen and the royal-blue ribbon
/// fills the curved band between its bottom edge and the white page below.
class AuthWaveHeader extends StatelessWidget {
  const AuthWaveHeader({super.key, required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: topInset + authWaveBodyHeight,
      child: const CustomPaint(painter: AuthWaveHeaderPainter()),
    );
  }
}

class AuthWaveHeaderPainter extends CustomPainter {
  const AuthWaveHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Sky-blue top layer. Its bottom edge is walked right to left so the path
    // can be closed straight back over the top of the screen.
    final skyBlue = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * 0.45);
    _addSmoothCurve(skyBlue, [
      Offset(width, height * 0.45),
      Offset(width * 0.72, height * 0.22),
      Offset(width * 0.22, height * 0.78),
      Offset(0, height * 0.62),
    ]);
    skyBlue.close();

    // Royal-blue ribbon: bounded above by the sky-blue edge and below by its
    // own bottom edge.
    final ribbon = Path()..moveTo(0, height * 0.62);
    _addSmoothCurve(ribbon, [
      Offset(0, height * 0.62),
      Offset(width * 0.22, height * 0.78),
      Offset(width * 0.72, height * 0.22),
      Offset(width, height * 0.45),
    ]);
    ribbon.lineTo(width, height * 0.92);
    _addSmoothCurve(ribbon, [
      Offset(width, height * 0.92),
      Offset(width * 0.68, height * 0.42),
      Offset(width * 0.24, height * 0.85),
      Offset(0, height * 0.64),
    ]);
    ribbon.close();

    canvas.drawPath(skyBlue, Paint()..color = AppPalette.authWaveBack);
    canvas.drawPath(ribbon, Paint()..color = AppPalette.authWaveFront);
  }

  /// Appends smooth cubic segments through [points] using Catmull-Rom
  /// tangents, so the given anchors are interpolated instead of hard corners.
  /// The current point of [path] must already sit on `points.first`.
  void _addSmoothCurve(Path path, List<Offset> points) {
    for (var i = 0; i < points.length - 1; i++) {
      final previous = points[i == 0 ? 0 : i - 1];
      final start = points[i];
      final end = points[i + 1];
      final next = points[i + 2 < points.length ? i + 2 : points.length - 1];

      path.cubicTo(
        start.dx + (end.dx - previous.dx) / 6,
        start.dy + (end.dy - previous.dy) / 6,
        end.dx - (next.dx - start.dx) / 6,
        end.dy - (next.dy - start.dy) / 6,
        end.dx,
        end.dy,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AuthWaveHeaderPainter oldDelegate) => false;
}
