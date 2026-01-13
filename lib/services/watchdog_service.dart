import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class WatchdogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static final Map<String, dynamic> _crashContext = {};
  static final Stopwatch _uptime = Stopwatch()..start();

  static void init() {
    // Setup global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _reportCrash(details.exception, details.stack, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _reportCrash(error, stack, fatal: true);
      return true;
    };

    _checkHealth();
  }

  static void reportError(
    dynamic error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    _reportCrash(error, stack, fatal: fatal);
  }

  static void setContext(String key, dynamic value) {
    _crashContext[key] = value;
  }

  static void logMetric(String name, int durationMs) {
    // Silent logging of performance metrics
    // In production, this would go to Firebase Performance or custom backend
    if (durationMs > 100) {
      // Only log slow operations
      _logToDisk('[METRIC] $name took ${durationMs}ms');
    }
  }

  static void _reportCrash(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    final contextString = _crashContext.toString();

    _logger.e(
      "CRASH REPORT (Fatal: $fatal)\nContext: $contextString",
      error: error,
      stackTrace: stack,
    );

    _logToDisk('''
CRASH REPORT
Time: ${DateTime.now()}
Fatal: $fatal
Error: $error
Stack: $stack
Context: $contextString
Uptime: ${_uptime.elapsed}
--------------------------
''');
  }

  static Future<void> _checkHealth() async {
    // 1. Check startup time (simulated)
    if (_uptime.elapsedMilliseconds > 3000) {
      logWarning(
        "Slow startup detected (${_uptime.elapsedMilliseconds}ms). Cleaning cache...",
      );
      _clearCache();
    }

    // 2. Check disk space (optional, skipping for now)
  }

  static Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      logInfo("Cache cleared successfully (Self-Healing).");
    } catch (e) {
      logWarning("Failed to clear cache: $e");
    }
  }

  static Future<void> _logToDisk(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/app_logs.txt');
      await file.writeAsString(
        '${DateTime.now()}: $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint("Failed to write log to disk: $e");
    }
  }

  static void logInfo(String message) {
    _logger.i(message);
  }

  static void logWarning(String message) {
    _logger.w(message);
  }
}
