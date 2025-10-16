import 'package:clinic_core/core/database/hive/models/appointment_model.dart';
import 'package:clinic_core/core/database/hive/models/bill_model.dart';
import 'package:clinic_core/core/database/hive/models/medical_record_model.dart';
import 'package:clinic_core/core/database/hive/models/patient_model.dart';
import 'package:clinic_core/core/database/hive/models/qmra_test_model.dart';
import 'package:clinic_core/core/database/hive/models/user_model.dart';
import 'package:hive/hive.dart';

class HiveBoxes {
  // Box names
  static const String users = 'users';
  static const String patients = 'patients';
  static const String appointments = 'appointments';
  static const String medicalRecords = 'medical_records';
  static const String qmraTests = 'qmra_tests';
  static const String bills = 'bills';
  static const String settings = 'settings';
  static const String cache = 'cache';

  // Get boxes
  static Box<UserModel> getUsersBox() => Hive.box<UserModel>(users);
  static Box<PatientModel> getPatientsBox() => Hive.box<PatientModel>(patients);
  static Box<AppointmentModel> getAppointmentsBox() =>
      Hive.box<AppointmentModel>(appointments);
  static Box<MedicalRecordModel> getMedicalRecordsBox() =>
      Hive.box<MedicalRecordModel>(medicalRecords);
  static Box<QMRATestModel> getQMRATestsBox() =>
      Hive.box<QMRATestModel>(qmraTests);
  static Box<BillModel> getBillsBox() => Hive.box<BillModel>(bills);
  static Box<dynamic> getSettingsBox() => Hive.box(settings);
  static Box<dynamic> getCacheBox() => Hive.box(cache);

  // Open all boxes
  static Future<void> openAllBoxes() async {
    await Future.wait([
      Hive.openBox<UserModel>(users),
      Hive.openBox<PatientModel>(patients),
      Hive.openBox<AppointmentModel>(appointments),
      Hive.openBox<MedicalRecordModel>(medicalRecords),
      Hive.openBox<QMRATestModel>(qmraTests),
      Hive.openBox<BillModel>(bills),
      Hive.openBox(settings),
      Hive.openBox(cache),
    ]);
  }
  // Close all boxes

  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  // Clear all boxes (for testing/reset)
  static Future<void> clearAllBoxes() async {
    await getUsersBox().clear();
    await getPatientsBox().clear();
    await getAppointmentsBox().clear();
    await getMedicalRecordsBox().clear();
    await getQMRATestsBox().clear();
    await getBillsBox().clear();
    await getSettingsBox().clear();
    await getCacheBox().clear();
  }
}
