import 'package:clinic_core/core/database/hive/models/hive_service.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../../../core/database/encryption/encryption_service.dart';
import '../../../../core/utils/logger_util.dart';
import '../models/user_model.dart';

class AuthLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final EncryptionService _encryptionService;

  AuthLocalDataSource({
    required DatabaseHelper databaseHelper,
    required EncryptionService encryptionService,
  })  : _databaseHelper = databaseHelper,
        _encryptionService = encryptionService;

  // Login - verify credentials
  Future<UserModel?> login(String username, String password) async {
    try {
      final Database db = await _databaseHelper.database;

      // Get user by username
      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
      );

      if (results.isEmpty) {
        LoggerUtil.warning('User not found: $username');
        return null;
      }

      final Map<String, dynamic> userMap = results.first;
      final String storedPasswordHash = userMap['password_hash'] as String;

      // Verify password
      final bool isPasswordValid = _encryptionService.verifyPassword(
        password,
        storedPasswordHash,
      );

      if (!isPasswordValid) {
        LoggerUtil.warning('Invalid password for user: $username');
        return null;
      }

      LoggerUtil.info('User logged in successfully: $username');
      return UserModel.fromJson(userMap);
    } catch (e) {
      LoggerUtil.error('Error during login: $e');
      return null;
    }
  }

  // Save session to Hive (for fast access)
  Future<void> saveSession(UserModel user) async {
    try {
      await HiveService.saveSetting('current_user', user.toJsonString());
      await HiveService.saveSetting(
        'session_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      LoggerUtil.info('Session saved for user: ${user.username}');
    } catch (e) {
      LoggerUtil.error('Error saving session: $e');
      rethrow;
    }
  }

  // Get current user from session
  Future<UserModel?> getCurrentUser() async {
    try {
      final String? userJson = HiveService.getSetting<String>('current_user');
      if (userJson == null) return null;

      return UserModel.fromJsonString(userJson);
    } catch (e) {
      LoggerUtil.error('Error getting current user: $e');
      return null;
    }
  }

  // Clear session
  Future<void> clearSession() async {
    try {
      await HiveService.saveSetting('current_user', null);
      await HiveService.saveSetting('session_timestamp', null);
      LoggerUtil.info('Session cleared');
    } catch (e) {
      LoggerUtil.error('Error clearing session: $e');
      rethrow;
    }
  }

  // Validate session (check if not expired)
  Future<bool> validateSession() async {
    try {
      final int? sessionTimestamp =
          HiveService.getSetting<int>('session_timestamp');
      if (sessionTimestamp == null) return false;

      final DateTime sessionTime =
          DateTime.fromMillisecondsSinceEpoch(sessionTimestamp);
      final Duration difference = DateTime.now().difference(sessionTime);

      // Session timeout: 30 minutes
      const int timeoutMinutes = 30;
      final bool isValid = difference.inMinutes < timeoutMinutes;

      if (!isValid) {
        LoggerUtil.warning('Session expired');
        await clearSession();
      }

      return isValid;
    } catch (e) {
      LoggerUtil.error('Error validating session: $e');
      return false;
    }
  }

  // Create default admin user (for first run)
  Future<void> createDefaultAdmin() async {
    try {
      final Database db = await _databaseHelper.database;

      // Check if admin already exists
      final List<Map<String, dynamic>> existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (existing.isNotEmpty) {
        LoggerUtil.info('Default admin already exists');
        return;
      }

      // Create default admin
      final String passwordHash = _encryptionService.hashPassword('admin123');
      final DateTime now = DateTime.now();

      final Map<String, dynamic> adminUser = {
        'user_id': 'admin-001',
        'username': 'admin',
        'email': 'admin@oneminuteclinic.com',
        'password_hash': passwordHash,
        'role': 'admin',
        'name': 'System Administrator',
        'phone': null,
        'address': null,
        'national_id': null,
        'salary': null,
        'is_active': 1,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      await db.insert('users', adminUser);
      LoggerUtil.info(
        '✅ Default admin user created (username: admin, password: admin123)',
      );
    } catch (e) {
      LoggerUtil.error('Error creating default admin: $e');
    }
  }
}
