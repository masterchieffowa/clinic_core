import 'dart:convert';

class MedicalRecordModel {
  final String recordId;
  final String patientId;
  final String doctorId;
  final DateTime visitDate;
  final String? diagnosis;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecordModel({
    required this.recordId,
    required this.patientId,
    required this.doctorId,
    required this.visitDate,
    this.diagnosis,
    this.notes,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'patientId': patientId,
      'doctorId': doctorId,
      'visitDate': visitDate.toIso8601String(),
      'diagnosis': diagnosis,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      recordId: json['recordId'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      diagnosis: json['diagnosis'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static MedicalRecordModel fromJsonString(String jsonString) =>
      MedicalRecordModel.fromJson(jsonDecode(jsonString));
}
