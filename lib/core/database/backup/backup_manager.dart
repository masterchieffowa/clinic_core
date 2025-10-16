import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive_io.dart';
import '../../config/app_config.dart';
import '../../utils/logger_util.dart';
import '../../utils/date_util.dart';
import '../sqlite/database_helper.dart';

class BackupManager {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<String> getBackupDirectory() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String backupPath = path.join(
      documentsDirectory.path,
      'OneMinuteClinic',
      AppConfig.backupFolderName,
    );

    final Directory backupDir = Directory(backupPath);
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupPath;
  }

  Future<File> createBackup({String? customName}) async {
    try {
      LoggerUtil.info('Starting database backup...');

      final String backupDir = await getBackupDirectory();
      final String timestamp = DateUtil.formatForFilename(DateTime.now());
      final String backupName = customName ?? 'backup_$timestamp';

      // Create temporary directory for backup files
      final String tempDir = path.join(backupDir, 'temp_$timestamp');
      await Directory(tempDir).create(recursive: true);

      // Export database to JSON
      final Map<String, dynamic> exportData = await _exportDatabase();

      // Write JSON file
      final File jsonFile = File(path.join(tempDir, 'database.json'));
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      // Copy QMRA files if they exist
      await _copyQMRAFiles(tempDir);

      // Create metadata file
      final Map<String, dynamic> metadata = {
        'version': AppConfig.appVersion,
        'databaseVersion': AppConfig.databaseVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'totalRecords': _calculateTotalRecords(exportData),
      };

      final File metadataFile = File(path.join(tempDir, 'metadata.json'));
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(metadata),
      );

      // Compress to zip file
      final String zipPath = path.join(backupDir, '$backupName.zip');
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addDirectory(Directory(tempDir));
      encoder.close();

      // Clean up temporary directory
      await Directory(tempDir).delete(recursive: true);

      // Clean old backups
      await _cleanOldBackups(backupDir);

      LoggerUtil.info('Backup completed successfully: $zipPath');
      return File(zipPath);
    } catch (e) {
      LoggerUtil.error('Error creating backup: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _exportDatabase() async {
    final Database db = await _databaseHelper.database;

    final Map<String, dynamic> exportData = {
      'users': await db.query('users'),
      'patients': await db.query('patients'),
      'medical_records': await db.query('medical_records'),
      'appointments': await db.query('appointments'),
      'qmra_tests': await db.query('qmra_tests'),
      'bills': await db.query('bills'),
      'medical_representatives': await db.query('medical_representatives'),
      'settings': await db.query('settings'),
    };

    return exportData;
  }

  Future<void> _copyQMRAFiles(String tempDir) async {
    try {
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String qmraSourcePath = path.join(
        documentsDirectory.path,
        'OneMinuteClinic',
        AppConfig.qmraResultFolder,
      );

      final Directory qmraSourceDir = Directory(qmraSourcePath);
      if (await qmraSourceDir.exists()) {
        final String qmraDestPath = path.join(tempDir, 'qmra_files');
        await Directory(qmraDestPath).create(recursive: true);

        await for (final entity in qmraSourceDir.list()) {
          if (entity is File) {
            final String fileName = path.basename(entity.path);
            await entity.copy(path.join(qmraDestPath, fileName));
          }
        }

        LoggerUtil.info('QMRA files copied to backup');
      }
    } catch (e) {
      LoggerUtil.warning('Error copying QMRA files: $e');
    }
  }

  int _calculateTotalRecords(Map<String, dynamic> data) {
    int total = 0;
    data.forEach((key, value) {
      if (value is List) {
        total += value.length;
      }
    });
    return total;
  }

  Future<void> _cleanOldBackups(String backupDir) async {
    try {
      final Directory dir = Directory(backupDir);
      final List<FileSystemEntity> files = dir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.zip'))
          .toList();

      if (files.length > AppConfig.maxBackupFiles) {
        // Sort by modification time
        files.sort((a, b) => (a as File)
            .lastModifiedSync()
            .compareTo((b as File).lastModifiedSync()));

        // Delete oldest files
        final int toDelete = files.length - AppConfig.maxBackupFiles;
        for (int i = 0; i < toDelete; i++) {
          await files[i].delete();
          LoggerUtil.info(
              'Deleted old backup: ${path.basename(files[i].path)}');
        }
      }
    } catch (e) {
      LoggerUtil.error('Error cleaning old backups: $e');
    }
  }

  Future<void> restoreBackup(String backupFilePath) async {
    try {
      LoggerUtil.info('Starting database restore from: $backupFilePath');

      final File backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      // Create temporary directory for extraction
      final String backupDir = await getBackupDirectory();
      final String timestamp = DateUtil.formatForFilename(DateTime.now());
      final String tempDir = path.join(backupDir, 'restore_temp_$timestamp');
      await Directory(tempDir).create(recursive: true);

      // Extract zip file
      final bytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final extractedFile = File(path.join(tempDir, filename));
          await extractedFile.create(recursive: true);
          await extractedFile.writeAsBytes(data);
        }
      }

      // Read and validate metadata
      final File metadataFile = File(path.join(tempDir, 'metadata.json'));
      if (!await metadataFile.exists()) {
        throw Exception('Invalid backup file: metadata not found');
      }

      final String metadataContent = await metadataFile.readAsString();
      final Map<String, dynamic> metadata = json.decode(metadataContent);

      LoggerUtil.info('Restoring backup from: ${metadata['timestamp']}');

      // Read database JSON
      final File jsonFile = File(path.join(tempDir, 'database.json'));
      if (!await jsonFile.exists()) {
        throw Exception('Invalid backup file: database.json not found');
      }

      final String jsonContent = await jsonFile.readAsString();
      final Map<String, dynamic> data = json.decode(jsonContent);

      // Close current database
      await _databaseHelper.closeDatabase();

      // Restore data
      await _importDatabase(data);

      // Restore QMRA files
      await _restoreQMRAFiles(tempDir);

      // Clean up temporary directory
      await Directory(tempDir).delete(recursive: true);

      LoggerUtil.info('Database restored successfully');
    } catch (e) {
      LoggerUtil.error('Error restoring backup: $e');
      rethrow;
    }
  }

  Future<void> _importDatabase(Map<String, dynamic> data) async {
    final Database db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('audit_log');
      await txn.delete('bills');
      await txn.delete('qmra_tests');
      await txn.delete('medical_records');
      await txn.delete('appointments');
      await txn.delete('patients');
      await txn.delete('medical_representatives');
      await txn.delete('settings');
      await txn.delete('users');

      // Import data
      for (final user in data['users'] as List) {
        await txn.insert('users', user as Map<String, dynamic>);
      }

      for (final patient in data['patients'] as List) {
        await txn.insert('patients', patient as Map<String, dynamic>);
      }

      for (final record in data['medical_records'] as List) {
        await txn.insert('medical_records', record as Map<String, dynamic>);
      }

      for (final appointment in data['appointments'] as List) {
        await txn.insert('appointments', appointment as Map<String, dynamic>);
      }

      for (final test in data['qmra_tests'] as List) {
        await txn.insert('qmra_tests', test as Map<String, dynamic>);
      }

      for (final bill in data['bills'] as List) {
        await txn.insert('bills', bill as Map<String, dynamic>);
      }

      for (final rep in data['medical_representatives'] as List) {
        await txn.insert(
            'medical_representatives', rep as Map<String, dynamic>);
      }

      for (final setting in data['settings'] as List) {
        await txn.insert('settings', setting as Map<String, dynamic>);
      }
    });
  }

  Future<void> _restoreQMRAFiles(String tempDir) async {
    try {
      final String qmraSourcePath = path.join(tempDir, 'qmra_files');
      final Directory qmraSourceDir = Directory(qmraSourcePath);

      if (await qmraSourceDir.exists()) {
        final Directory documentsDirectory =
            await getApplicationDocumentsDirectory();
        final String qmraDestPath = path.join(
          documentsDirectory.path,
          'OneMinuteClinic',
          AppConfig.qmraResultFolder,
        );

        final Directory qmraDestDir = Directory(qmraDestPath);
        if (!await qmraDestDir.exists()) {
          await qmraDestDir.create(recursive: true);
        }

        await for (final entity in qmraSourceDir.list()) {
          if (entity is File) {
            final String fileName = path.basename(entity.path);
            await entity.copy(path.join(qmraDestPath, fileName));
          }
        }

        LoggerUtil.info('QMRA files restored');
      }
    } catch (e) {
      LoggerUtil.warning('Error restoring QMRA files: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final String backupDir = await getBackupDirectory();
      final Directory dir = Directory(backupDir);

      if (!await dir.exists()) {
        return [];
      }

      final List<Map<String, dynamic>> backups = [];

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          final FileStat stats = await entity.stat();
          final String fileName = path.basenameWithoutExtension(entity.path);

          backups.add({
            'name': fileName,
            'path': entity.path,
            'size': stats.size,
            'date': stats.modified,
          });
        }
      }

      // Sort by date (newest first)
      backups.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return backups;
    } catch (e) {
      LoggerUtil.error('Error getting backup list: $e');
      return [];
    }
  }

  Future<void> deleteBackup(String backupPath) async {
    try {
      final File backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
        LoggerUtil.info('Backup deleted: $backupPath');
      }
    } catch (e) {
      LoggerUtil.error('Error deleting backup: $e');
      rethrow;
    }
  }
}
