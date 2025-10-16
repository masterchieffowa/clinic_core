// // lib/core/local_database.dart -- old version
// import 'package:clinic_core/core/config/app_config.dart';
// import 'package:clinic_core/core/database/hive/boxes.dart';
// import 'package:clinic_core/core/database/sqlite/database_helper.dart';
// import 'package:clinic_core/core/utils/logger_util.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:path/path.dart' as path;
// import '../config/app_config.dart';
// import '../utils/logger_util.dart';
// import 'hive/boxes.dart';
// import 'hive/models/hive_user.dart';
// import 'hive/models/hive_patient.dart';
// import 'hive/models/hive_appointment.dart';
// import 'hive/models/hive_medical_record.dart';
// import 'hive/models/hive_qmra_test.dart';
// import 'hive/models/hive_bill.dart';
// import 'sqlite/database_helper.dart';
// import 'encryption/encryption_service.dart';
// import 'database/backup/auto_backup_service.dart';
// class LocalDatabase {
//   static bool _initialized = false;
//   static Future<void> init() async {
//     if (_initialized) {
//       LoggerUtil.warning('LocalDatabase already initialized');
//       return;
//     }
//     try {
//       LoggerUtil.info('Initializing LocalDatabase...');
//       // Initialize Hive
//       await _initHive();
//       // Initialize SQLite
//       await _initSQLite();
//       // Initialize Encryption
//       await _initEncryption();
//       // Start auto backup service
//       _startAutoBackup();
//       _initialized = true;
//       LoggerUtil.info('LocalDatabase initialized successfully');
//     } catch (e) {
//       LoggerUtil.error('Error initializing LocalDatabase: $e');
//       rethrow;
//     }
//   }
//   static Future<void> _initHive() async {
//     try {
//       // Get application documents directory
//       final Directory appDocDir = await getApplicationDocumentsDirectory();
//       final String hivePath = path.join(
//         appDocDir.path,
//         'OneMinuteClinic',
//         'Hive',
//       );
//       // Create directory if it doesn't exist
//       final Directory hiveDir = Directory(hivePath);
//       if (!await hiveDir.exists()) {
//         await hiveDir.create(recursive: true);
//       }
//       // Initialize Hive with path
//       await Hive.initFlutter(hivePath);
//       // Register adapters
//       if (!Hive.isAdapterRegistered(0)) {
//         Hive.registerAdapter(HiveUserAdapter());
//       }
//       if (!Hive.isAdapterRegistered(1)) {
//         Hive.registerAdapter(HivePatientAdapter());
//       }
//       if (!Hive.isAdapterRegistered(2)) {
//         Hive.registerAdapter(HiveAppointmentAdapter());
//       }
//       if (!Hive.isAdapterRegistered(3)) {
//         Hive.registerAdapter(HiveMedicalRecordAdapter());
//       }
//       if (!Hive.isAdapterRegistered(4)) {
//         Hive.registerAdapter(HiveQMRATestAdapter());
//       }
//       if (!Hive.isAdapterRegistered(5)) {
//         Hive.registerAdapter(HiveBillAdapter());
//       }
//       // Open all boxes
//       await HiveBoxes.openAllBoxes();
//       LoggerUtil.info('Hive initialized at: $hivePath');
//     } catch (e) {
//       LoggerUtil.error('Error initializing Hive: $e');
//       rethrow;
//     }
//   }
//   static Future<void> _initSQLite() async {
//     try {
//       final DatabaseHelper dbHelper = DatabaseHelper();
//       await dbHelper.database; // This will create/open the database
//       LoggerUtil.info('SQLite initialized successfully');
//     } catch (e) {
//       LoggerUtil.error('Error initializing SQLite: $e');
//       rethrow;
//     }
//   }
//   static Future<void> _initEncryption() async {
//     try {
//       if (AppConfig.useEncryption) {
//         final EncryptionService encryptionService = EncryptionService();
//         await encryptionService.initialize();
//         LoggerUtil.info('Encryption service initialized');
//       } else {
//         LoggerUtil.warning('Encryption is disabled in config');
//       }
//     } catch (e) {
//       LoggerUtil.error('Error initializing encryption: $e');
//       rethrow;
//     }
//   }
//   static void _startAutoBackup() {
//     try {
//       final AutoBackupService autoBackupService = AutoBackupService();
//       autoBackupService.start();
//       LoggerUtil.info('Auto backup service started');
//     } catch (e) {
//       LoggerUtil.error('Error starting auto backup service: $e');
//     }
//   }
//   static Future<void> dispose() async {
//     try {
//       // Stop auto backup
//       AutoBackupService().stop();
//       // Close Hive boxes
//       await HiveBoxes.closeAllBoxes();
//       // Close SQLite database
//       await DatabaseHelper().closeDatabase();
//       _initialized = false;
//       LoggerUtil.info('LocalDatabase disposed');
//     } catch (e) {
//       LoggerUtil.error('Error disposing LocalDatabase: $e');
//     }
//   }
//   static bool get isInitialized => _initialized;
// }

