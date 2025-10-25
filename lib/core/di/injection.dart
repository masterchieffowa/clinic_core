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

import 'package:clinic_core/features/patient/data/datasources/patient_local_datasource.dart';
import 'package:get_it/get_it.dart';
import '../database/sqlite/database_helper.dart';
import '../database/encryption/encryption_service.dart';
import '../database/backup/backup_manager.dart';
import '../database/backup/auto_backup_service.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';

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

  getIt.registerLazySingleton<PatientLocalDataSource>(
    () => PatientLocalDataSource(
      databaseHelper: getIt<DatabaseHelper>(),
    ),
  );
}
