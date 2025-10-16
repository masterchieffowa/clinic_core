import 'package:clinic_core/core/database/hive/models/patient_model.dart';
import 'package:clinic_core/core/database/hive/models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String usersBox = 'users';
  static const String patientsBox = 'patients';
  static const String appointmentsBox = 'appointments';
  static const String medicalRecordsBox = 'medical_records';
  static const String qmraTestsBox = 'qmra_tests';
  static const String billsBox = 'bills';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Open all boxes
    await Future.wait([
      Hive.openBox<String>(usersBox),
      Hive.openBox<String>(patientsBox),
      Hive.openBox<String>(appointmentsBox),
      Hive.openBox<String>(medicalRecordsBox),
      Hive.openBox<String>(qmraTestsBox),
      Hive.openBox<String>(billsBox),
      Hive.openBox(settingsBox),
    ]);
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<String>(usersBox);
    await box.put(user.userId, user.toJsonString());
  }

  static UserModel? getUser(String userId) {
    final box = Hive.box<String>(usersBox);
    final jsonString = box.get(userId);
    if (jsonString == null) return null;
    return UserModel.fromJsonString(jsonString);
  }

  static List<UserModel> getAllUsers() {
    final box = Hive.box<String>(usersBox);
    return box.values
        .map((jsonString) => UserModel.fromJsonString(jsonString))
        .toList();
  }

  // Patient operations
  static Future<void> savePatient(PatientModel patient) async {
    final box = Hive.box<String>(patientsBox);
    await box.put(patient.patientId, patient.toJsonString());
  }

  static PatientModel? getPatient(String patientId) {
    final box = Hive.box<String>(patientsBox);
    final jsonString = box.get(patientId);
    if (jsonString == null) return null;
    return PatientModel.fromJsonString(jsonString);
  }

  static List<PatientModel> getAllPatients() {
    final box = Hive.box<String>(patientsBox);
    return box.values
        .map((jsonString) => PatientModel.fromJsonString(jsonString))
        .toList();
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBox);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key) {
    final box = Hive.box(settingsBox);
    return box.get(key) as T?;
  }
}