import 'package:clinic_core/core/config/app_config.dart';
import 'package:clinic_core/core/database/backup/auto_backup_service.dart';
import 'package:clinic_core/core/database/hive/models/hive_service.dart';
import 'package:clinic_core/core/database/sqlite/database_helper.dart';
import 'package:clinic_core/core/utils/logger_util.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'encryption/encryption_service.dart';

class LocalDatabase {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      LoggerUtil.warning('LocalDatabase already initialized');
      return;
    }

    try {
      LoggerUtil.info('Initializing LocalDatabase...');

      // Initialize Hive (using HiveService which handles everything)
      await _initHive();

      // Initialize SQLite
      await _initSQLite();

      // Initialize Encryption
      await _initEncryption();

      // Start auto backup service
      _startAutoBackup();

      _initialized = true;
      LoggerUtil.info('LocalDatabase initialized successfully');
    } catch (e) {
      LoggerUtil.error('Error initializing LocalDatabase: $e');
      rethrow;
    }
  }

  static Future<void> _initHive() async {
    try {
      // Get application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String hivePath = path.join(
        appDocDir.path,
        'OneMinuteClinic',
        'Hive',
      );

      // Create directory if it doesn't exist
      final Directory hiveDir = Directory(hivePath);
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
      }

      // Initialize Hive with path
      await Hive.initFlutter(hivePath);

      // Use HiveService to initialize (which opens boxes)
      await HiveService.init();

      LoggerUtil.info('Hive initialized at: $hivePath');
    } catch (e) {
      LoggerUtil.error('Error initializing Hive: $e');
      rethrow;
    }
  }

  static Future<void> _initSQLite() async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper();
      await dbHelper.database; // This will create/open the database
      LoggerUtil.info('SQLite initialized successfully');
    } catch (e) {
      LoggerUtil.error('Error initializing SQLite: $e');
      rethrow;
    }
  }

  static Future<void> _initEncryption() async {
    try {
      if (AppConfig.useEncryption) {
        final EncryptionService encryptionService = EncryptionService();
        await encryptionService.initialize();
        LoggerUtil.info('Encryption service initialized');
      } else {
        LoggerUtil.warning('Encryption is disabled in config');
      }
    } catch (e) {
      LoggerUtil.error('Error initializing encryption: $e');
      rethrow;
    }
  }

  static void _startAutoBackup() {
    try {
      final AutoBackupService autoBackupService = AutoBackupService();
      autoBackupService.start();
      LoggerUtil.info('Auto backup service started');
    } catch (e) {
      LoggerUtil.error('Error starting auto backup service: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      // Stop auto backup
      AutoBackupService().stop();

      // Close Hive boxes
      await Hive.close();

      // Close SQLite database
      await DatabaseHelper().closeDatabase();

      _initialized = false;
      LoggerUtil.info('LocalDatabase disposed');
    } catch (e) {
      LoggerUtil.error('Error disposing LocalDatabase: $e');
    }
  }

  static bool get isInitialized => _initialized;
}
