import 'package:logger/logger.dart';
import '../config/app_config.dart';

class LoggerUtil {
  static Logger? _logger;

  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: AppConfig.enableDebugMode ? Level.debug : Level.info,
    );
  }

  static void debug(String message) {
    if (AppConfig.enableLogging) {
      _logger?.d(message);
    }
  }

  static void info(String message) {
    if (AppConfig.enableLogging) {
      _logger?.i(message);
    }
  }

  static void warning(String message) {
    if (AppConfig.enableLogging) {
      _logger?.w(message);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.enableLogging) {
      _logger?.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
