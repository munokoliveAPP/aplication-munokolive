import 'dart:math';
import 'package:flutter/material.dart';

class AegisRadarOverlay extends StatefulWidget {
  final double radius;
  final Color color;

  const AegisRadarOverlay({
    super.key,
    required this.radius,
    required this.color,
  });

  @override
  State<AegisRadarOverlay> createState() => _AegisRadarOverlayState();
}

class _AegisRadarOverlayState extends State<AegisRadarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: RadarPainter(animation: _controller, color: widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RadarPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Dynamic radius based on screen size, fitting the concept of "scanning around user"
    // Since this overlay is full screen, and the map centers on user,
    // the center of screen is roughly the user's location.
    final maxRadius = min(size.width, size.height) * 0.4;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi * 2,
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.1),
          color.withValues(alpha: 0.5),
        ],
        stops: const [0.5, 0.75, 1.0],
        transform: GradientRotation(animation.value * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    // Draw concentric circles
    canvas.drawCircle(center, maxRadius * 0.33, paint);
    canvas.drawCircle(center, maxRadius * 0.66, paint);
    canvas.drawCircle(center, maxRadius, paint);

    // Draw scanning sweep
    canvas.drawCircle(
      center,
      maxRadius,
      sweepPaint..style = PaintingStyle.fill,
    );

    // Draw crosshairs
    final crossHairPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      crossHairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      crossHairPaint,
    );
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
