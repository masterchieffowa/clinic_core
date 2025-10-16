import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../../../core/di/injection.dart';

// ============================================================================
// Dashboard Statistics Model
// ============================================================================

class DashboardStats {
  final int totalPatientsToday;
  final int totalPatientsInClinic;
  final int maxCapacity;
  final double todayIncome;
  final double lastWeekIncome;
  final int newCases;
  final int oldCases;
  final int totalDates;
  final List<Map<String, dynamic>> waitingPatients;
  final List<double> incomeLastWeek;

  DashboardStats({
    required this.totalPatientsToday,
    required this.totalPatientsInClinic,
    required this.maxCapacity,
    required this.todayIncome,
    required this.lastWeekIncome,
    required this.newCases,
    required this.oldCases,
    required this.totalDates,
    required this.waitingPatients,
    required this.incomeLastWeek,
  });

  double get capacityPercentage =>
      (totalPatientsInClinic / maxCapacity * 100).clamp(0, 100);
}

// ============================================================================
// Dashboard Data Source
// ============================================================================

class DashboardDataSource {
  final DatabaseHelper _databaseHelper;

  DashboardDataSource(this._databaseHelper);

  Future<DashboardStats> getDashboardStats() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    // Get total patients today
    final totalPatientsToday = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ?',
          [todayStart, todayEnd],
        )) ??
        0;

    // Get patients currently in clinic (waiting or in_progress)
    final totalPatientsInClinic = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM appointments WHERE appointment_date >= ? AND appointment_date <= ? AND status IN (?, ?)',
          [todayStart, todayEnd, 'waiting', 'in_progress'],
        )) ??
        0;

    // Get today's income
    final todayIncomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM bills WHERE created_at >= ? AND created_at <= ? AND status = ?',
      [todayStart, todayEnd, 'paid'],
    );
    final todayIncome =
        (todayIncomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get last week's income (for comparison)
    final lastWeekStart =
        DateTime(now.year, now.month, now.day - 7).millisecondsSinceEpoch;
    final lastWeekEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59)
        .millisecondsSinceEpoch;
    final lastWeekIncomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM bills WHERE created_at >= ? AND created_at <= ? AND status = ?',
      [lastWeekStart, lastWeekEnd, 'paid'],
    );
    final lastWeekIncome =
        (lastWeekIncomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get new cases (first visit patients)
    final newCases = Sqflite.firstIntValue(await db.rawQuery(
          '''
      SELECT COUNT(DISTINCT a.patient_id) 
      FROM appointments a 
      WHERE a.appointment_date >= ? AND a.appointment_date <= ?
      AND NOT EXISTS (
        SELECT 1 FROM medical_records mr 
        WHERE mr.patient_id = a.patient_id 
        AND mr.visit_date < a.appointment_date
      )
      ''',
          [todayStart, todayEnd],
        )) ??
        0;

    // Get old cases (returning patients)
    final oldCases = totalPatientsToday - newCases;

    // Get total dates (appointments for medical representatives)
    final totalDates = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM medical_representatives',
        )) ??
        0;

    // Get waiting patients list
    final waitingPatients = await db.rawQuery(
      '''
      SELECT 
        p.name,
        p.patient_id,
        a.appointment_time,
        a.status,
        a.arrival_time,
        a.priority
      FROM appointments a
      JOIN patients p ON a.patient_id = p.patient_id
      WHERE a.appointment_date >= ? AND a.appointment_date <= ?
      AND a.status IN ('scheduled', 'waiting', 'in_progress')
      ORDER BY a.priority_score DESC, a.arrival_time ASC
      LIMIT 10
      ''',
      [todayStart, todayEnd],
    );

    // Get income for last 7 days (for chart)
    final incomeLastWeek = <double>[];
    for (int i = 6; i >= 0; i--) {
      final dayStart =
          DateTime(now.year, now.month, now.day - i).millisecondsSinceEpoch;
      final dayEnd = DateTime(now.year, now.month, now.day - i, 23, 59, 59)
          .millisecondsSinceEpoch;
      final dayIncomeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM bills WHERE created_at >= ? AND created_at <= ? AND status = ?',
        [dayStart, dayEnd, 'paid'],
      );
      final dayIncome =
          (dayIncomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
      incomeLastWeek.add(dayIncome);
    }

    return DashboardStats(
      totalPatientsToday: totalPatientsToday,
      totalPatientsInClinic: totalPatientsInClinic,
      maxCapacity: 12, // TODO: Make this configurable
      todayIncome: todayIncome,
      lastWeekIncome: lastWeekIncome,
      newCases: newCases,
      oldCases: oldCases,
      totalDates: totalDates,
      waitingPatients: waitingPatients,
      incomeLastWeek: incomeLastWeek,
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

// Dashboard Data Source Provider
final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return DashboardDataSource(getIt<DatabaseHelper>());
});

// Dashboard Stats Provider (with auto-refresh)
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final dataSource = ref.read(dashboardDataSourceProvider);
  return await dataSource.getDashboardStats();
});

// Refresh Dashboard Provider
final refreshDashboardProvider = StateProvider<int>((ref) => 0);
