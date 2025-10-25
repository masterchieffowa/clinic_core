import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../../../core/utils/logger_util.dart';
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

      // Check if national ID already exists (if provided)
      if (patientWithId.nationalId != null &&
          patientWithId.nationalId!.isNotEmpty) {
        final existing = await db.query(
          'patients',
          where: 'national_id = ?',
          whereArgs: [patientWithId.nationalId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          throw Exception('Patient with this national ID already exists');
        }
      }

      // Insert into SQLite
      await db.insert('patients', patientWithId.toJson());

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
      final db = await _databaseHelper.database;
      final results = await db.query(
        'patients',
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );

      if (results.isEmpty) return null;

      return PatientModel.fromJson(results.first);
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

      // Check if national ID is being changed and if it already exists
      if (updatedPatient.nationalId != null &&
          updatedPatient.nationalId!.isNotEmpty) {
        final existing = await db.query(
          'patients',
          where: 'national_id = ? AND patient_id != ?',
          whereArgs: [updatedPatient.nationalId, patient.patientId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          throw Exception('Patient with this national ID already exists');
        }
      }

      await db.update(
        'patients',
        updatedPatient.toJson(),
        where: 'patient_id = ?',
        whereArgs: [patient.patientId],
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

  // Clear duplicate national IDs (utility function)
  Future<void> clearDuplicateNationalIds() async {
    try {
      final db = await _databaseHelper.database;

      // Get all patients with national IDs
      final patients = await db.query(
        'patients',
        where: 'national_id IS NOT NULL',
        orderBy: 'created_at ASC',
      );

      // Track seen national IDs
      final seenIds = <String>{};
      final duplicatePatientIds = <String>[];

      for (final patient in patients) {
        final nationalId = patient['national_id'] as String?;
        final patientId = patient['patient_id'] as String;

        if (nationalId != null && nationalId.isNotEmpty) {
          if (seenIds.contains(nationalId)) {
            duplicatePatientIds.add(patientId);
          } else {
            seenIds.add(nationalId);
          }
        }
      }

      // Set national_id to NULL for duplicates
      for (final patientId in duplicatePatientIds) {
        await db.update(
          'patients',
          {'national_id': null},
          where: 'patient_id = ?',
          whereArgs: [patientId],
        );
      }

      LoggerUtil.info(
          'Cleared ${duplicatePatientIds.length} duplicate national IDs');
    } catch (e) {
      LoggerUtil.error('Error clearing duplicate national IDs: $e');
      rethrow;
    }
  }
}
