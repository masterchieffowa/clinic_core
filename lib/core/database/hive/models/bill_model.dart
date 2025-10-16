import 'dart:convert';

class BillModel {
  final String billId;
  final String patientId;
  final String? appointmentId;
  final double amount;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final String status;
  final DateTime createdAt;

  BillModel({
    required this.billId,
    required this.patientId,
    this.appointmentId,
    required this.amount,
    this.paymentMethod,
    this.paymentDate,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'billId': billId,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      billId: json['billId'] as String,
      patientId: json['patientId'] as String,
      appointmentId: json['appointmentId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String?,
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static BillModel fromJsonString(String jsonString) =>
      BillModel.fromJson(jsonDecode(jsonString));
}
