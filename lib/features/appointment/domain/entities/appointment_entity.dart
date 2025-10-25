import 'package:equatable/equatable.dart';

class AppointmentEntity extends Equatable {
  final String appointmentId;
  final String patientId;
  final String patientName; // For display
  final String receptionistId;
  final DateTime appointmentDate;
  final String appointmentTime; // Format: "09:00"
  final int duration; // in minutes
  final String? reason;
  final String priority; // 'emergency', 'urgent', 'normal', 'routine'
  final double priorityScore;
  final String
      status; // 'scheduled', 'waiting', 'in_progress', 'completed', 'cancelled', 'no_show'
  final DateTime? arrivalTime;
  final double? fees;
  final bool isPaid;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentEntity({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.receptionistId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.duration = 30,
    this.reason,
    this.priority = 'normal',
    this.priorityScore = 0,
    this.status = 'scheduled',
    this.arrivalTime,
    this.fees,
    this.isPaid = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        appointmentId,
        patientId,
        patientName,
        receptionistId,
        appointmentDate,
        appointmentTime,
        duration,
        reason,
        priority,
        priorityScore,
        status,
        arrivalTime,
        fees,
        isPaid,
        notes,
        createdAt,
        updatedAt,
      ];

  String get displayStatus {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'waiting':
        return 'Waiting';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  String get displayPriority {
    switch (priority) {
      case 'emergency':
        return 'Emergency';
      case 'urgent':
        return 'Urgent';
      case 'normal':
        return 'Normal';
      case 'routine':
        return 'Routine';
      default:
        return priority;
    }
  }

  bool get isActive =>
      status == 'scheduled' || status == 'waiting' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'no_show';
}
