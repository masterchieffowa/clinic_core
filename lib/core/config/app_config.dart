class AppConfig {
  // App Information
  static const String appName = 'One Minute Clinic';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Database Configuration
  static const String hiveBoxName = 'clinic_db';
  static const String sqliteDatabaseName = 'clinic.db';
  static const int databaseVersion = 1;

  // Backup Configuration
  static const int autoBackupIntervalHours = 6;
  static const String backupFolderName = 'Backups';
  static const int maxBackupFiles = 10; // Keep last 10 backups

  // Encryption
  static const bool useEncryption = true;
  static const String encryptionAlgorithm = 'AES-256';

  // QMRA Configuration
  static const String qmraResultFolder = 'QMRA_Results';
  static const List<String> qmraSupportedFormats = ['pdf', 'html'];

  // Appointment Configuration
  static const int defaultAppointmentDuration = 30; // minutes
  static const int minAppointmentDuration = 15;
  static const int maxAppointmentDuration = 120;

  // Priority Weights for Scheduling Algorithm
  static const Map<String, double> priorityWeights = {
    'arrivalTime': 0.20,
    'severity': 0.40,
    'waitTime': 0.20,
    'duration': 0.10,
    'history': 0.10,
  };

  // Severity Levels
  static const List<String> severityLevels = [
    'Emergency',
    'Urgent',
    'Normal',
    'Routine',
  ];

  // File Size Limits (in MB)
  static const int maxFileUploadSize = 10;
  static const int maxImageSize = 5;

  // Pagination
  static const int itemsPerPage = 20;

  // Cache
  static const int cacheExpirationDays = 7;

  // Session
  static const int sessionTimeoutMinutes = 30;

  // API Configuration (for future cloud sync)
  static const String apiBaseUrl = 'https://api.example.com';
  static const int apiTimeoutSeconds = 30;

  // Development
  static const bool enableLogging = true;
  static const bool enableDebugMode = false;
}
