// E:\Projects\Flutter Projects\Clinic Management System\clinic_core\lib\features\appointment\presentation\pages\appointment_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../data/models/appointment_model.dart';
import '../../../patient/domain/entities/patient_entity.dart';
import '../../../patient/data/datasources/patient_local_datasource.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/sqlite/database_helper.dart';
import 'appointments_page.dart';

// Provider for patients list
final patientsListProvider = FutureProvider<List<PatientEntity>>((ref) async {
  final dataSource = PatientLocalDataSource(
    databaseHelper: getIt<DatabaseHelper>(),
  );
  return await dataSource.getAllPatients();
});

class AppointmentFormPage extends ConsumerStatefulWidget {
  final AppointmentEntity? appointment;
  final DateTime initialDate;

  const AppointmentFormPage({
    super.key,
    this.appointment,
    required this.initialDate,
  });

  @override
  ConsumerState<AppointmentFormPage> createState() =>
      _AppointmentFormPageState();
}

class _AppointmentFormPageState extends ConsumerState<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _feesController = TextEditingController();

  PatientEntity? _selectedPatient;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'normal';
  String _selectedStatus = 'scheduled';
  int _duration = 30;
  bool _isPaid = false;
  bool _isLoading = false;

  final List<String> _priorities = ['emergency', 'urgent', 'normal', 'routine'];
  final List<String> _statuses = [
    'scheduled',
    'waiting',
    'in_progress',
    'completed',
    'cancelled'
  ];
  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    if (widget.appointment != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final apt = widget.appointment!;
    _reasonController.text = apt.reason ?? '';
    _notesController.text = apt.notes ?? '';
    _feesController.text = apt.fees?.toString() ?? '';
    _selectedDate = apt.appointmentDate;

    // Parse time from string (format: "09:00")
    final timeParts = apt.appointmentTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    _selectedPriority = apt.priority;
    _selectedStatus = apt.status;
    _duration = apt.duration;
    _isPaid = apt.isPaid;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Format time as "HH:mm"
    final timeString =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    // Get current user (assuming admin for now)
    const currentUserId = 'admin-user-id'; // TODO: Get from auth provider

    final appointment = AppointmentModel(
      appointmentId: widget.appointment?.appointmentId ?? '',
      patientId: _selectedPatient!.patientId,
      patientName: _selectedPatient!.name,
      receptionistId: currentUserId,
      appointmentDate: _selectedDate!,
      appointmentTime: timeString,
      duration: _duration,
      reason:
          _reasonController.text.isEmpty ? null : _reasonController.text.trim(),
      priority: _selectedPriority,
      priorityScore: _calculatePriorityScore(),
      status: _selectedStatus,
      fees: _feesController.text.isEmpty
          ? null
          : double.tryParse(_feesController.text),
      isPaid: _isPaid,
      notes:
          _notesController.text.isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Import the provider from appointments_page.dart
    final success = widget.appointment == null
        ? await ref
            .read(appointmentsProvider.notifier)
            .createAppointment(appointment)
        : await ref
            .read(appointmentsProvider.notifier)
            .updateAppointment(appointment);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.appointment == null
                  ? 'Appointment booked successfully'
                  : 'Appointment updated successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save appointment')),
        );
      }
    }
  }

  double _calculatePriorityScore() {
    // Simple priority scoring
    switch (_selectedPriority) {
      case 'emergency':
        return 100.0;
      case 'urgent':
        return 75.0;
      case 'normal':
        return 50.0;
      case 'routine':
        return 25.0;
      default:
        return 0.0;
    }
  }

  @override

  /// Builds the appointment form page.
  ///
  /// This page is used to book a new appointment or edit an existing one.
  ///
  /// It takes a [AppointmentEntity] object as a parameter, which is used to prefill
  /// the form fields if the appointment is being edited.
  ///
  /// The page contains the following sections:
  ///
  /// - Patient Information: Patient selection dropdown, date and time pickers,
  ///     and a duration dropdown.
  ///
  /// - Priority & Status: Priority dropdown and status dropdown.
  ///
  /// - Appointment Details: Reason for visit text field and additional notes text field.
  ///
  /// - Payment Information: Fees text field and a checkbox to indicate if the appointment has been paid.
  ///
  /// If the appointment is being edited, the page will display the existing values in the
  /// form fields. If the appointment is being booked, the form fields will be empty.
  ///
  /// When the save button is pressed, the page will validate the form fields and then
  /// save the appointment to the database. If the appointment is being edited, the page
  /// will update the existing appointment in the database. If the appointment is being
  /// booked, the page will create a new appointment in the database.
  ///
  /// The page will display a loading indicator while the appointment is being saved
  /// to the database. If there is an error while saving the appointment, the page
  /// will display an error message.
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider);
    final isEditMode = widget.appointment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Appointment' : 'Book Appointment'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveAppointment,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Patient Selection
            _buildSectionTitle('Patient Information'),
            const SizedBox(height: 16),

            patientsAsync.when(
              data: (patients) => DropdownButtonFormField<PatientEntity>(
                initialValue: _selectedPatient,
                decoration: InputDecoration(
                  labelText: 'Select Patient',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: patients.map((patient) {
                  return DropdownMenuItem(
                    value: patient,
                    child: Text('${patient.name} - ${patient.phone}'),
                  );
                }).toList(),
                onChanged: isEditMode
                    ? null
                    : (value) => setState(() => _selectedPatient = value),
                validator: (value) {
                  if (value == null) return 'Please select a patient';
                  return null;
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading patients: $error'),
            ),
            const SizedBox(height: 24),

            // Date & Time Section
            _buildSectionTitle('Appointment Date & Time'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat('EEEE, MMM d, yyyy')
                                .format(_selectedDate!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Time',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Select time'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _duration,
              decoration: InputDecoration(
                labelText: 'Duration',
                prefixIcon: const Icon(Icons.timelapse),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _durations.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text('$duration minutes'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _duration = value!),
            ),
            const SizedBox(height: 24),

            // Priority & Status Section
            _buildSectionTitle('Priority & Status'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: const Icon(Icons.priority_high),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(
                            priority[0].toUpperCase() + priority.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPriority = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.circle),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((word) =>
                                word[0].toUpperCase() + word.substring(1))
                            .join(' ')),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details Section
            _buildSectionTitle('Appointment Details'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Visit (Optional)',
                hintText: 'e.g., Regular checkup, Follow-up',
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Any special instructions or notes',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Payment Section
            _buildSectionTitle('Payment Information'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _feesController,
                    decoration: InputDecoration(
                      labelText: 'Fees (Optional)',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Paid'),
                    value: _isPaid,
                    onChanged: (value) =>
                        setState(() => _isPaid = value ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    tileColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveAppointment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                    isEditMode ? 'Update Appointment' : 'Book Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
