import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;

  const BrandLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandLogoPainter(),
      ),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Top dot (Burnt Sienna #EE6C4D)
    final dotPaint = Paint()
      ..color = AppTheme.burntSienna
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final dotCenter = Offset(w * 0.5, h * 0.22);
    final dotRadius = w * 0.14;
    canvas.drawCircle(dotCenter, dotRadius, dotPaint);

    // 2. Left leaf (YInMn Blue #3D5A80)
    final leftLeafPaint = Paint()
      ..color = AppTheme.yinMnBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final leftPath = Path();
    leftPath.moveTo(w * 0.48, h * 0.92);
    leftPath.cubicTo(
      w * 0.44, h * 0.70,
      w * 0.16, h * 0.60,
      w * 0.16, h * 0.42,
    );
    leftPath.cubicTo(
      w * 0.16, h * 0.32,
      w * 0.35, h * 0.34,
      w * 0.46, h * 0.56,
    );
    leftPath.close();
    canvas.drawPath(leftPath, leftLeafPaint);

    // 3. Right leaf (Powder Blue #98C1D9)
    final rightLeafPaint = Paint()
      ..color = AppTheme.powderBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rightPath = Path();
    rightPath.moveTo(w * 0.52, h * 0.92);
    rightPath.cubicTo(
      w * 0.56, h * 0.70,
      w * 0.84, h * 0.60,
      w * 0.84, h * 0.42,
    );
    rightPath.cubicTo(
      w * 0.84, h * 0.32,
      w * 0.65, h * 0.34,
      w * 0.54, h * 0.56,
    );
    rightPath.close();
    canvas.drawPath(rightPath, rightLeafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
