import 'package:flutter/material.dart';

class WavyBackground extends StatelessWidget {
  final Widget child;

  const WavyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WavyBackgroundPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _WavyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background color
    final basePaint = Paint()..color = const Color(0xFFEFF7FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    // Top gentle ambient wave
    final topPaint = Paint()
      ..color = const Color(0xFFDCEEF6).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(w, 0);
    topPath.lineTo(w, h * 0.22);
    topPath.cubicTo(
      w * 0.75, h * 0.28,
      w * 0.40, h * 0.12,
      0, h * 0.20,
    );
    topPath.close();
    canvas.drawPath(topPath, topPaint);

    // Bottom soft curve
    final bottomPaint = Paint()
      ..color = const Color(0xFFD8ECF5).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final bottomPath = Path();
    bottomPath.moveTo(0, h * 0.65);
    bottomPath.cubicTo(
      w * 0.35, h * 0.58,
      w * 0.65, h * 0.78,
      w, h * 0.70,
    );
    bottomPath.lineTo(w, h);
    bottomPath.lineTo(0, h);
    bottomPath.close();
    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
