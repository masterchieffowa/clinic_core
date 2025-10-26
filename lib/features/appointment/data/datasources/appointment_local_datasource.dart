import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../../../core/utils/logger_util.dart';
import '../models/appointment_model.dart';

class AppointmentLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  AppointmentLocalDataSource({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  // Create appointment
  Future<AppointmentModel> createAppointment(
      AppointmentModel appointment) async {
    try {
      final db = await _databaseHelper.database;

      final appointmentWithId = appointment.appointmentId.isEmpty
          ? appointment.copyWith(
              appointmentId: _uuid.v4(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : appointment;

      await db.insert('appointments', appointmentWithId.toJson());

      LoggerUtil.info(
          'Appointment created: ${appointmentWithId.appointmentId} for ${appointmentWithId.patientName}');
      return appointmentWithId;
    } catch (e) {
      LoggerUtil.error('Error creating appointment: $e');
      rethrow;
    }
  }

  // Get appointments for a specific date
  Future<List<AppointmentModel>> getAppointmentsByDate(DateTime date) async {
    try {
      final db = await _databaseHelper.database;
      final dayStart =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .millisecondsSinceEpoch;

      // ✅ UPDATED: Handle visitors and medical reps with LEFT JOIN
      final results = await db.rawQuery(
        '''
        SELECT 
          a.*,
          CASE 
            WHEN a.patient_id = 'visitor' THEN a.patient_id
            WHEN a.patient_id = 'medical_rep' THEN a.patient_id
            ELSE COALESCE(p.name, 'Unknown Patient')
          END as patient_name
        FROM appointments a
        LEFT JOIN patients p ON a.patient_id = p.patient_id
        WHERE a.appointment_date >= ? AND a.appointment_date <= ?
        ORDER BY a.appointment_time ASC
        ''',
        [dayStart, dayEnd],
      );

      return results.map((json) => AppointmentModel.fromJson(json)).toList();
    } catch (e) {
      LoggerUtil.error('Error getting appointments by date: $e');
      rethrow;
    }
  }

  // Get all appointments
  Future<List<AppointmentModel>> getAllAppointments() async {
    try {
      final db = await _databaseHelper.database;

      // ✅ UPDATED: Handle visitors and medical reps with LEFT JOIN
      final results = await db.rawQuery(
        '''
        SELECT 
          a.*,
          CASE 
            WHEN a.patient_id = 'visitor' THEN a.patient_id
            WHEN a.patient_id = 'medical_rep' THEN a.patient_id
            ELSE COALESCE(p.name, 'Unknown Patient')
          END as patient_name
        FROM appointments a
        LEFT JOIN patients p ON a.patient_id = p.patient_id
        ORDER BY a.appointment_date DESC, a.appointment_time ASC
        LIMIT 100
        ''',
      );

      return results.map((json) => AppointmentModel.fromJson(json)).toList();
    } catch (e) {
      LoggerUtil.error('Error getting all appointments: $e');
      rethrow;
    }
  }

  // Update appointment
  Future<AppointmentModel> updateAppointment(
      AppointmentModel appointment) async {
    try {
      final db = await _databaseHelper.database;

      final updated = appointment.copyWith(updatedAt: DateTime.now());

      await db.update(
        'appointments',
        updated.toJson(),
        where: 'appointment_id = ?',
        whereArgs: [appointment.appointmentId],
      );

      LoggerUtil.info('Appointment updated: ${updated.appointmentId}');
      return updated;
    } catch (e) {
      LoggerUtil.error('Error updating appointment: $e');
      rethrow;
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      final db = await _databaseHelper.database;

      await db.delete(
        'appointments',
        where: 'appointment_id = ?',
        whereArgs: [appointmentId],
      );

      LoggerUtil.info('Appointment deleted: $appointmentId');
    } catch (e) {
      LoggerUtil.error('Error deleting appointment: $e');
      rethrow;
    }
  }

  // Get appointment statistics
  Future<Map<String, int>> getAppointmentStats() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59)
          .millisecondsSinceEpoch;

      final todayTotal = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ?',
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      final todayCompleted = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND status = 'completed'",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      final todayWaiting = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND status IN ('scheduled', 'waiting')",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      final todayInProgress = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND status = 'in_progress'",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      return {
        'todayTotal': todayTotal,
        'todayCompleted': todayCompleted,
        'todayWaiting': todayWaiting,
        'todayInProgress': todayInProgress,
      };
    } catch (e) {
      LoggerUtil.error('Error getting appointment stats: $e');
      rethrow;
    }
  }

  //  NEW: Get appointments by type
  Future<Map<String, int>> getAppointmentsByType() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59)
          .millisecondsSinceEpoch;

      final patients = Sqflite.firstIntValue(
            await db.rawQuery(
              """SELECT COUNT(*) FROM appointments 
                 WHERE appointment_date >= ? AND appointment_date <= ? 
                 AND patient_id NOT IN ('visitor', 'medical_rep')""",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      final visitors = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND patient_id = 'visitor'",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      final medicalReps = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND patient_id = 'medical_rep'",
              [todayStart, todayEnd],
            ),
          ) ??
          0;

      return {
        'patients': patients,
        'visitors': visitors,
        'medicalReps': medicalReps,
      };
    } catch (e) {
      LoggerUtil.error('Error getting appointments by type: $e');
      rethrow;
    }
  }
}
