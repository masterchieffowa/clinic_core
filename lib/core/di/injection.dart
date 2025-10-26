// //lib/core/di/injection.dart -- old version
// import 'package:clinic_core/core/encryption/encryption_service.dart';
// import 'package:get_it/get_it.dart';
// import '../database/sqlite/database_helper.dart';
// import '../database/encryption/encryption_service.dart';
// import '../database/backup/backup_manager.dart';
// import '../database/backup/auto_backup_service.dart';
// import '../../features/auth/data/repositories/auth_repository_impl.dart';
// import '../../features/auth/domain/repositories/auth_repository.dart';
// import '../../features/auth/domain/usecases/login_usecase.dart';
// import '../../features/auth/presentation/bloc/auth_bloc.dart';
// final GetIt getIt = GetIt.instance;
// Future<void> configureDependencies() async {
//   // Core Services
//   getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
//   getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
//   getIt.registerLazySingleton<BackupManager>(() => BackupManager());
//   getIt.registerLazySingleton<AutoBackupService>(() => AutoBackupService());
//   // Auth
//   getIt.registerLazySingleton<AuthRepository>(
//     () => AuthRepositoryImpl(
//       databaseHelper: getIt<DatabaseHelper>(),
//       encryptionService: getIt<EncryptionService>(),
//     ),a
//   );
//   getIt.registerLazySingleton<LoginUseCase>(
//     () => LoginUseCase(getIt<AuthRepository>()),
//   );
//   getIt.registerFactory<AuthBloc>(
//     () => AuthBloc(loginUseCase: getIt<LoginUseCase>()),
//   );
//   // Add more dependencies as needed...
// }
// File Path: lib/core/di/injection.dart
// ✅ FINAL CONFIRMED VERSION - Use this exact content

// ============================================================================
// File: lib/core/di/injection.dart
// ✅ UPDATED: Added special patient entries for visitors and medical reps
// ============================================================================

import 'package:clinic_core/features/appointment/data/datasources/appointment_local_datasource.dart';
import 'package:clinic_core/features/patient/data/datasources/patient_local_datasource.dart';
import 'package:get_it/get_it.dart';
import '../database/sqlite/database_helper.dart';
import '../database/encryption/encryption_service.dart';
import '../database/backup/backup_manager.dart';
import '../database/backup/auto_backup_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../utils/logger_util.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core Services
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  getIt.registerLazySingleton<EncryptionService>(() => EncryptionService());
  getIt.registerLazySingleton<BackupManager>(() => BackupManager());
  getIt.registerLazySingleton<AutoBackupService>(() => AutoBackupService());

  // Auth Data Source
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(
      databaseHelper: getIt<DatabaseHelper>(),
      encryptionService: getIt<EncryptionService>(),
    ),
  );

  // Create default admin user (username: admin, password: admin123)
  await getIt<AuthLocalDataSource>().createDefaultAdmin();

  // Patient Data Source
  getIt.registerLazySingleton<PatientLocalDataSource>(
    () => PatientLocalDataSource(
      databaseHelper: getIt<DatabaseHelper>(),
    ),
  );

  // ✅ NEW: Appointment Data Source (needed for dashboard waiting list)
  getIt.registerLazySingleton<AppointmentLocalDataSource>(
    () => AppointmentLocalDataSource(
      databaseHelper: getIt<DatabaseHelper>(),
    ),
  );

  // ✅ NEW: Create special patient entries for visitors and medical reps
  await _createSpecialPatientEntries();
}

// ✅ NEW: Create special patient entries to support appointments without actual patients
Future<void> _createSpecialPatientEntries() async {
  try {
    final db = await getIt<DatabaseHelper>().database;
    final now = DateTime.now();

    // Check if visitor entry exists
    final visitorExists = await db.query(
      'patients',
      where: 'patient_id = ?',
      whereArgs: ['visitor'],
      limit: 1,
    );

    if (visitorExists.isEmpty) {
      await db.insert('patients', {
        'patient_id': 'visitor',
        'national_id': null,
        'name': 'Walk-in Visitor',
        'date_of_birth': DateTime(2000, 1, 1).millisecondsSinceEpoch,
        'age': 0,
        'gender': 'male',
        'phone': '0000000000',
        'email': null,
        'address': null,
        'blood_type': null,
        'chronic_diseases': null,
        'allergies': null,
        'emergency_contact_name': null,
        'emergency_contact_phone': null,
        'emergency_contact_relation': null,
        'profile_picture': null,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      LoggerUtil.info('✅ Created special "visitor" patient entry');
    }

    // Check if medical_rep entry exists
    final medRepExists = await db.query(
      'patients',
      where: 'patient_id = ?',
      whereArgs: ['medical_rep'],
      limit: 1,
    );

    if (medRepExists.isEmpty) {
      await db.insert('patients', {
        'patient_id': 'medical_rep',
        'national_id': null,
        'name': 'Medical Representative',
        'date_of_birth': DateTime(2000, 1, 1).millisecondsSinceEpoch,
        'age': 0,
        'gender': 'male',
        'phone': '0000000000',
        'email': null,
        'address': null,
        'blood_type': null,
        'chronic_diseases': null,
        'allergies': null,
        'emergency_contact_name': null,
        'emergency_contact_phone': null,
        'emergency_contact_relation': null,
        'profile_picture': null,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      LoggerUtil.info('✅ Created special "medical_rep" patient entry');
    }
  } catch (e) {
    LoggerUtil.error('Error creating special patient entries: $e');
    // Don't rethrow - this is not critical
  }
}
