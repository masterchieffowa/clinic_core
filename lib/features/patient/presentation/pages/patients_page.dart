// E:\Projects\Flutter Projects\Clinic Management System\clinic_core\lib\features\patient\presentation\pages\patients_page.dart

import 'package:clinic_core/features/patient/presentation/pages/patient_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/patient_entity.dart';
import '../../data/models/patient_model.dart';
import '../../data/datasources/patient_local_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/sqlite/database_helper.dart';

// Data Source Provider
final patientDataSourceProvider = Provider<PatientLocalDataSource>((ref) {
  return PatientLocalDataSource(
    databaseHelper: getIt<DatabaseHelper>(),
  );
});

// Search Query Provider
final patientSearchQueryProvider = StateProvider<String>((ref) => '');

// Patients State Provider
final patientsProvider =
    StateNotifierProvider<PatientsNotifier, PatientsState>((ref) {
  return PatientsNotifier(ref.read(patientDataSourceProvider));
});

// Filtered Patients Provider
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

class PatientsNotifier extends StateNotifier<PatientsState> {
  final PatientLocalDataSource _dataSource;

  PatientsNotifier(this._dataSource) : super(const PatientsState()) {
    loadPatients();
  }

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

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class PatientsPage extends ConsumerWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(patientsProvider);
    final filteredPatients = ref.watch(filteredPatientsProvider);
    final statsAsync = ref.watch(patientStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Patients Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Clear Duplicate IDs',
            onPressed: () async {
              try {
                await ref
                    .read(patientDataSourceProvider)
                    .clearDuplicateNationalIds();
                ref.read(patientsProvider.notifier).loadPatients();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Duplicate IDs cleared successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(patientsProvider.notifier).loadPatients();
              ref.invalidate(patientStatsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Stats Bar
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    ref.read(patientSearchQueryProvider.notifier).state = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or national ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Statistics Cards
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Patients',
                          value: '${stats['total']}',
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Male',
                          value: '${stats['male']}',
                          icon: Icons.male,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Female',
                          value: '${stats['female']}',
                          icon: Icons.female,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'New This Month',
                          value: '${stats['newThisMonth']}',
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          // Patients List
          Expanded(
            child: patientsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return _PatientCard(
                            patient: patient,
                            onTap: () =>
                                _openPatientDetails(context, ref, patient),
                            onEdit: () => _editPatient(context, ref, patient),
                            onDelete: () =>
                                _deletePatient(context, ref, patient),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewPatient(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No patients found',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first patient to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _addNewPatient(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PatientFormPage(),
      ),
    );
  }

  void _openPatientDetails(
      BuildContext context, WidgetRef ref, PatientEntity patient) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening details for ${patient.name}')),
    );
  }

  void _editPatient(
      BuildContext context, WidgetRef ref, PatientEntity patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientFormPage(patient: patient),
      ),
    );
  }

  void _deletePatient(
      BuildContext context, WidgetRef ref, PatientEntity patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(patientsProvider.notifier)
                  .deletePatient(patient.patientId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Patient deleted successfully'
                          : 'Failed to delete patient',
                    ),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientEntity patient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            patient.name[0].toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(patient.phone),
                const SizedBox(width: 16),
                Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${patient.age} years'),
                const SizedBox(width: 16),
                Icon(
                  patient.gender == 'male' ? Icons.male : Icons.female,
                  size: 16,
                  color: patient.gender == 'male' ? Colors.blue : Colors.pink,
                ),
                const SizedBox(width: 4),
                Text(patient.displayGender),
              ],
            ),
            if (patient.hasChronicDiseases || patient.hasAllergies) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (patient.hasChronicDiseases)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Chronic Disease',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  if (patient.hasChronicDiseases && patient.hasAllergies)
                    const SizedBox(width: 8),
                  if (patient.hasAllergies)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Allergies',
                        style: TextStyle(fontSize: 11, color: Colors.red[900]),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
