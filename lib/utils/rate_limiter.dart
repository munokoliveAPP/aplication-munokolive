import 'dart:collection';

class RateLimiter {
  final int maxRequests;
  final Duration duration;
  final Queue<DateTime> _timestamps = Queue();

  RateLimiter({
    this.maxRequests = 5,
    this.duration = const Duration(seconds: 10),
  });

  bool canRequest() {
    final now = DateTime.now();

    // Remove old timestamps
    while (_timestamps.isNotEmpty &&
        now.difference(_timestamps.first) > duration) {
      _timestamps.removeFirst();
    }

    if (_timestamps.length < maxRequests) {
      _timestamps.add(now);
      return true;
    }

    return false;
  }
}
