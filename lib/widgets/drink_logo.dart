import 'package:flutter/material.dart';

/// Stylized drink mark: a round wine glass with an embedded `%` symbol.
///
/// Drawn with a [CustomPainter] (rather than a bitmap) so it can be recoloured
/// to match whatever surface it sits on - this keeps the mark crisp and legible
/// in both light and dark themes. The geometry mirrors the launcher icon
/// generated from `assets/icon/app_icon.png`.
class DrinkLogo extends StatelessWidget {
  const DrinkLogo({
    super.key,
    this.size = 96,
    this.lineColor,
    this.bowlColor,
    this.percentColor,
  });

  /// Width/height of the (square) logo.
  final double size;

  /// Glass outline, stem and base colour. Defaults to the theme on-surface.
  final Color? lineColor;

  /// Colour of the filled bowl. Defaults to a subtle surface container.
  final Color? bowlColor;

  /// Colour of the embedded percentage symbol. Defaults to the brand accent.
  final Color? percentColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DrinkLogoPainter(
          line: lineColor ?? scheme.onSurface,
          bowl: bowlColor ?? scheme.surfaceContainerHighest,
          percent: percentColor ?? scheme.primary,
        ),
      ),
    );
  }
}

class _DrinkLogoPainter extends CustomPainter {
  const _DrinkLogoPainter({
    required this.line,
    required this.bowl,
    required this.percent,
  });

  final Color line;
  final Color bowl;
  final Color percent;

  @override
  void paint(Canvas canvas, Size size) {
    // Author the mark in a 100 x 100 space and scale it to the requested size.
    final double u = size.shortestSide / 100.0;
    Offset p(double x, double y) => Offset(x * u, y * u);

    final Paint linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stem.
    canvas.drawLine(
      p(50, 66),
      p(50, 86),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * u
        ..strokeCap = StrokeCap.round,
    );

    // Base.
    canvas.drawLine(
      p(32, 90),
      p(68, 90),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * u
        ..strokeCap = StrokeCap.round,
    );

    // Bowl.
    final Rect bowlRect = Rect.fromCircle(center: p(50, 42), radius: 27 * u);
    canvas.drawCircle(
      bowlRect.center,
      bowlRect.width / 2,
      Paint()..color = bowl,
    );

    // Embedded percentage symbol (upper-left ring, lower-right ring, slash).
    final Paint percentPaint = Paint()
      ..color = percent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(p(41, 35), 6 * u, percentPaint);
    canvas.drawCircle(p(60, 49), 6 * u, percentPaint);
    canvas.drawLine(p(36, 52), p(64, 32), percentPaint);

    // Bowl outline drawn last so the rim sits cleanly on top of the symbol.
    canvas.drawCircle(
      bowlRect.center,
      bowlRect.width / 2,
      linePaint..strokeWidth = 3.6 * u,
    );
  }

  @override
  bool shouldRepaint(covariant _DrinkLogoPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.bowl != bowl ||
      oldDelegate.percent != percent;
}
