import 'dart:convert';

class QMRATestModel {
  final String testId;
  final String patientId;
  final DateTime testDate;
  final String resultFilePath;
  final String resultFormat;
  final DateTime createdAt;

  QMRATestModel({
    required this.testId,
    required this.patientId,
    required this.testDate,
    required this.resultFilePath,
    required this.resultFormat,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'patientId': patientId,
      'testDate': testDate.toIso8601String(),
      'resultFilePath': resultFilePath,
      'resultFormat': resultFormat,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QMRATestModel.fromJson(Map<String, dynamic> json) {
    return QMRATestModel(
      testId: json['testId'] as String,
      patientId: json['patientId'] as String,
      testDate: DateTime.parse(json['testDate'] as String),
      resultFilePath: json['resultFilePath'] as String,
      resultFormat: json['resultFormat'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static QMRATestModel fromJsonString(String jsonString) =>
      QMRATestModel.fromJson(jsonDecode(jsonString));
}
