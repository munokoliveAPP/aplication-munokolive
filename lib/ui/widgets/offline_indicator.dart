import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/connectivity_provider.dart';

class OfflineIndicator extends ConsumerWidget {
  final Widget child;
  const OfflineIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch global connectivity status
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) {
      return child;
    }

    return Stack(
      children: [
        // Content in Grayscale
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: AbsorbPointer(
             // Optional: Disable interaction if desired? 
             // User said "navigation en gris", implying disabled?
             // But if we want them to see cache, they should be able to scroll.
             // "simplement la navigation en gris" -> maybe just visual.
             // I'll keep interaction enabled for scrolling, but maybe disable buttons?
             // Hard to disable buttons selectively.
             // I'll leave interaction ENABLED so they can read cached content.
             absorbing: false, 
             child: child,
          ),
        ),
        
        // Offline Message
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: SafeArea(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.black87,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "Mode Hors Ligne",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Connectez-vous pour une bonne expérience",
                            style: TextStyle(
                              color: Colors.white70,
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
          ),
        ),
      ],
    );
  }
}
