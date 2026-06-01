import 'dart:math' as math;
import 'package:flutter/material.dart';

enum AnimatedSvgIconType {
  dashboard,
  analytics,
  mentor,
  settings,
}

class AnimatedSvgIcon extends StatelessWidget {
  final AnimatedSvgIconType type;
  final double progress; // 0.0 to 1.0 based on selection state
  final Color color;
  final double size;

  const AnimatedSvgIcon({
    super.key,
    required this.type,
    required this.progress,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AnimatedSvgIconPainter(
        type: type,
        progress: progress,
        color: color,
      ),
    );
  }
}

class _AnimatedSvgIconPainter extends CustomPainter {
  final AnimatedSvgIconType type;
  final double progress;
  final Color color;

  _AnimatedSvgIconPainter({
    required this.type,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    switch (type) {
      case AnimatedSvgIconType.dashboard:
        _paintDashboard(canvas, size, paint, fillPaint);
        break;
      case AnimatedSvgIconType.analytics:
        _paintAnalytics(canvas, size, paint, fillPaint);
        break;
      case AnimatedSvgIconType.mentor:
        _paintMentor(canvas, size, paint, fillPaint);
        break;
      case AnimatedSvgIconType.settings:
        _paintSettings(canvas, size, paint, fillPaint);
        break;
    }
  }

  void _paintDashboard(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    // Grid nodes shift outward and expand borders upon selection
    double x1 = 3 - (1.0 * progress);
    double y1 = 3 - (1.0 * progress);
    double w1 = 8 + (1.0 * progress);
    double h1 = 8 + (1.0 * progress);

    double x2 = 13;
    double y2 = 3 - (1.0 * progress);
    double w2 = 8 + (1.0 * progress);
    double h2 = 5 + (1.0 * progress);

    double x3 = 3 - (1.0 * progress);
    double y3 = 13;
    double w3 = 8 + (1.0 * progress);
    double h3 = 8 + (1.0 * progress);

    double x4 = 13;
    double y4 = 10;
    double w4 = 8 + (1.0 * progress);
    double h4 = 11 + (1.0 * progress);

    void drawCard(double x, double y, double w, double h) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scaleX, y * scaleY, w * scaleX, h * scaleY),
        Radius.circular(2.5 * scaleX),
      );
      if (progress > 0.0) {
        fillPaint.color = color.withOpacity(progress * 0.15);
        canvas.drawRRect(rect, fillPaint);
      }
      canvas.drawRRect(rect, paint);
    }

    drawCard(x1, y1, w1, h1);
    drawCard(x2, y2, w2, h2);
    drawCard(x3, y3, w3, h3);
    drawCard(x4, y4, w4, h4);
  }

  void _paintAnalytics(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    // Render 3 growing columns
    double h1 = 6 + (4.0 * progress);
    double h2 = 9 + (8.0 * progress);
    double h3 = 7 + (7.0 * progress);

    void drawBar(double x, double targetH) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scaleX, (20 - targetH) * scaleY, 4 * scaleX, targetH * scaleY),
        Radius.circular(1.5 * scaleX),
      );
      if (progress > 0.0) {
        fillPaint.color = color.withOpacity(progress * 0.15);
        canvas.drawRRect(rect, fillPaint);
      }
      canvas.drawRRect(rect, paint);
    }

    drawBar(3, h1);
    drawBar(10, h2);
    drawBar(17, h3);

    // Floor Axis line
    canvas.drawLine(
      Offset(2 * scaleX, 20 * scaleY),
      Offset(22 * scaleX, 20 * scaleY),
      paint,
    );

    // Bending trend line that grows with active spark
    if (progress > 0.0) {
      final linePaint = Paint()
        ..color = color.withOpacity(progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scaleX
        ..strokeCap = StrokeCap.round;

      final sparkPath = Path()
        ..moveTo(5 * scaleX, (20 - h1 - 2.0) * scaleY)
        ..quadraticBezierTo(
          12 * scaleX,
          (20 - h2 - 4.0) * scaleY,
          19 * scaleX,
          (20 - h3 - 2.0) * scaleY,
        );

      canvas.drawPath(sparkPath, linePaint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(19 * scaleX, (20 - h3 - 2.0) * scaleY),
        2.5 * scaleX,
        dotPaint,
      );
    }
  }

  void _paintMentor(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    Path createStarPath(double x, double y, double radius) {
      final path = Path();
      path.moveTo(x, y - radius);
      path.quadraticBezierTo(x, y, x + radius, y);
      path.quadraticBezierTo(x, y, x, y + radius);
      path.quadraticBezierTo(x, y, x - radius, y);
      path.quadraticBezierTo(x, y, x, y - radius);
      path.close();
      return path;
    }

    // 1. Central star rotates and scales up
    final mainRadius = (6.0 + (2.5 * progress)) * scaleX;
    final mainRotation = progress * (math.pi / 2);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(mainRotation);
    final mainStarPath = createStarPath(0, 0, mainRadius);
    if (progress > 0.0) {
      fillPaint.color = color.withOpacity(progress * 0.2);
      canvas.drawPath(mainStarPath, fillPaint);
    }
    canvas.drawPath(mainStarPath, paint);
    canvas.restore();

    // 2. Spark Top-Right expands and orbits backwards
    final trX = (17.5 + (1.5 * progress)) * scaleX;
    final trY = (6.5 - (1.5 * progress)) * scaleY;
    final trRadius = (2.2 + (1.3 * progress)) * scaleX;
    final trRotation = -progress * (math.pi / 3);

    canvas.save();
    canvas.translate(trX, trY);
    canvas.rotate(trRotation);
    final trStarPath = createStarPath(0, 0, trRadius);
    if (progress > 0.0) {
      fillPaint.color = color.withOpacity(progress * 0.15);
      canvas.drawPath(trStarPath, fillPaint);
    }
    canvas.drawPath(trStarPath, paint);
    canvas.restore();

    // 3. Spark Bottom-Left expands
    final blX = (6.5 - (1.5 * progress)) * scaleX;
    final blY = (17.5 + (1.5 * progress)) * scaleY;
    final blRadius = (1.8 + (1.2 * progress)) * scaleX;
    final blRotation = -progress * (math.pi / 4);

    canvas.save();
    canvas.translate(blX, blY);
    canvas.rotate(blRotation);
    final blStarPath = createStarPath(0, 0, blRadius);
    if (progress > 0.0) {
      fillPaint.color = color.withOpacity(progress * 0.15);
      canvas.drawPath(blStarPath, fillPaint);
    }
    canvas.drawPath(blStarPath, paint);
    canvas.restore();
  }

  void _paintSettings(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final scale = size.width / 24.0;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    // Gear spins nicely by 135 degrees upon full selection
    canvas.rotate(progress * (math.pi * 0.75));

    final outerRadius = 7.8 * scale;
    final innerRadius = 3.5 * scale;
    const teethCount = 6;
    final teethDepth = 1.8 * scale;
    const teethWidth = 0.35; // radians

    final path = Path();
    for (int i = 0; i < teethCount; i++) {
      final double angle = (2 * math.pi / teethCount) * i;
      final double a1 = angle - teethWidth / 2;
      final double a2 = angle + teethWidth / 2;

      final x1 = (outerRadius - teethDepth) * math.cos(a1);
      final y1 = (outerRadius - teethDepth) * math.sin(a1);

      final x2 = outerRadius * math.cos(a1);
      final y2 = outerRadius * math.sin(a1);

      final x3 = outerRadius * math.cos(a2);
      final y3 = outerRadius * math.sin(a2);

      final x4 = (outerRadius - teethDepth) * math.cos(a2);
      final y4 = (outerRadius - teethDepth) * math.sin(a2);

      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
      path.lineTo(x4, y4);

      final double nextAngle = (2 * math.pi / teethCount) * (i + 1);
      final double aNext1 = nextAngle - teethWidth / 2;
      final nextX1 = (outerRadius - teethDepth) * math.cos(aNext1);
      final nextY1 = (outerRadius - teethDepth) * math.sin(aNext1);
      path.lineTo(nextX1, nextY1);
    }
    path.close();

    if (progress > 0.0) {
      fillPaint.color = color.withOpacity(progress * 0.15);
      canvas.drawPath(path, fillPaint);
    }
    canvas.drawPath(path, paint);

    // Internal center ring
    final centerPaint = Paint()
      ..color = color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset.zero, innerRadius, centerPaint);

    if (progress > 0.0) {
      final pulsePaint = Paint()
        ..color = color.withOpacity(progress * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, innerRadius * 0.5, pulsePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedSvgIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
