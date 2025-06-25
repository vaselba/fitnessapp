import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void log(String message,
      {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    final prefix = _levelPrefix(level);
    final logMsg = '[$prefix] $message';
    if (kDebugMode) {
      // Print to console in debug mode
      if (error != null) {
        debugPrint('$logMsg\nError: $error');
      } else {
        debugPrint(logMsg);
      }
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
    // TODO: Add integration with remote logging/analytics if needed
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
