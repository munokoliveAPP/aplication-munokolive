import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/services/ai_service.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets/glass_container.dart';

class MunoIABubble extends ConsumerStatefulWidget {
  const MunoIABubble({super.key});

  @override
  ConsumerState<MunoIABubble> createState() => _MunoIABubbleState();
}

class _MunoIABubbleState extends ConsumerState<MunoIABubble>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  String _displayedText = "";
  Timer? _typingTimer;
  Timer? _cycleTimer;
  bool _isLoading = false;

  final List<String> _staticTips = [
    "L'onction attire le talent, préparez votre cœur pour ce service.",
    "Un leader spirituel cherche d'abord à servir.",
    "La ponctualité est la politesse des rois et des musiciens.",
    "Soyez sensible à l'esprit pendant la louange.",
    "Votre talent est un don, votre caractère est un choix.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _startTypingCycle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _typingTimer?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _typingTimer?.cancel();
      _cycleTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTypingCycle();
    }
  }

  void _startTypingCycle() {
    _cycleTimer?.cancel(); // Ensure no double timer
    
    // Initial tip
    _fetchAndDisplayAdvice();

    // Cycle every 30 seconds to be less intrusive with AI calls, or mix with static
    _cycleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      _fetchAndDisplayAdvice();
    });
  }

  Future<void> _fetchAndDisplayAdvice() async {
    // 50% chance to use AI, 50% static to save quota and be fast
    // Or if loading, skip
    if (_isLoading) return;

    if (DateTime.now().second % 2 == 0) {
      setState(() => _isLoading = true);
      try {
        final advice = await ref.read(aiServiceProvider).getSpiritualAdvice("Encouragement musicien chrétien");
        if (mounted) _typeText(advice);
      } catch (e) {
        if (mounted) _typeText(_staticTips[DateTime.now().second % _staticTips.length]);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
       _typeText(_staticTips[DateTime.now().second % _staticTips.length]);
    }
  }

  void _typeText(String text) {
    _displayedText = "";
    int charIndex = 0;
    _typingTimer?.cancel();

    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (charIndex < text.length) {
        setState(() {
          _displayedText += text[charIndex];
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeController,
        child: GestureDetector(
          onTap: () {
            // Force refresh on tap
            _cycleTimer?.cancel();
            _fetchAndDisplayAdvice();
            // Restart cycle
            _cycleTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
              if (!mounted) return;
              _fetchAndDisplayAdvice();
            });
          },
          child: GlassContainer(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 20,
            blur: 15,
            opacity: 0.1,
            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
            border: Border.all(
              color: AppTheme.secondaryColor.withValues(alpha: 0.5),
              width: 1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayedText.isEmpty ? "Écoute du Saint-Esprit..." : _displayedText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
