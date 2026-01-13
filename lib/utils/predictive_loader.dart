import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// A mixin to detect when a user "dwells" on a widget for a certain duration.
/// Useful for predictive loading.
mixin PredictiveLoader<T extends StatefulWidget> on State<T> {
  Timer? _dwellTimer;
  final Duration _dwellThreshold = const Duration(seconds: 2);

  /// Override this to define what to preload.
  void onPredictiveLoad();

  void startDwellTracking() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(_dwellThreshold, () {
      onPredictiveLoad();
    });
  }

  void cancelDwellTracking() {
    _dwellTimer?.cancel();
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }
}

/// A widget wrapper for easy use in Lists/Grids
class PredictiveWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onPredictiveLoad;
  final Duration threshold;
  final String id; // Unique ID for VisibilityDetector

  const PredictiveWrapper({
    super.key,
    required this.child,
    required this.onPredictiveLoad,
    required this.id,
    this.threshold = const Duration(seconds: 2),
  });

  @override
  State<PredictiveWrapper> createState() => _PredictiveWrapperState();
}

class _PredictiveWrapperState extends State<PredictiveWrapper> {
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.id),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.8) {
          // Item is mostly visible, start timer
          _startTimer();
        } else {
          // Scrolled away, cancel
          _cancelTimer();
        }
      },
      child: widget.child,
    );
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer(widget.threshold, () {
      widget.onPredictiveLoad();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
