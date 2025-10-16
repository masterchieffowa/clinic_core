import 'dart:convert';

class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String receptionistId;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int duration;
  final String? reason;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.receptionistId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.duration = 30,
    this.reason,
    this.priority = 'normal',
    this.status = 'scheduled',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'receptionistId': receptionistId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'duration': duration,
      'reason': reason,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      appointmentId: json['appointmentId'] as String,
      patientId: json['patientId'] as String,
      receptionistId: json['receptionistId'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      appointmentTime: json['appointmentTime'] as String,
      duration: json['duration'] as int? ?? 30,
      reason: json['reason'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'scheduled',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static AppointmentModel fromJsonString(String jsonString) =>
      AppointmentModel.fromJson(jsonDecode(jsonString));
}
