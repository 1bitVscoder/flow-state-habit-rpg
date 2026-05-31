import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidProgressRing extends StatefulWidget {
  final double percentage; // 0.0 to 1.0
  final double size;
  final Color activeColor;

  const LiquidProgressRing({
    super.key,
    required this.percentage,
    this.size = 72.0,
    this.activeColor = const Color(0xff00F2C3),
  });

  @override
  State<LiquidProgressRing> createState() => _LiquidProgressRingState();
}

class _LiquidProgressRingState extends State<LiquidProgressRing> with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _fillController;
  late Animation<double> _fillAnimation;
  double _prevPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    // Continuous horizontal wave shifting
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Rises liquid vertically when percentage updates
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutBack),
    );

    _fillController.forward();
    _prevPercentage = widget.percentage;
  }

  @override
  void didUpdateWidget(covariant LiquidProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _fillAnimation = Tween<double>(
        begin: _prevPercentage,
        end: widget.percentage,
      ).animate(
        CurvedAnimation(parent: _fillController, curve: Curves.easeOutBack),
      );
      _fillController.reset();
      _fillController.forward();
      _prevPercentage = widget.percentage;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _fillController]),
      builder: (context, child) {
        final animatedFill = _fillAnimation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Radial Frame
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.activeColor.withOpacity(0.08),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Liquid Waving Canvas
            SizedBox(
              width: widget.size - 7,
              height: widget.size - 7,
              child: ClipOval(
                child: CustomPaint(
                  painter: LiquidWavePainter(
                    waveOffset: _waveController.value * 2 * math.pi,
                    fillLevel: animatedFill,
                    waveColor: widget.activeColor,
                  ),
                ),
              ),
            ),

            // Center Stats Label (e.g. "87%")
            Text(
              '${(animatedFill * 100).toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: widget.size * 0.22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class LiquidWavePainter extends CustomPainter {
  final double waveOffset;
  final double fillLevel; // 0.0 to 1.0
  final Color waveColor;

  LiquidWavePainter({
    required this.waveOffset,
    required this.fillLevel,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final secondaryPaint = Paint()
      ..color = waveColor.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final double waveHeight = 5.0; // wave peak-to-trough
    final double waveFrequency = 0.07; // wave spacing speed

    // Calculate vertical height point relative to completion percentage
    final double targetY = size.height - (fillLevel * size.height);

    // Path 1: Primary Back Wave
    final path1 = Path();
    path1.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y = targetY + math.sin(x * waveFrequency + waveOffset) * waveHeight;
      path1.lineTo(x, y.clamp(0.0, size.height));
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, secondaryPaint);

    // Path 2: Primary Front Wave (Offset for Depth)
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final double y = targetY + math.cos(x * waveFrequency - waveOffset) * (waveHeight * 0.8);
      path2.lineTo(x, y.clamp(0.0, size.height));
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
