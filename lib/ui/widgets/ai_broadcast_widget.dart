import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/offline_provider.dart';

class AiBroadcastWidget extends ConsumerStatefulWidget {
  const AiBroadcastWidget({super.key});

  @override
  ConsumerState<AiBroadcastWidget> createState() => _AiBroadcastWidgetState();
}

class _AiBroadcastWidgetState extends ConsumerState<AiBroadcastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final _supabase = Supabase.instance.client;

  // États pour la séquence de rétablissement
  bool _isRecovering = false;
  Timer? _recoveryTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _recoveryTimer?.cancel();
    super.dispose();
  }

  void _triggerRecoverySequence() {
    if (mounted) {
      setState(() => _isRecovering = true);

      // Petit effet "Flash" vert pendant 4 secondes
      _recoveryTimer?.cancel();
      _recoveryTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _isRecovering = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écoute de l'état de connexion
    final isOffline = ref.watch(isOfflineProvider);

    // Détection de la transition OFF -> ON pour déclencher l'effet "Succès"
    ref.listen<bool>(isOfflineProvider, (previous, next) {
      if (previous == true && next == false) {
        _triggerRecoverySequence();
      }
    });

    // Définition des couleurs en fonction du statut
    Color themeColor;
    Color borderColor;

    if (isOffline) {
      themeColor = Colors.orangeAccent;
      borderColor = Colors.redAccent;
    } else if (_isRecovering) {
      themeColor = const Color(0xFF00FF41); // Vert Hacker "Matrix"
      borderColor = Colors.greenAccent;
    } else {
      themeColor = Colors.cyanAccent;
      borderColor = Colors.cyanAccent;
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _supabase
          .from('app_config')
          .stream(primaryKey: ['id'])
          .eq('id', 1)
          .map((data) => data.isNotEmpty ? data.first : {}),
      builder: (context, snapshot) {
        // Logique de message
        String message = "INITIALIZING SYSTEM... STAND BY...";

        if (isOffline) {
          message =
              "[ ! ] ALERTE LIAISON : Mode local activé. Données limitées.";
        } else if (_isRecovering) {
          message = "[ ✓ ] LIAISON RÉTABLIE : Synchronisation terminée.";
        } else if (snapshot.hasData && snapshot.data != null) {
          final msg = snapshot.data!['ai_message'] as String?;
          if (msg != null && msg.isNotEmpty) {
            message = msg;
          } else {
            message = "Système : En ligne. Prêt pour l'opération.";
          }
        }

        // Si le message est vide en BDD et qu'on est en ligne (hors recovery), on n'affiche rien
        if (!isOffline && !_isRecovering && message.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          height: 42,
          child: Stack(
            children: [
              // 1. CRT Grain & Glass Background
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0F14).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withValues(
                            alpha: _isRecovering ? 0.6 : 0.1,
                          ),
                          blurRadius: _isRecovering ? 20 : 10,
                          spreadRadius: _isRecovering ? 2 : 1,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _CrtGrainPainter(),
                      child: Container(),
                    ),
                  ),
                ),
              ),

              // 2. Content
              Row(
                children: [
                  // Badge INFO Cyberpunk
                  _buildCyberBadge(themeColor, isOffline, _isRecovering),

                  // Scrolling Message
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      child: Marquee(
                        text: "$message   ///   ",
                        style: GoogleFonts.spaceMono(
                          color: isOffline
                              ? Colors.orangeAccent
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          shadows: [
                            Shadow(
                              color: themeColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 20.0,
                        velocity: 30.0,
                        startPadding: 10.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCyberBadge(Color color, bool isAlert, bool isRecovering) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radar Pulse Effect behind the badge
        AnimatedBuilder(
          animation: _radarController,
          builder: (context, child) {
            return CustomPaint(
              painter: _RadarPulsePainter(
                animationValue: _radarController.value,
                color: color,
                isRapid:
                    isAlert ||
                    isRecovering, // Pulse plus rapide en mode alerte ou recovery
              ),
              size: const Size(60, 48),
            );
          },
        ),

        // The Badge Itself
        ClipPath(
          clipper: _CyberBadgeClipper(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            height: 42, // Match container height
            width: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              border: Border(
                right: BorderSide(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    isRecovering ? "SYNC" : "INFO",
                    style: GoogleFonts.vt323(
                      color: color,
                      fontSize: 20, // Bigger for VT323
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                // Hacker Status Dot (Top Right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAlert
                          ? Colors
                                .blueAccent // Bleu pulsant (Offline/Cache)
                          : (isRecovering
                                ? Colors.greenAccent
                                : const Color(
                                    0xFF00FF41,
                                  )), // Vert Hacker (Online)
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isAlert
                                      ? Colors.blueAccent
                                      : const Color(0xFF00FF41))
                                  .withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- PAINTERS & CLIPPERS ---

class _CyberBadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const cutSize = 10.0;

    // Top Left
    path.moveTo(0, 0);
    // Top Right
    path.lineTo(size.width - cutSize, 0);
    path.lineTo(size.width, cutSize); // Cut corner
    // Bottom Right
    path.lineTo(size.width, size.height);
    // Bottom Left
    path.lineTo(0, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RadarPulsePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final bool isRapid;

  _RadarPulsePainter({
    required this.animationValue,
    required this.color,
    this.isRapid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Pulse Speed Logic
    // If rapid (alert mode), we effectively double the speed visually by phase shifting
    final effectiveValue = isRapid
        ? (animationValue * 2) % 1.0
        : animationValue;

    // Draw 2 ripple circles
    for (int i = 0; i < 2; i++) {
      final value = (effectiveValue + i * 0.5) % 1.0;
      final radius = value * maxRadius;
      final opacity = (1.0 - value).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.isRapid != isRapid;
  }
}

class _CrtGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    final paint = Paint();

    // Draw random noise points
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.05);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }

    // Draw subtle scanlines
    paint.color = Colors.black.withValues(alpha: 0.1);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
