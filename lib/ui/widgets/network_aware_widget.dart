import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:munokolive_music/ui/widgets/glass_container.dart';

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;
  final bool onlineOnly;
  final String? offlineTitle;
  final String? offlineSubtitle;
  final VoidCallback? onReconnected;

  final Future<void> Function()? onRefresh;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.onlineOnly = false,
    this.offlineTitle,
    this.offlineSubtitle,
    this.onReconnected,
    this.onRefresh,
  });

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget>
    with TickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Reconnection Animation (Radial Reveal)
  late AnimationController _reconnectionController;
  late Animation<double> _reconnectionAnimation;

  @override
  void initState() {
    super.initState();

    // Initial check
    _checkConnectivity();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });

    // Pulsing Animation for WiFi Icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Reconnection Animation
    _reconnectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _reconnectionAnimation = CurvedAnimation(
      parent: _reconnectionController,
      curve: Curves.easeOutExpo,
    );
  }

  void _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    final isNowOffline = results.contains(ConnectivityResult.none);

    if (_isOffline && !isNowOffline) {
      // Transition Offline -> Online
      _reconnectionController.forward(from: 0.0);
      widget.onReconnected?.call();
    }

    setState(() {
      _isOffline = isNowOffline;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _pulseController.dispose();
    _reconnectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          // Custom Cyberpunk Refresh Logic
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // Simulate process
          if (!context.mounted) return;
          if (_isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Pas de réseau. Impossible de rafraîchir."),
                backgroundColor: Colors.orangeAccent,
              ),
            );
            return;
          }
          await widget.onRefresh!();
        }
      },
      color: Colors.cyanAccent, // Cyberpunk Cyan
      backgroundColor: Colors.black,
      strokeWidth: 3,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: Stack(
        children: [
          // 1. Fallback for the "Grey" background during animation
          // Must be BEHIND the revealing layer
          if (!_isOffline && _reconnectionController.isAnimating)
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: widget.child,
              ),
            ),

          // 2. Main Content (With Reveal Animation)
          AnimatedBuilder(
            animation: _reconnectionAnimation,
            builder: (context, child) {
              // Si on est en train de se reconnecter (animation active) ou offline
              // On applique le filtre gris MAIS avec un masque radial qui s'ouvre
              if (_isOffline) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: widget.child,
                );
              } else if (_reconnectionController.isAnimating) {
                // Animation de "Merveille" : Recolorisation depuis le centre
                return ShaderMask(
                  shaderCallback: (rect) {
                    return RadialGradient(
                      center: Alignment.center,
                      radius:
                          _reconnectionAnimation.value *
                          1.5, // S'étend jusqu'aux bords
                      colors: const [Colors.white, Colors.transparent],
                      stops: const [0.5, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: widget.child,
                );
              } else {
                return widget.child;
              }
            },
            child: widget.child,
          ),

          // 3. Reconnection Particle (Particule Lumineuse)
          if (!_isOffline && _reconnectionController.isAnimating)
            AnimatedBuilder(
              animation: _reconnectionAnimation,
              builder: (context, child) {
                // Une onde de choc lumineuse qui suit le rayon
                // Calcul approximatif du rayon en pixels (basé sur la largeur écran)
                final radius =
                    _reconnectionAnimation.value *
                    MediaQuery.of(context).size.longestSide;

                return Center(
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: (1.0 - _reconnectionAnimation.value).clamp(
                            0.0,
                            1.0,
                          ),
                        ),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 4. Offline Indicator (Non-blocking Banner)
          if (_isOffline)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GlassContainer(
                height: 70,
                borderRadius: 20,
                blur: 10,
                opacity: 0.1,
                color: Colors.black,
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    // Pulsing Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withValues(alpha: 0.2),
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.offlineTitle ?? "Mode Hors-Ligne",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.offlineSubtitle ?? "Accès au cache local",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
