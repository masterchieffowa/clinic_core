import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import '../../data/datasources/patient_local_datasource.dart';
import '../../data/models/patient_model.dart';
import '../../domain/entities/patient_entity.dart';

// ============================================================================
// Providers
// ============================================================================

// Data Source Provider
final patientDataSourceProvider = Provider<PatientLocalDataSource>((ref) {
  return PatientLocalDataSource(
    databaseHelper: getIt<DatabaseHelper>(),
  );
});

// Patients List Provider
final patientsProvider =
    StateNotifierProvider<PatientsNotifier, PatientsState>((ref) {
  return PatientsNotifier(ref.read(patientDataSourceProvider));
});

// Search Query Provider
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Patients Provider (with search)
final filteredPatientsProvider = Provider<List<PatientEntity>>((ref) {
  final patientsState = ref.watch(patientsProvider);
  final searchQuery = ref.watch(patientSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return patientsState.patients;
  }

  final query = searchQuery.toLowerCase();
  return patientsState.patients.where((patient) {
    return patient.name.toLowerCase().contains(query) ||
        patient.phone.contains(query) ||
        (patient.nationalId?.contains(query) ?? false);
  }).toList();
});

// Patient Stats Provider
final patientStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final dataSource = ref.read(patientDataSourceProvider);
  return await dataSource.getPatientStats();
});

// ============================================================================
// State
// ============================================================================

class PatientsState {
  final List<PatientEntity> patients;
  final bool isLoading;
  final String? errorMessage;

  const PatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PatientsState copyWith({
    List<PatientEntity>? patients,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class PatientsNotifier extends StateNotifier<PatientsState> {
  final PatientLocalDataSource _dataSource;

  PatientsNotifier(this._dataSource) : super(const PatientsState()) {
    loadPatients();
  }

  // Load all patients
  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final patients = await _dataSource.getAllPatients();
      state = state.copyWith(
        patients: patients,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load patients: $e',
      );
    }
  }

  // Create patient
  Future<bool> createPatient(PatientModel patient) async {
    try {
      final newPatient = await _dataSource.createPatient(patient);
      state = state.copyWith(
        patients: [...state.patients, newPatient],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create patient: $e');
      return false;
    }
  }

  // Update patient
  Future<bool> updatePatient(PatientModel patient) async {
    try {
      final updatedPatient = await _dataSource.updatePatient(patient);

      final updatedList = state.patients.map((p) {
        return p.patientId == patient.patientId ? updatedPatient : p;
      }).toList();

      state = state.copyWith(patients: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update patient: $e');
      return false;
    }
  }

  // Delete patient
  Future<bool> deletePatient(String patientId) async {
    try {
      await _dataSource.deletePatient(patientId);

      state = state.copyWith(
        patients:
            state.patients.where((p) => p.patientId != patientId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete patient: $e');
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
