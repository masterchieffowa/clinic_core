import 'dart:convert';
import '../../domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.appointmentId,
    required super.patientId,
    required super.patientName,
    required super.receptionistId,
    required super.appointmentDate,
    required super.appointmentTime,
    super.duration,
    super.reason,
    super.priority,
    super.priorityScore,
    super.status,
    super.arrivalTime,
    super.fees,
    super.isPaid,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointment_id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      receptionistId: json['receptionist_id'] as String,
      appointmentDate:
          DateTime.fromMillisecondsSinceEpoch(json['appointment_date'] as int),
      appointmentTime: json['appointment_time'] as String,
      duration: json['duration'] as int? ?? 30,
      reason: json['reason'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'scheduled',
      arrivalTime: json['arrival_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['arrival_time'] as int)
          : null,
      fees: (json['fees'] as num?)?.toDouble(),
      isPaid: (json['is_paid'] as int?) == 1,
      notes: json['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'patient_id': patientId,
      'receptionist_id': receptionistId,
      'appointment_date': appointmentDate.millisecondsSinceEpoch,
      'appointment_time': appointmentTime,
      'duration': duration,
      'reason': reason,
      'priority': priority,
      'priority_score': priorityScore,
      'status': status,
      'arrival_time': arrivalTime?.millisecondsSinceEpoch,
      'fees': fees,
      'is_paid': isPaid ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppointmentModel.fromJsonString(String jsonString) {
    return AppointmentModel.fromJson(jsonDecode(jsonString));
  }

  factory AppointmentModel.fromEntity(AppointmentEntity entity) {
    return AppointmentModel(
      appointmentId: entity.appointmentId,
      patientId: entity.patientId,
      patientName: entity.patientName,
      receptionistId: entity.receptionistId,
      appointmentDate: entity.appointmentDate,
      appointmentTime: entity.appointmentTime,
      duration: entity.duration,
      reason: entity.reason,
      priority: entity.priority,
      priorityScore: entity.priorityScore,
      status: entity.status,
      arrivalTime: entity.arrivalTime,
      fees: entity.fees,
      isPaid: entity.isPaid,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AppointmentModel copyWith({
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? receptionistId,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? duration,
    String? reason,
    String? priority,
    double? priorityScore,
    String? status,
    DateTime? arrivalTime,
    double? fees,
    bool? isPaid,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      receptionistId: receptionistId ?? this.receptionistId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
      priorityScore: priorityScore ?? this.priorityScore,
      status: status ?? this.status,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      fees: fees ?? this.fees,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
