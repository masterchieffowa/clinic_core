import 'dart:convert';

class PatientModel {
  final String patientId;
  final String? nationalId;
  final String name;
  final DateTime dateOfBirth;
  final int age;
  final String gender;
  final String phone;
  final String? email;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  PatientModel({
    required this.patientId,
    this.nationalId,
    required this.name,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.phone,
    this.email,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'nationalId': nationalId,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patientId'] as String,
      nationalId: json['nationalId'] as String?,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      age: json['age'] as int,
      gender: json['gender'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static PatientModel fromJsonString(String jsonString) =>
      PatientModel.fromJson(jsonDecode(jsonString));
}
