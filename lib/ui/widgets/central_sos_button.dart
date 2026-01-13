import 'dart:math' as math show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/auth_service.dart';
import '../../providers/sos_provider.dart';
import '../../ui/sos/sos_screen.dart';

class CentralSOSButton extends ConsumerStatefulWidget {
  final VoidCallback? onSoSTriggered;

  const CentralSOSButton({super.key, this.onSoSTriggered});

  @override
  ConsumerState<CentralSOSButton> createState() => _CentralSOSButtonState();
}

class _CentralSOSButtonState extends ConsumerState<CentralSOSButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSOS() async {
    // Logic to trigger SOS
    final userAsync = ref.read(currentUserProfileProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur non connecté')),
      );
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();

      await ref
          .read(sosServiceProvider)
          .triggerSOS(
            requesterId: user.uid,
            requesterName: '${user.firstName} ${user.lastName}',
            location: GeoPoint(pos.latitude, pos.longitude),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ALERTE SOS ENVOYÉE ! RECHERCHE DE MUSICIENS...'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 5),
          ),
        );
        widget.onSoSTriggered?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur SOS: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const SosScreen()));
        },
        onLongPressStart: (_) => setState(() => _isPressed = true),
        onLongPressEnd: (_) {
          setState(() => _isPressed = false);
          _handleSOS();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Halo
            RotationTransition(
              turns: _rotationController,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: HaloPainter(),
              ),
            ),

            // Pulsing Glow (when active/idle)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: _isPressed ? 110 : 90 + (_pulseController.value * 10),
                  height: _isPressed ? 110 : 90 + (_pulseController.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isPressed
                            ? Colors.redAccent.withValues(alpha: 0.6)
                            : const Color(0xFFDF00FF).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Glass Button
            GlassmorphicContainer(
              width: 80,
              height: 80,
              borderRadius: 40,
              blur: 10,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _isPressed
                      ? Colors.red.withValues(alpha: 0.8)
                      : const Color(0xFF2B124C).withValues(alpha: 0.8),
                  _isPressed
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.8),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFDF00FF).withValues(alpha: 0.6),
                  const Color(0xFFDF00FF).withValues(alpha: 0.1),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sensors, // or emergency_share
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPressed ? 'ACHEMINEMENT' : 'SOS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFDF00FF),
          Colors.transparent,
          Color(0xFF00FFFF),
          Colors.transparent,
          Color(0xFFDF00FF),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw multiple arcs to simulate rotation speed
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );

    final paintInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.3);

    canvas.drawCircle(center, radius * 0.8, paintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
