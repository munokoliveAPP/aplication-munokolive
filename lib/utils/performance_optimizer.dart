import 'package:flutter/material.dart';

/// Utilitaires pour optimiser les performances de l'application
class PerformanceOptimizer {
  /// Créer un RepaintBoundary pour isoler les repaints
  static Widget wrapWithRepaintBoundary(Widget child, {String? debugLabel}) {
    return RepaintBoundary(
      child: child,
      // debugLabel is useful for performance debugging
    );
  }

  /// Créer un widget const optimisé
  static Widget constWidget(Widget child) {
    return child;
  }

  /// Debounce helper pour éviter trop d'appels
  static Duration debounceDelay = const Duration(milliseconds: 300);
}

/// Mixin pour optimiser les rebuilds
mixin OptimizedRebuild {
  bool _shouldRebuild = true;

  void markForRebuild() {
    _shouldRebuild = true;
  }

  void markRebuilt() {
    _shouldRebuild = false;
  }

  bool get shouldRebuild => _shouldRebuild;
}
