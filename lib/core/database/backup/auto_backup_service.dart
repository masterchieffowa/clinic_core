import 'dart:async';
import '../../config/app_config.dart';
import '../../utils/logger_util.dart';
import 'backup_manager.dart';

class AutoBackupService {
  static AutoBackupService? _instance;
  Timer? _timer;
  final BackupManager _backupManager = BackupManager();

  AutoBackupService._();

  factory AutoBackupService() {
    _instance ??= AutoBackupService._();
    return _instance!;
  }

  void start() {
    if (_timer != null && _timer!.isActive) {
      LoggerUtil.warning('Auto backup service is already running');
      return;
    }

    final Duration interval = Duration(
      hours: AppConfig.autoBackupIntervalHours,
    );

    _timer = Timer.periodic(interval, (timer) async {
      try {
        LoggerUtil.info('Auto backup triggered');
        await _backupManager.createBackup(
          customName: 'auto_backup_${DateTime.now().millisecondsSinceEpoch}',
        );
        LoggerUtil.info('Auto backup completed successfully');
      } catch (e) {
        LoggerUtil.error('Auto backup failed: $e');
      }
    });

    LoggerUtil.info(
        'Auto backup service started (interval: ${AppConfig.autoBackupIntervalHours}h)');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    LoggerUtil.info('Auto backup service stopped');
  }

  bool get isRunning => _timer != null && _timer!.isActive;
}
