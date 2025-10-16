import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../config/app_config.dart';
import '../../utils/logger_util.dart';
import 'tables/database_tables.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // ✅ IMPORTANT: Initialize sqflite_ffi for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Initialize FFI
        sqfliteFfiInit();
        // Set the database factory for desktop
        databaseFactory = databaseFactoryFfi;
        LoggerUtil.info('✅ Initialized sqflite_ffi for desktop platform');
      }

      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      final String path = join(
        documentsDirectory.path,
        'OneMinuteClinic',
        'Database',
        AppConfig.sqliteDatabaseName,
      );

      // Create directory if it doesn't exist
      final Directory dbDirectory = Directory(dirname(path));
      if (!await dbDirectory.exists()) {
        await dbDirectory.create(recursive: true);
      }

      LoggerUtil.info('Initializing SQLite database at: $path');

      return await openDatabase(
        path,
        version: AppConfig.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      LoggerUtil.error('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LoggerUtil.info('Upgrading database from v$oldVersion to v$newVersion');
    // Handle migrations here
  }

  Future<void> _createTables(Database db) async {
    final Batch batch = db.batch();

    // Users Table
    batch.execute(DatabaseTables.createUsersTable);

    // Patients Table
    batch.execute(DatabaseTables.createPatientsTable);

    // Medical Records Table
    batch.execute(DatabaseTables.createMedicalRecordsTable);

    // Appointments Table
    batch.execute(DatabaseTables.createAppointmentsTable);

    // QMRA Tests Table
    batch.execute(DatabaseTables.createQMRATestsTable);

    // Bills Table
    batch.execute(DatabaseTables.createBillsTable);

    // Medical Representatives Table
    batch.execute(DatabaseTables.createMedicalRepsTable);

    // Settings Table
    batch.execute(DatabaseTables.createSettingsTable);

    // Audit Log Table
    batch.execute(DatabaseTables.createAuditLogTable);

    await batch.commit(noResult: true);
    LoggerUtil.info('✅ Database tables created successfully');
  }

  Future<void> closeDatabase() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      LoggerUtil.info('Database closed');
    }
  }

  Future<void> deleteDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(
      documentsDirectory.path,
      'OneMinuteClinic',
      'Database',
      AppConfig.sqliteDatabaseName,
    );

    await closeDatabase();
    final File dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
      LoggerUtil.info('Database deleted');
    }
  }
}
