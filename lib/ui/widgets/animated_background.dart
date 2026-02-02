/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(
                _controller.value * 2 * math.pi,
              ),
              colors: [
                AppTheme.backgroundDark,
                AppTheme.backgroundGradientStart,
                AppTheme.primaryColor.withValues(alpha: 0.3),
                AppTheme.backgroundDark,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _OrbPainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double animationValue;

  _OrbPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Animated orbs
    final orb1X = size.width * 0.2 + math.sin(animationValue * 2 * math.pi) * 50;
    final orb1Y = size.height * 0.3 + math.cos(animationValue * 2 * math.pi) * 50;
    paint.color = AppTheme.primaryColor.withValues(alpha: 0.2);
    canvas.drawCircle(Offset(orb1X, orb1Y), 100, paint);

    final orb2X = size.width * 0.8 + math.cos(animationValue * 2 * math.pi) * 50;
    final orb2Y = size.height * 0.7 + math.sin(animationValue * 2 * math.pi) * 50;
    paint.color = AppTheme.secondaryColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(orb2X, orb2Y), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
