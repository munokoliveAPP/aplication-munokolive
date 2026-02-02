import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SOSRadialButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const SOSRadialButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<SOSRadialButton> createState() => _SOSRadialButtonState();
}

class _SOSRadialButtonState extends State<SOSRadialButton>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Neon colors from the theme
    const neonPink = Color(0xFFFF00FF);
    const neonPurple = Color(0xFF8A2BE2);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 + (_controller.value * 0.1); // Scale 1.0 to 1.1
          final blur = 10.0 + (_controller.value * 10.0); // Blur 10 to 20

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [neonPink, neonPurple],
                ),
                boxShadow: [
                  // Layer 1: Inner Glow
                  BoxShadow(
                    color: neonPink.withValues(alpha: 0.5),
                    blurRadius: blur,
                    spreadRadius: 2,
                  ),
                  // Layer 2: Outer Glow
                  BoxShadow(
                    color: neonPurple.withValues(alpha: 0.3),
                    blurRadius: blur * 1.5,
                    spreadRadius: 5,
                  ),
                  // Layer 3: Ambient Glow
                  BoxShadow(
                    color: neonPink.withValues(alpha: 0.1),
                    blurRadius: blur * 2,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(
                        Icons.emergency_share,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
          );
        },
      ),
    ));
  }
}
