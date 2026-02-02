/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/foundation.dart';

class WatchdogService {
  static void init() {
    // Initialize crash reporting (e.g., Firebase Crashlytics)
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(details.exception, details.stack);
    };
  }

  static void reportError(Object error, StackTrace? stack) {
    if (kDebugMode) {
      print('Watchdog Caught Error: $error');
      if (stack != null) print(stack);
    }
    // In production, send to Crashlytics
  }
}
