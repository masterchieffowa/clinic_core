import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../data/models/appointment_model.dart';
import '../../data/datasources/appointment_local_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import 'appointment_form_page.dart';

final appointmentDataSourceProvider =
    Provider<AppointmentLocalDataSource>((ref) {
  return AppointmentLocalDataSource(
    databaseHelper: getIt<DatabaseHelper>(),
  );
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  return AppointmentsNotifier(ref.read(appointmentDataSourceProvider));
});

final selectedDateAppointmentsProvider =
    Provider<List<AppointmentEntity>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final appointmentsState = ref.watch(appointmentsProvider);

  return appointmentsState.appointments.where((apt) {
    return apt.appointmentDate.year == selectedDate.year &&
        apt.appointmentDate.month == selectedDate.month &&
        apt.appointmentDate.day == selectedDate.day;
  }).toList();
});

final appointmentStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final dataSource = ref.read(appointmentDataSourceProvider);
  return await dataSource.getAppointmentStats();
});

// ============================================================================
// STATE
// ============================================================================

class AppointmentsState {
  final List<AppointmentEntity> appointments;
  final bool isLoading;
  final String? errorMessage;

  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentsState copyWith({
    List<AppointmentEntity>? appointments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// NOTIFIER
// ============================================================================

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentLocalDataSource _dataSource;

  AppointmentsNotifier(this._dataSource) : super(const AppointmentsState()) {
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final appointments = await _dataSource.getAllAppointments();
      state = state.copyWith(
        appointments: appointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load appointments: $e',
      );
    }
  }

  Future<bool> createAppointment(AppointmentModel appointment) async {
    try {
      final newAppointment = await _dataSource.createAppointment(appointment);
      state = state.copyWith(
        appointments: [...state.appointments, newAppointment],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create appointment: $e');
      return false;
    }
  }

  Future<bool> updateAppointment(AppointmentModel appointment) async {
    try {
      final updated = await _dataSource.updateAppointment(appointment);

      final updatedList = state.appointments.map((a) {
        return a.appointmentId == appointment.appointmentId ? updated : a;
      }).toList();

      state = state.copyWith(appointments: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update appointment: $e');
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _dataSource.deleteAppointment(appointmentId);

      state = state.copyWith(
        appointments: state.appointments
            .where((a) => a.appointmentId != appointmentId)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete appointment: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ============================================================================
// APPOINTMENTS PAGE
// ============================================================================

class AppointmentsPage extends ConsumerWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsState = ref.watch(appointmentsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedDateAppointments =
        ref.watch(selectedDateAppointmentsProvider);
    final statsAsync = ref.watch(appointmentStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appointments & Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(appointmentsProvider.notifier).loadAppointments();
              ref.invalidate(appointmentStatsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: appointmentsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left: Calendar
                Expanded(
                  flex: 2,
                  child: _buildCalendarSection(context, ref, selectedDate),
                ),

                const VerticalDivider(width: 1),

                // Right: Appointment List
                Expanded(
                  flex: 1,
                  child: _buildAppointmentsList(
                    context,
                    ref,
                    selectedDate,
                    selectedDateAppointments,
                    statsAsync,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewAppointment(context, ref, selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildCalendarSection(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    final appointments = ref.watch(appointmentsProvider).appointments;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selected, focused) {
                ref.read(selectedDateProvider.notifier).state = selected;
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal[300],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              eventLoader: (day) {
                return appointments
                    .where((apt) =>
                        apt.appointmentDate.year == day.year &&
                        apt.appointmentDate.month == day.month &&
                        apt.appointmentDate.day == day.day)
                    .toList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    List<AppointmentEntity> appointments,
    AsyncValue<Map<String, int>> statsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Section
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${stats['todayTotal']}',
                      color: Colors.blue,
                    ),
                    _StatChip(
                      label: 'Waiting',
                      value: '${stats['todayWaiting']}',
                      color: Colors.orange,
                    ),
                    _StatChip(
                      label: 'In Progress',
                      value: '${stats['todayInProgress']}',
                      color: Colors.teal,
                    ),
                    _StatChip(
                      label: 'Completed',
                      value: '${stats['todayCompleted']}',
                      color: Colors.green,
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Appointments List
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: appointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: appointments.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final apt = appointments[index];
                            return ListTile(
                              title: Text(apt.patientName),
                              subtitle: Text(DateFormat('hh:mm a')
                                  .format(apt.appointmentDate)),
                              trailing: Text(apt.status),
                              onTap: () {
                                // Handle appointment tap
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
