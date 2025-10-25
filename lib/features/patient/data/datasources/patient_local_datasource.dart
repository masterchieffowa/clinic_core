import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../../../core/database/hive/models/hive_service.dart';
import '../../../../core/database/hive/models/patient_model.dart'
    as hive_patient;
import '../../../../core/utils/logger_util.dart';
import '../../../../core/utils/date_util.dart';
import '../models/patient_model.dart';

class PatientLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  PatientLocalDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  // Create new patient
  Future<PatientModel> createPatient(PatientModel patient) async {
    try {
      final db = await _databaseHelper.database;

      // Generate ID if not provided
      final patientWithId = patient.patientId.isEmpty
          ? patient.copyWith(
              patientId: _uuid.v4(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : patient;

      // Insert into SQLite
      await db.insert('patients', patientWithId.toJson());

      // Cache in Hive for fast access
      await HiveService.savePatient(
        hive_patient.PatientModel.fromJson(patientWithId.toJson()),
      );

      LoggerUtil.info('Patient created: ${patientWithId.name}');
      return patientWithId;
    } catch (e) {
      LoggerUtil.error('Error creating patient: $e');
      rethrow;
    }
  }

  // Get all patients
  Future<List<PatientModel>> getAllPatients() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> results = await db.query(
        'patients',
        orderBy: 'name ASC',
      );

      return results.map((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      LoggerUtil.error('Error getting all patients: $e');
      rethrow;
    }
  }

  // Get patient by ID
  Future<PatientModel?> getPatientById(String patientId) async {
    try {
      // Try Hive first (faster)
      final cachedPatient = HiveService.getPatient(patientId);
      if (cachedPatient != null) {
        return PatientModel.fromJson(cachedPatient.toJson());
      }

      // Fallback to SQLite
      final db = await _databaseHelper.database;
      final results = await db.query(
        'patients',
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );

      if (results.isEmpty) return null;

      final patient = PatientModel.fromJson(results.first);

      // Update Hive cache
      await HiveService.savePatient(
        hive_patient.PatientModel.fromJson(patient.toJson()),
      );

      return patient;
    } catch (e) {
      LoggerUtil.error('Error getting patient by ID: $e');
      rethrow;
    }
  }

  // Search patients
  Future<List<PatientModel>> searchPatients(String query) async {
    try {
      final db = await _databaseHelper.database;
      final searchQuery = '%$query%';

      final results = await db.query(
        'patients',
        where: 'name LIKE ? OR phone LIKE ? OR national_id LIKE ?',
        whereArgs: [searchQuery, searchQuery, searchQuery],
        orderBy: 'name ASC',
      );

      return results.map((json) => PatientModel.fromJson(json)).toList();
    } catch (e) {
      LoggerUtil.error('Error searching patients: $e');
      rethrow;
    }
  }

  // Update patient
  Future<PatientModel> updatePatient(PatientModel patient) async {
    try {
      final db = await _databaseHelper.database;

      final updatedPatient = patient.copyWith(
        updatedAt: DateTime.now(),
      );

      await db.update(
        'patients',
        updatedPatient.toJson(),
        where: 'patient_id = ?',
        whereArgs: [patient.patientId],
      );

      // Update Hive cache
      await HiveService.savePatient(
        hive_patient.PatientModel.fromJson(updatedPatient.toJson()),
      );

      LoggerUtil.info('Patient updated: ${updatedPatient.name}');
      return updatedPatient;
    } catch (e) {
      LoggerUtil.error('Error updating patient: $e');
      rethrow;
    }
  }

  // Delete patient
  Future<void> deletePatient(String patientId) async {
    try {
      final db = await _databaseHelper.database;

      await db.delete(
        'patients',
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );

      // Remove from Hive cache
      final hiveBox = HiveService.getAllPatients();
      await Future.wait(
        hiveBox
            .where((p) => p.patientId == patientId)
            .map((p) => HiveService.savePatient(p)),
      );

      LoggerUtil.info('Patient deleted: $patientId');
    } catch (e) {
      LoggerUtil.error('Error deleting patient: $e');
      rethrow;
    }
  }

  // Get patient statistics
  Future<Map<String, int>> getPatientStats() async {
    try {
      final db = await _databaseHelper.database;

      final totalCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM patients'),
          ) ??
          0;

      final maleCount = Sqflite.firstIntValue(
            await db.rawQuery(
                "SELECT COUNT(*) FROM patients WHERE gender = 'male'"),
          ) ??
          0;

      final femaleCount = totalCount - maleCount;

      // Patients added this month
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59)
          .millisecondsSinceEpoch;

      final newThisMonth = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM patients WHERE created_at >= ? AND created_at <= ?',
              [monthStart, monthEnd],
            ),
          ) ??
          0;

      return {
        'total': totalCount,
        'male': maleCount,
        'female': femaleCount,
        'newThisMonth': newThisMonth,
      };
    } catch (e) {
      LoggerUtil.error('Error getting patient stats: $e');
      rethrow;
    }
  }
}
