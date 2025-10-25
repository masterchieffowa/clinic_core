import 'package:clinic_core/features/appointment/presentation/pages/appointment_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../data/models/appointment_model.dart';
import '../../data/datasources/appointment_local_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/sqlite/database_helper.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

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
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return _AppointmentCard(
                              appointment: appointment,
                              onTap: () =>
                                  _viewAppointment(context, ref, appointment),
                              onEdit: () =>
                                  _editAppointment(context, ref, appointment),
                              onDelete: () =>
                                  _deleteAppointment(context, ref, appointment),
                              onStatusChange: (newStatus) => _changeStatus(
                                  context, ref, appointment, newStatus),
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

  void _addNewAppointment(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentFormPage(initialDate: selectedDate),
      ),
    );
  }

  void _viewAppointment(
      BuildContext context, WidgetRef ref, AppointmentEntity appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Viewing ${appointment.patientName}\'s appointment')),
    );
  }

  void _editAppointment(
      BuildContext context, WidgetRef ref, AppointmentEntity appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentFormPage(
          appointment: appointment,
          initialDate: appointment.appointmentDate,
        ),
      ),
    );
  }

  void _deleteAppointment(
      BuildContext context, WidgetRef ref, AppointmentEntity appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Delete appointment for ${appointment.patientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(appointmentsProvider.notifier)
                  .deleteAppointment(appointment.appointmentId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Appointment deleted'
                          : 'Failed to delete appointment',
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

  void _changeStatus(BuildContext context, WidgetRef ref,
      AppointmentEntity appointment, String newStatus) async {
    final model =
        AppointmentModel.fromEntity(appointment).copyWith(status: newStatus);
    final success =
        await ref.read(appointmentsProvider.notifier).updateAppointment(model);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated to ${model.displayStatus}'
                : 'Failed to update status',
          ),
        ),
      );
    }
  }
}

// ============================================================================
// APPOINTMENT CARD WIDGET
// ============================================================================

class _AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case 'scheduled':
        return Colors.blue;
      case 'waiting':
        return Colors.orange;
      case 'in_progress':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'no_show':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor() {
    switch (appointment.priority) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'routine':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Time
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      appointment.appointmentTime,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appointment.displayPriority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                        case 'scheduled':
                        case 'waiting':
                        case 'in_progress':
                        case 'completed':
                        case 'cancelled':
                          onStatusChange(value);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'scheduled',
                        child: Text('Mark as Scheduled'),
                      ),
                      const PopupMenuItem(
                        value: 'waiting',
                        child: Text('Mark as Waiting'),
                      ),
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Text('Mark as In Progress'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Mark as Completed'),
                      ),
                      const PopupMenuItem(
                        value: 'cancelled',
                        child: Text('Cancel Appointment'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Patient Name
              Text(
                appointment.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Reason
              if (appointment.reason != null && appointment.reason!.isNotEmpty)
                Text(
                  appointment.reason!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 8),

              // Status & Duration
              Row(
                children: [
                  Icon(Icons.timelapse, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${appointment.duration} min',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.circle, size: 10, color: _getStatusColor()),
                  const SizedBox(width: 4),
                  Text(
                    appointment.displayStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (appointment.isPaid) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Paid',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CHIP WIDGET
// ============================================================================

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLACEHOLDER FOR APPOINTMENT FORM PAGE
// ============================================================================

// class AppointmentFormPage extends StatelessWidget {
//   final AppointmentEntity? appointment;
//   final DateTime initialDate;

//   const AppointmentFormPage({
//     super.key,
//     this.appointment,
//     required this.initialDate,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:
//             Text(appointment == null ? 'Book Appointment' : 'Edit Appointment'),
//       ),
//       body: const Center(
//         child: Text('Appointment form will be implemented'),
//       ),
//     );
//   }
// }
