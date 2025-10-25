import 'dart:convert';
import '../../domain/entities/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.patientId,
    super.nationalId,
    required super.name,
    required super.dateOfBirth,
    required super.age,
    required super.gender,
    required super.phone,
    super.email,
    super.address,
    super.bloodType,
    super.chronicDiseases,
    super.allergies,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.emergencyContactRelation,
    super.profilePicture,
    required super.createdAt,
    required super.updatedAt,
  });

  // From SQLite Database
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patient_id'] as String,
      nationalId: json['national_id'] as String?,
      name: json['name'] as String,
      dateOfBirth:
          DateTime.fromMillisecondsSinceEpoch(json['date_of_birth'] as int),
      age: json['age'] as int,
      gender: json['gender'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      bloodType: json['blood_type'] as String?,
      chronicDiseases: json['chronic_diseases'] as String?,
      allergies: json['allergies'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelation: json['emergency_contact_relation'] as String?,
      profilePicture: json['profile_picture'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  // To SQLite Database
  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'national_id': nationalId,
      'name': name,
      'date_of_birth': dateOfBirth.millisecondsSinceEpoch,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'address': address,
      'blood_type': bloodType,
      'chronic_diseases': chronicDiseases,
      'allergies': allergies,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'profile_picture': profilePicture,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // For Hive Storage (JSON String)
  String toJsonString() => jsonEncode(toJson());

  factory PatientModel.fromJsonString(String jsonString) {
    return PatientModel.fromJson(jsonDecode(jsonString));
  }

  // From Entity
  factory PatientModel.fromEntity(PatientEntity entity) {
    return PatientModel(
      patientId: entity.patientId,
      nationalId: entity.nationalId,
      name: entity.name,
      dateOfBirth: entity.dateOfBirth,
      age: entity.age,
      gender: entity.gender,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      bloodType: entity.bloodType,
      chronicDiseases: entity.chronicDiseases,
      allergies: entity.allergies,
      emergencyContactName: entity.emergencyContactName,
      emergencyContactPhone: entity.emergencyContactPhone,
      emergencyContactRelation: entity.emergencyContactRelation,
      profilePicture: entity.profilePicture,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PatientModel copyWith({
    String? patientId,
    String? nationalId,
    String? name,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? address,
    String? bloodType,
    String? chronicDiseases,
    String? allergies,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      patientId: patientId ?? this.patientId,
      nationalId: nationalId ?? this.nationalId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      allergies: allergies ?? this.allergies,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
