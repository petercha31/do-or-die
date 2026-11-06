import 'package:flutter/foundation.dart';

void logSyncDebug(String message) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('[sync] $message');
}

void logSyncError(String context, Object error, [StackTrace? stackTrace]) {
  if (!kDebugMode) {
    return;
  }
  debugPrint('[sync] $context: $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace, label: '[sync]');
  }
}
