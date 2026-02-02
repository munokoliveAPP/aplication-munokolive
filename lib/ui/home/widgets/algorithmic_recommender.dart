import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:munokolive_music/models/event_model.dart';
import 'package:munokolive_music/providers/events_repository.dart';
import 'package:munokolive_music/providers/user_location_provider.dart';

class AlgorithmicRecommender extends ConsumerStatefulWidget {
  final VoidCallback? onEventTap;

  const AlgorithmicRecommender({super.key, this.onEventTap});

  @override
  ConsumerState<AlgorithmicRecommender> createState() =>
      _AlgorithmicRecommenderState();
}

class _AlgorithmicRecommenderState extends ConsumerState<AlgorithmicRecommender>
    with SingleTickerProviderStateMixin {
  EventModel? _recommendedEvent;
  String _algoTag = 'EVENT'; // To store the computed tag
  late AnimationController _pulseController;

  bool _isCalculatingDistance = false;
  Timer? _distanceCalculationTimer;
  String _displayedDistance = "";

  // States for Glitch Transition
  bool _isTransitioning = false;
  double _glitchOffset = 0.0;
  Color? _glitchColor;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _distanceCalculationTimer?.cancel();
    super.dispose();
  }

  void _triggerDistanceCalculationEffect(String finalDistance) {
    if (!mounted) return;
    // If we are already displaying this distance, don't glitch/recalc
    if (_displayedDistance == finalDistance && !_isCalculatingDistance) return;

    setState(() {
      _isCalculatingDistance = true;
      _displayedDistance = "[Calcul...]";
    });

    int step = 0;
    _distanceCalculationTimer?.cancel();
    _distanceCalculationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) return;

        step++;
        if (step < 8) {
          setState(() {
            final chars = ['X', '0', '1', '7', 'A', 'Z', '#', '%'];
            final randomChar = chars[Random().nextInt(chars.length)];
            _displayedDistance =
                "[Calcul... $randomChar${Random().nextInt(99)}]";
          });
        } else {
          timer.cancel();
          setState(() {
            _isCalculatingDistance = false;
            _displayedDistance = finalDistance;
          });
        }
      },
    );
  }

  // Handle transitions with glitch effect
  Future<void> _updateRecommendedEvent(
    EventModel? newEvent,
    String newTag,
    Position? currentPosition,
  ) async {
    if (newEvent == null) return;

    // Check if event actually changed
    if (_recommendedEvent != null && _recommendedEvent!.id == newEvent.id) {
      // Just update distance if needed
      if (currentPosition != null &&
          newEvent.latitude != null &&
          newEvent.longitude != null) {
        final dist = _calculateDistanceString(
          newEvent.latitude!,
          newEvent.longitude!,
          currentPosition,
        );
        _triggerDistanceCalculationEffect(dist);
      }
      return;
    }

    // Trigger Glitch OUT
    if (mounted) {
      setState(() {
        _isTransitioning = true;
        _glitchColor = Colors.white;
        _glitchOffset = 5.0;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _glitchOffset = -5.0;
        _glitchColor = Colors.cyanAccent;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Update Data
    if (mounted) {
      setState(() {
        _recommendedEvent = newEvent;
        _algoTag = newTag;
        _glitchOffset = 0.0;
        _glitchColor = null;
        _isTransitioning = false;
      });

      // Trigger Distance Calculation
      if (currentPosition != null &&
          newEvent.latitude != null &&
          newEvent.longitude != null) {
        _triggerDistanceCalculationEffect(
          _calculateDistanceString(
            newEvent.latitude!,
            newEvent.longitude!,
            currentPosition,
          ),
        );
      } else {
        _triggerDistanceCalculationEffect("N/A");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch shared providers
    final userLocationAsync = ref.watch(userLocationProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);
    final currentPosition = userLocationAsync.valueOrNull;

    eventsAsync.whenData((events) {
      if (events.isEmpty) return;
      final result = _applyAlgorithm(events, currentPosition);
      if (result != null) {
        if (_recommendedEvent?.id != result.event.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateRecommendedEvent(result.event, result.tag, currentPosition);
          });
        } else {
          // Same event, check if distance needs update (e.g. user moved)
          if (currentPosition != null &&
              result.event.latitude != null &&
              result.event.longitude != null &&
              !_isCalculatingDistance) {
            final newDist = _calculateDistanceString(
              result.event.latitude!,
              result.event.longitude!,
              currentPosition,
            );

            // Only update if significantly different or if current display is placeholder
            if (newDist != _displayedDistance &&
                !_displayedDistance.startsWith("[")) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _triggerDistanceCalculationEffect(newDist);
              });
            }
          }
        }
      }
    });

    if (_recommendedEvent == null) return const SizedBox.shrink();

    final event = _recommendedEvent!;
    final date = event.eventDate;
    final formattedDate = DateFormat(
      'EEE d MMM • HH:mm',
      'fr_FR',
    ).format(date).toUpperCase();
    final tag = _algoTag;

    Color accentColor;
    if (tag == 'LIVE') {
      accentColor = Colors.amberAccent;
    } else if (tag == 'PROXIMITY_CLOSE') {
      accentColor = const Color(0xFF00FF41);
    } else if (tag == 'PROXIMITY') {
      accentColor = Colors.cyanAccent;
    } else {
      accentColor = Colors.purpleAccent;
    }

    return GestureDetector(
      onTap: widget.onEventTap,
      child: Transform.translate(
        offset: Offset(_glitchOffset, 0),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 1. Background Image with Blur
                if (event.imageUrl != null)
                  Positioned.fill(
                    child: ColorFiltered(
                      colorFilter: _isTransitioning
                          ? const ColorFilter.mode(
                              Colors.red,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.black),
                      ),
                    ),
                  )
                else
                  Container(color: const Color(0xFF1A0B2E)),

                // Glassmorphism Overlay
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color:
                          _glitchColor?.withValues(alpha: 0.3) ??
                          Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                // 2. Data Frame Borders
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.1),
                          Colors.transparent,
                          accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                      boxShadow: tag == 'LIVE'
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),

                // Corner Accents
                Positioned(
                  top: 0,
                  left: 0,
                  child: _CornerAccent(color: accentColor),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Transform.rotate(
                    angle: pi,
                    child: _CornerAccent(color: accentColor),
                  ),
                ),

                // 3. Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Date & Time Box
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.oxanium(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM',
                                'fr_FR',
                              ).format(date).toUpperCase(),
                              style: GoogleFonts.oxanium(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                if (tag == 'LIVE')
                                  FadeTransition(
                                    opacity: _pulseController,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Text(
                                        "SPECIAL EVENT",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.oxanium(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: accentColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.near_me,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _displayedDistance.isNotEmpty
                                        ? _displayedDistance
                                        : "Calcul...",
                                    key: ValueKey(_displayedDistance),
                                    style: TextStyle(
                                      color: _isCalculatingDistance
                                          ? accentColor
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow / Action
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: accentColor.withValues(alpha: 0.8),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Classes & Methods ---

  _RecommendationResult? _applyAlgorithm(
    List<EventModel> events,
    Position? currentPosition,
  ) {
    // Filter out past events just in case, though Repo should handle it
    final futureEvents = events
        .where((e) => e.eventDate.isAfter(DateTime.now()))
        .toList(); // Create a copy

    if (futureEvents.isEmpty) return null;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    // Priority 1: Event Today
    try {
      final todayEvent = futureEvents.firstWhere((e) {
        final d = e.eventDate;
        return "${d.year}-${d.month}-${d.day}" == todayStr;
      });
      return _RecommendationResult(todayEvent, 'LIVE');
    } catch (_) {}

    // Priority 2: Closest Geographically
    if (currentPosition != null) {
      // Sort by distance (create a new list to avoid mutating the provider's list)
      final sortedByDist = List<EventModel>.from(futureEvents);
      sortedByDist.sort((a, b) {
        if (a.latitude == null ||
            a.longitude == null ||
            b.latitude == null ||
            b.longitude == null) {
          return 0;
        }

        final distA = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distB = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distA.compareTo(distB);
      });

      final closest = sortedByDist.first;
      if (closest.latitude != null && closest.longitude != null) {
        final dist = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          closest.latitude!,
          closest.longitude!,
        );

        if (dist < 5000) {
          return _RecommendationResult(closest, 'PROXIMITY_CLOSE');
        } else if (dist < 50000) {
          return _RecommendationResult(closest, 'PROXIMITY');
        }
      }
    }

    // Priority 3: Soonest (Default sort of the list is usually by date)
    // Re-sort by date just to be sure
    futureEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return _RecommendationResult(futureEvents.first, 'NEW');
  }

  String _calculateDistanceString(
    double lat,
    double lng,
    Position currentPosition,
  ) {
    final distMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      lat,
      lng,
    );

    if (distMeters < 1000) {
      return "${distMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distMeters / 1000).toStringAsFixed(1)} km";
    }
  }
}

class _CornerAccent extends StatelessWidget {
  final Color color;
  const _CornerAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _CornerPainter(color: color)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecommendationResult {
  final EventModel event;
  final String tag;
  _RecommendationResult(this.event, this.tag);
}
