import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/glass_container.dart';

class FeaturedEventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  const FeaturedEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  State<FeaturedEventCard> createState() => _FeaturedEventCardState();
}

class _FeaturedEventCardState extends State<FeaturedEventCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isLive = false;
  bool _isToday = false;
  late AnimationController
  _motionController; // Pour l'effet "Ken Burns" (Parallaxe simulé)
  late AnimationController
  _shimmerController; // Pour l'effet de brillance bouton

  @override
  void initState() {
    super.initState();
    // Animation de pulsation pour le mode LIVE
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation Ken Burns (Zoom lent)
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Très lent
    )..repeat(reverse: true);

    // Animation Shimmer Bouton
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _calculateTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(FeaturedEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event['id'] != widget.event['id']) {
      _calculateTime();
    }
  }

  void _calculateTime() {
    final DateTime date = widget.event['parsedDate'];
    final now = DateTime.now();
    final difference = date.difference(now);

    // Vérification si c'est "Aujourd'hui" (Même jour, mois, année)
    final isSameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;

    setState(() {
      _isToday = isSameDay;

      if (difference.isNegative) {
        // L'événement a commencé
        if (difference.abs().inHours < 4) {
          // Étendu à 4h
          _isLive = true;
          _timeLeft = Duration.zero;
        } else {
          _isLive = false; // Fini
        }
      } else {
        _isLive = false;
        _timeLeft = difference;
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _calculateTime();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _motionController.dispose();
    _shimmerController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    if (duration.inDays > 0) {
      return "${duration.inDays}j : ${twoDigits(duration.inHours.remainder(24))}h";
    } else {
      return "${twoDigits(duration.inHours)}h : ${twoDigits(duration.inMinutes.remainder(60))}m : ${twoDigits(duration.inSeconds.remainder(60))}s";
    }
  }

  // Helper pour le nom du mois
  String _getMonthName(int month) {
    const months = [
      "JAN",
      "FÉV",
      "MAR",
      "AVR",
      "MAI",
      "JUIN",
      "JUIL",
      "AOÛT",
      "SEP",
      "OCT",
      "NOV",
      "DÉC",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.event['title'] ?? 'Événement';
    final location = widget.event['location'] ?? 'Lieu à confirmer';
    final imageUrl = widget.event['image_url'];
    final DateTime date = widget.event['parsedDate'];

    // Couleurs dynamiques selon l'urgence
    Color accentColor;
    if (_isLive) {
      accentColor = const Color(0xFFFF0033); // Rouge Vif
    } else if (_isToday) {
      accentColor = const Color(0xFFFFD700); // Or pour "Aujourd'hui"
    } else if (_timeLeft.inHours < 24) {
      accentColor = Colors.orangeAccent;
    } else {
      accentColor = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 320, // Plus haut pour l'immersion
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          // Ombre portée diffuse pour détacher légèrement du fond
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: _isLive ? 0.3 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. IMAGE DE FOND AVEC EFFET "KEN BURNS" (Mouvement lent) & MASKING
              AnimatedBuilder(
                animation: _motionController,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        1.0 +
                        (_motionController.value *
                            0.1), // Zoom léger de 1.0 à 1.1
                    child: child,
                  );
                },
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black, // Visible en haut
                        Colors.black, // Visible au milieu
                        Colors.transparent, // Disparaît en bas (fusion)
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? 'https://via.placeholder.com/400x300',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF1A0B2E),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.white10,
                          size: 40,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF1A0B2E),
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                    fadeInDuration: const Duration(milliseconds: 500),
                  ),
                ),
              ),

              // 2. OVERLAY "FUSION" & "INTELLIGENT"
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),

              // 3. CONTENU (Information Layer)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER: BADGES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge LIVE / AUJOURD'HUI / TIMER
                        if (_isLive)
                          _buildLiveBadge()
                        else if (_isToday)
                          _buildTodayBadge()
                        else
                          _buildTimerBadge(accentColor),

                        // Badge Date Élégant
                        _buildElegantDate(date),
                      ],
                    ),

                    const Spacer(),

                    // --- FOOTER: TITRE & ACTION ---
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 16),

                    // Ligne Lieu + Bouton
                    Row(
                      children: [
                        // Lieu
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: accentColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "LIEU",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bouton Action "CTA Brillant"
                        _buildShinyCTA(accentColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0033),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0033).withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
            SizedBox(width: 6),
            Text(
              "EN DIRECT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayBadge() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700), // Or
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available, color: Colors.black, size: 14),
            SizedBox(width: 6),
            Text(
              "AUJOURD'HUI",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge(Color color) {
    return GlassContainer(
      borderRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.black,
      opacity: 0.5,
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            _timeLeft.inDays > 30 ? "Bientôt" : _formatDuration(_timeLeft),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDate(DateTime date) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: Colors.black,
      opacity: 0.3,
      borderRadius: 16,
      blur: 5,
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Column(
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          Text(
            _getMonthName(date.month).toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShinyCTA(Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Stack(
            children: [
              // Texte et Icône
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      "Je participe",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),

              // Effet Shimmer (Brillance qui passe)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      widthFactor: 0.5,
                      alignment: Alignment(
                        -1.5 + (_shimmerController.value * 3),
                        0,
                      ), // De gauche à droite
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
