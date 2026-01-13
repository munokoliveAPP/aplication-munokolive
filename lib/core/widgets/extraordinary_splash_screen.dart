import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExtraordinarySplashScreen extends StatefulWidget {
  const ExtraordinarySplashScreen({super.key});

  @override
  State<ExtraordinarySplashScreen> createState() =>
      _ExtraordinarySplashScreenState();
}

class _ExtraordinarySplashScreenState extends State<ExtraordinarySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particlesController;
  late AnimationController _rippleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Pulse animation (respiration du logo)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Rotation animation (anneau rotatif)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Particles animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Ripple animation (ondes concentriques)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Glow animation (pulsation de lumière)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Générer plus de particules pour un effet plus riche
    for (int i = 0; i < 50; i++) {
      _particles.add(_generateParticle());
    }
  }

  Particle _generateParticle() {
    return Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 2 + _random.nextDouble() * 4,
      speed: 0.3 + _random.nextDouble() * 0.5,
      opacity: 0.1 + _random.nextDouble() * 0.3,
      angle: _random.nextDouble() * 2 * math.pi,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particlesController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              AppTheme.background,
              AppTheme.surface,
              AppTheme.background,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Particules flottantes en arrière-plan (magenta/violet)
            AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlesPainter(
                    particles: _particles,
                    progress: _particlesController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Gradient animé en arrière-plan
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        AppTheme.accent.withValues(
                          alpha: _glowAnimation.value * 0.15,
                        ),
                        AppTheme.primary.withValues(
                          alpha: _glowAnimation.value * 0.1,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Ondes concentriques (ripples) avec couleurs du thème
            Center(
              child: AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: List.generate(4, (index) {
                      final delay = index * 0.25;
                      final progress = (_rippleController.value + delay) % 1.0;
                      final size = 150.0 + (progress * 400.0);
                      final opacity = (1.0 - progress) * 0.2;
                      final color = index % 2 == 0
                          ? AppTheme.accent
                          : AppTheme.primary;

                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(alpha: opacity),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: opacity * 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Logo principal avec animations
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pulseController,
                  _rotateController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value * _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Anneau rotatif externe avec gradient du thème
                          Transform.rotate(
                            angle: _rotateController.value * 2 * math.pi,
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppTheme.accent.withValues(
                                          alpha: 0.4 * _glowAnimation.value,
                                        ),
                                        AppTheme.primary.withValues(
                                          alpha: 0.7 * _glowAnimation.value,
                                        ),
                                        AppTheme.accent.withValues(
                                          alpha: 0.4 * _glowAnimation.value,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Anneau intermédiaire avec glow intense
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.6 + 0.4 * _glowAnimation.value,
                                    ),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(
                                        alpha: 0.5 * _glowAnimation.value,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.4 * _glowAnimation.value,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 15,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(
                                        alpha: 0.3 * _glowAnimation.value,
                                      ),
                                      blurRadius: 80,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Logo rond principal avec fond sombre et bordure lumineuse
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surface,
                              border: Border.all(
                                color: AppTheme.accent.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 5),
                                ),
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.4),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.music_note,
                                      color: AppTheme.accent,
                                      size: 70,
                                    ),
                              ),
                            ),
                          ),

                          // Point lumineux au centre (pulse) avec couleurs du thème
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _pulseController,
                              _glowController,
                            ]),
                            builder: (context, child) {
                              return Container(
                                width: 25 * _pulseAnimation.value,
                                height: 25 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.accent.withValues(
                                        alpha: 0.9 * _glowAnimation.value,
                                      ),
                                      AppTheme.primary.withValues(
                                        alpha: 0.6 * _glowAnimation.value,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withValues(
                                        alpha: 0.9 * _glowAnimation.value,
                                      ),
                                      blurRadius: 20 * _pulseAnimation.value,
                                      spreadRadius: 8 * _pulseAnimation.value,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.6 * _glowAnimation.value,
                                      ),
                                      blurRadius: 35 * _pulseAnimation.value,
                                      spreadRadius: 12 * _pulseAnimation.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Texte "MunokoLive" en bas avec animation fade-in
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'MunokoLive',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: AppTheme.accent.withValues(alpha: 0.8),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                              ),
                              Shadow(
                                color: AppTheme.primary.withValues(alpha: 0.6),
                                blurRadius: 30,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Gospel Music Community',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final double angle;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintAccent = Paint()..style = PaintingStyle.fill;
    final paintPrimary = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final particle = particles[i];
      // Mettre à jour la position
      final newX =
          (particle.x + math.cos(particle.angle) * particle.speed * progress) %
          1.0;
      final newY =
          (particle.y + math.sin(particle.angle) * particle.speed * progress) %
          1.0;

      // Alterner entre accent et primary pour un effet plus riche
      final isAccent = i % 2 == 0;
      final opacity =
          particle.opacity * (0.5 + 0.5 * math.sin(progress * 2 * math.pi + i));

      if (isAccent) {
        paintAccent.color = AppTheme.accent.withValues(alpha: opacity);
        canvas.drawCircle(
          Offset(newX * size.width, newY * size.height),
          particle.size,
          paintAccent,
        );
      } else {
        paintPrimary.color = AppTheme.primary.withValues(alpha: opacity);
        canvas.drawCircle(
          Offset(newX * size.width, newY * size.height),
          particle.size,
          paintPrimary,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
