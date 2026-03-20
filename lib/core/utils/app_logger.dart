import 'package:logger/logger.dart';

/// Shared logger — use [AppLogger.instance] everywhere instead of [print].
class AppLogger {
  AppLogger._();

  static final Logger instance = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );
}
