#!/bin/sh

mkdir -p lib/core/config
mkdir -p lib/core/constants
mkdir -p lib/core/database/hive/models
mkdir -p lib/core/database/hive
mkdir -p lib/core/database/sqlite/tables
mkdir -p lib/core/database/sqlite/dao
mkdir -p lib/core/encryption
mkdir -p lib/core/backup
mkdir -p lib/core
mkdir -p lib/core/utils
mkdir -p lib/core/network
mkdir -p lib/core/di
mkdir -p lib/features/auth/data/models
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/repositories
mkdir -p lib/features/auth/domain/usecases
mkdir -p lib/features/auth/presentation/bloc
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets
mkdir -p lib/features/dashboard/presentation/pages
mkdir -p lib/features/dashboard/presentation/widgets
mkdir -p lib/features/patient
mkdir -p lib/features/appointment
mkdir -p lib/features/qmra
mkdir -p lib/features/medical_record
mkdir -p lib/shared/theme
mkdir -p lib/shared/widgets
mkdir -p lib/localization
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts
mkdir -p assets/translations
mkdir -p test/unit
mkdir -p test/widget
mkdir -p test/integration

touch lib/core/config/app_config.dart
touch lib/core/database/hive/models/hive_user.dart
touch lib/core/database/hive/models/hive_patient.dart
touch lib/core/database/hive/models/hive_appointment.dart
touch lib/core/database/hive/models/hive_medical_record.dart
touch lib/core/database/hive/models/hive_qmra_test.dart
touch lib/core/database/hive/models/hive_bill.dart
touch lib/core/database/hive/boxes.dart
touch lib/core/database/sqlite/tables/database_tables.dart
touch lib/core/database/sqlite/database_helper.dart
touch lib/core/encryption/encryption_service.dart
touch lib/core/backup/backup_manager.dart
touch lib/core/backup/auto_backup_service.dart
touch lib/core/local_database.dart
touch lib/core/utils/date_util.dart
touch lib/core/utils/logger_util.dart
touch lib/core/di/injection.dart
touch lib/shared/theme/app_colors.dart
