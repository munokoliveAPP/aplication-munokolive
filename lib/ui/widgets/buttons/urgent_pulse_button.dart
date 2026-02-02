import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UrgentPulseButton extends StatefulWidget {
  final VoidCallback? onUrgentTap;
  final bool isAdmin;
  final bool isNewMember; // Added for special highlighting

  const UrgentPulseButton({
    super.key,
    this.onUrgentTap,
    this.isAdmin = false,
    this.isNewMember = false,
  });

  @override
  State<UrgentPulseButton> createState() => _UrgentPulseButtonState();
}

class _UrgentPulseButtonState extends State<UrgentPulseButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _glowController; // New controller for glow effect

  // State Management
  bool _isCoolingDown = false;
  Timer? _cooldownTimer;
  String _timerText = "";

  @override
  void initState() {
    super.initState();
    // Heartbeat Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Kinetic Ripple Animation (Right to Left)
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Glow Animation for New Members (Surprise!)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _checkCooldown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _glowController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeStr = prefs.getString('urgent_cooldown_end');

    if (endTimeStr != null) {
      final endTime = DateTime.parse(endTimeStr);
      if (endTime.isAfter(DateTime.now())) {
        _startCooldown(endTime);
      } else {
        await prefs.remove('urgent_cooldown_end');
      }
    }
  }

  void _startCooldown(DateTime endTime) {
    setState(() {
      _isCoolingDown = true;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(endTime)) {
        timer.cancel();
        setState(() => _isCoolingDown = false);
        SharedPreferences.getInstance().then(
          (p) => p.remove('urgent_cooldown_end'),
        );
      } else {
        final diff = endTime.difference(now);
        setState(() {
          _timerText =
              "${diff.inHours}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      }
    });
  }

  Future<void> _handleTap() async {
    HapticFeedback.heavyImpact();

    // Admin Bypass: No cooldown for super admins
    if (_isCoolingDown && !widget.isAdmin) {
      _showPatienceDialog();
      return;
    }

    // Trigger Action
    if (widget.onUrgentTap != null) {
      widget.onUrgentTap!();
    }

    // Start 3h Cooldown ONLY if not admin
    if (!widget.isAdmin) {
      final endTime = DateTime.now().add(const Duration(hours: 3));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('urgent_cooldown_end', endTime.toIso8601String());
      _startCooldown(endTime);
    }
  }

  void _showPatienceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          "Transmission en cours",
          style: GoogleFonts.oxanium(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Patience, votre appel est en cours de transmission.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            // Nouveau Widget de Secours (Lien Direct)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    "Besoin d'une assistance immédiate ?\nLe secrétariat est à votre écoute.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactButton(
                        icon: Icons.call,
                        color: Colors.green,
                        label: "Appel",
                        onTap: () => launchUrl(Uri.parse("tel:+2250777916407")),
                      ),
                      _buildContactButton(
                        icon: Icons.chat, // WhatsApp icon alternative
                        color: Colors.greenAccent,
                        label: "WhatsApp",
                        onTap: () =>
                            launchUrl(Uri.parse("https://wa.me/2250777916407")),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final mainColor = _isCoolingDown
        ? Colors.deepPurple
        : (widget.isNewMember
              ? const Color(0xFFFF4500)
              : const Color(0xFFFF0000)); // Orange-Red for new members
    final glowColor = _isCoolingDown
        ? Colors.purpleAccent
        : (widget.isNewMember ? Colors.orangeAccent : Colors.redAccent);

    // Dimensions
    const double buttonSize = 90.0;
    const double maxWaveSize = 180.0;

    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: maxWaveSize,
        height: maxWaveSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 0. NEW MEMBER NOVA EFFECT (Rotating Ring)
            if (widget.isNewMember && !_isCoolingDown)
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _glowController.value * 2 * math.pi,
                    child: Container(
                      width: maxWaveSize,
                      height: maxWaveSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            glowColor.withValues(alpha: 0.0),
                            glowColor.withValues(alpha: 0.5),
                            glowColor.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // 1. Concentric Pulse Waves (Expanding from Center)
            if (!_isCoolingDown)
              ...List.generate(4, (index) {
                return AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, child) {
                    final progress =
                        (_rippleController.value + (index * 0.25)) % 1.0;
                    final opacity = (1.0 - progress).clamp(0.0, 1.0);
                    final size =
                        buttonSize + (progress * (maxWaveSize - buttonSize));

                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mainColor.withValues(alpha: opacity * 0.5),
                          width: 2,
                        ),
                        color: mainColor.withValues(alpha: opacity * 0.1),
                      ),
                    );
                  },
                );
              }),

            // 2. Heartbeat Glow (Underneath)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: buttonSize * 0.8,
                    height: buttonSize * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.6),
                          blurRadius: widget.isNewMember
                              ? 40
                              : 30, // Stronger glow
                          spreadRadius: widget.isNewMember ? 8 : 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 3. Main Button Core
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [mainColor.withValues(alpha: 0.8), mainColor],
                  center: const Alignment(-0.2, -0.2), // Light source top-left
                  radius: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: _isCoolingDown
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_bottom,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timerText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.notifications_active, // Urgent/Bell Icon
                        color: Colors.white,
                        size: 36, // Slightly larger icon
                      ),
              ),
            ),

            // 4. Glossy Reflection (Top)
            Positioned(
              top:
                  (maxWaveSize - buttonSize) / 2 +
                  10, // Adjust for new container size
              left: (maxWaveSize - buttonSize) / 2 + 20,
              child: Container(
                width: 30,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.elliptical(30, 18),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
