import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NearbyEventCard extends StatefulWidget {
  final Map<String, dynamic>? event;
  final VoidCallback? onTap;

  const NearbyEventCard({super.key, this.event, this.onTap});

  @override
  State<NearbyEventCard> createState() => _NearbyEventCardState();
}

class _NearbyEventCardState extends State<NearbyEventCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _tiltController;

  // Tilt State
  Offset _touchPosition = Offset.zero;
  Offset _startTiltOffset = Offset.zero; // For reset animation
  final double _maxTiltAngle = 0.15; // Max tilt in radians (approx 8.5 degrees)

  @override
  void initState() {
    super.initState();
    // Pulse/Scanning Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Tilt Reset Animation
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tiltController.addListener(_onTiltAnimationTick);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tiltController.removeListener(_onTiltAnimationTick);
    _tiltController.dispose();
    super.dispose();
  }

  void _onTiltAnimationTick() {
    if (_tiltController.isAnimating) {
      setState(() {
        _touchPosition = Offset.lerp(
          _startTiltOffset,
          Offset.zero,
          Curves.easeOutBack.transform(_tiltController.value),
        )!;
      });
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _tiltController.stop();
    _updateTilt(event.localPosition, context.size!);
  }

  void _onPointerMove(PointerMoveEvent event) {
    _updateTilt(event.localPosition, context.size!);
  }

  void _onPointerUp(PointerUpEvent event) {
    _resetTilt();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _resetTilt();
  }

  void _updateTilt(Offset localPosition, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Normalize position (-1 to 1)
    final dx = (localPosition.dx - centerX) / centerX;
    final dy = (localPosition.dy - centerY) / centerY;

    setState(() {
      _touchPosition = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _resetTilt() {
    _startTiltOffset = _touchPosition;
    _tiltController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isScanning = event == null;

    final now = DateTime.now();
    final date = isScanning
        ? now
        : (event['parsedDate'] as DateTime? ?? DateTime.parse(event['date']));

    // Formatting
    final dayNumber = DateFormat('d', 'fr_FR').format(date);
    final monthName = DateFormat(
      'MMM',
      'fr_FR',
    ).format(date).toUpperCase().replaceAll('.', '');
    final fullDate = isScanning
        ? "RECHERCHE EN COURS..."
        : DateFormat('EEE d MMM • HH:mm', 'fr_FR').format(date).toUpperCase();

    final title = isScanning
        ? "Détection d'événements..."
        : (event['title'] as String);
    final location = isScanning
        ? "Analyse de la zone..."
        : (event['location'] as String? ?? "Lieu inconnu");

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Calculate dynamic tilt
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(
            _touchPosition.dy * -_maxTiltAngle,
          ) // Invert Y for correct tilt feel
          ..rotateY(_touchPosition.dx * _maxTiltAngle);

        return Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              height: 90,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF150020), // Dark background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isScanning
                      ? Colors.cyanAccent.withValues(alpha: 0.5)
                      : Colors.purpleAccent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isScanning ? Colors.cyanAccent : Colors.purpleAccent)
                            .withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: Offset(
                      _touchPosition.dx *
                          -5, // Shadow moves opposite to light source/tilt
                      _touchPosition.dy * -5,
                    ),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  splashColor:
                      (isScanning ? Colors.cyanAccent : Colors.purpleAccent)
                          .withValues(alpha: 0.2),
                  highlightColor:
                      (isScanning ? Colors.cyanAccent : Colors.purpleAccent)
                          .withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Date Box with 3D Pop
                        Transform(
                          transform: Matrix4.translationValues(
                            _touchPosition.dx * 10,
                            _touchPosition.dy * 10,
                            0.0,
                          ),
                          child: Container(
                            width: 60,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A0B36),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 5,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  monthName,
                                  style: TextStyle(
                                    color: isScanning
                                        ? Colors.cyanAccent
                                        : Colors.purpleAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top Date/Time Line
                              Text(
                                fullDate,
                                style: TextStyle(
                                  color: isScanning
                                      ? Colors.cyanAccent
                                      : const Color(0xFFE040FB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Title
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Location
                              Row(
                                children: [
                                  Icon(
                                    Icons.near_me,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Arrow with Pulse
                        Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.2),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(
                              alpha: 0.3 + (_pulseController.value * 0.3),
                            ),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
