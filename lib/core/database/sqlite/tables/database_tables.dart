class DatabaseTables {
  // Users Table
  static const String createUsersTable = '''
    CREATE TABLE users (
      user_id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('admin', 'receptionist', 'doctor')),
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      national_id TEXT,
      salary REAL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  // Patients Table
  static const String createPatientsTable = '''
    CREATE TABLE patients (
      patient_id TEXT PRIMARY KEY,
      national_id TEXT UNIQUE,
      name TEXT NOT NULL,
      date_of_birth INTEGER NOT NULL,
      age INTEGER NOT NULL,
      gender TEXT NOT NULL CHECK(gender IN ('male', 'female')),
      phone TEXT NOT NULL,
      email TEXT,
      address TEXT,
      blood_type TEXT,
      chronic_diseases TEXT,
      allergies TEXT,
      emergency_contact_name TEXT,
      emergency_contact_phone TEXT,
      emergency_contact_relation TEXT,
      profile_picture TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  // Medical Records Table
  static const String createMedicalRecordsTable = '''
    CREATE TABLE medical_records (
      record_id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      doctor_id TEXT NOT NULL,
      visit_date INTEGER NOT NULL,
      chief_complaint TEXT,
      diagnosis TEXT,
      prescription TEXT,
      lab_tests TEXT,
      notes TEXT,
      follow_up_date INTEGER,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'completed', 'cancelled')),
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE,
      FOREIGN KEY (doctor_id) REFERENCES users (user_id)
    )
  ''';

  // Appointments Table
  // static const String createAppointmentsTable = '''
  //   CREATE TABLE appointments (
  //     appointment_id TEXT PRIMARY KEY,
  //     patient_id TEXT NOT NULL,
  //     receptionist_id TEXT NOT NULL,
  //     appointment_date INTEGER NOT NULL,
  //     appointment_time TEXT NOT NULL,
  //     duration INTEGER NOT NULL DEFAULT 30,
  //     reason TEXT,
  //     priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('emergency', 'urgent', 'normal', 'routine')),
  //     priority_score REAL NOT NULL DEFAULT 0,
  //     status TEXT NOT NULL DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'waiting', 'in_progress', 'completed', 'cancelled', 'no_show')),
  //     arrival_time INTEGER,
  //     fees REAL,
  //     is_paid INTEGER NOT NULL DEFAULT 0,
  //     notes TEXT,
  //     created_at INTEGER NOT NULL,
  //     updated_at INTEGER NOT NULL,
  //     FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE,
  //     FOREIGN KEY (receptionist_id) REFERENCES users (user_id)
  //   )
  // ''';

  static const String createAppointmentsTable = '''
  CREATE TABLE appointments (
    appointment_id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    receptionist_id TEXT NOT NULL,
    appointment_date INTEGER NOT NULL,
    appointment_time TEXT NOT NULL,
    duration INTEGER NOT NULL DEFAULT 30,
    reason TEXT,
    priority TEXT NOT NULL DEFAULT 'normal' CHECK(priority IN ('emergency', 'urgent', 'normal', 'routine')),
    priority_score REAL NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'waiting', 'in_progress', 'completed', 'cancelled', 'no_show')),
    arrival_time INTEGER,
    fees REAL,
    is_paid INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (receptionist_id) REFERENCES users (user_id)
    -- ✅ REMOVED: FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE
  )
''';

  // QMRA Tests Table
  static const String createQMRATestsTable = '''
    CREATE TABLE qmra_tests (
      test_id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      test_date INTEGER NOT NULL,
      result_file_path TEXT NOT NULL,
      result_format TEXT NOT NULL CHECK(result_format IN ('pdf', 'html')),
      parsed_results TEXT,
      overall_score REAL,
      recommendations TEXT,
      abnormal_findings TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE
    )
  ''';

  // Bills Table
  static const String createBillsTable = '''
    CREATE TABLE bills (
      bill_id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      appointment_id TEXT,
      amount REAL NOT NULL,
      payment_method TEXT CHECK(payment_method IN ('cash', 'card', 'insurance')),
      payment_date INTEGER,
      items TEXT,
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('paid', 'pending', 'cancelled')),
      created_at INTEGER NOT NULL,
      FOREIGN KEY (patient_id) REFERENCES patients (patient_id) ON DELETE CASCADE,
      FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id) ON DELETE SET NULL
    )
  ''';

  // Medical Representatives Table
  static const String createMedicalRepsTable = '''
    CREATE TABLE medical_representatives (
      rep_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      company TEXT NOT NULL,
      phone TEXT NOT NULL,
      email TEXT,
      visit_dates TEXT,
      notes TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  // Settings Table
  static const String createSettingsTable = '''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''';

  // Audit Log Table
  static const String createAuditLogTable = '''
    CREATE TABLE audit_log (
      log_id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      action TEXT NOT NULL,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      old_value TEXT,
      new_value TEXT,
      timestamp INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (user_id)
    )
  ''';

  // Indexes for performance
  static const List<String> createIndexes = [
    'CREATE INDEX idx_patients_national_id ON patients(national_id)',
    'CREATE INDEX idx_patients_phone ON patients(phone)',
    'CREATE INDEX idx_appointments_date ON appointments(appointment_date)',
    'CREATE INDEX idx_appointments_patient ON appointments(patient_id)',
    'CREATE INDEX idx_appointments_status ON appointments(status)',
    'CREATE INDEX idx_medical_records_patient ON medical_records(patient_id)',
    'CREATE INDEX idx_medical_records_date ON medical_records(visit_date)',
    'CREATE INDEX idx_qmra_tests_patient ON qmra_tests(patient_id)',
    'CREATE INDEX idx_qmra_tests_date ON qmra_tests(test_date)',
    'CREATE INDEX idx_audit_log_user ON audit_log(user_id)',
    'CREATE INDEX idx_audit_log_timestamp ON audit_log(timestamp)',
  ];
}
