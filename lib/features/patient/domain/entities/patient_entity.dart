import 'package:equatable/equatable.dart';

class PatientEntity extends Equatable {
  final String patientId;
  final String? nationalId;
  final String name;
  final DateTime dateOfBirth;
  final int age;
  final String gender;
  final String phone;
  final String? email;
  final String? address;
  final String? bloodType;
  final String? chronicDiseases;
  final String? allergies;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientEntity({
    required this.patientId,
    this.nationalId,
    required this.name,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.phone,
    this.email,
    this.address,
    this.bloodType,
    this.chronicDiseases,
    this.allergies,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        patientId,
        nationalId,
        name,
        dateOfBirth,
        age,
        gender,
        phone,
        email,
        address,
        bloodType,
        chronicDiseases,
        allergies,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        profilePicture,
        createdAt,
        updatedAt,
      ];

  String get displayGender => gender == 'male' ? 'Male' : 'Female';
  bool get hasChronicDiseases =>
      chronicDiseases != null && chronicDiseases!.isNotEmpty;
  bool get hasAllergies => allergies != null && allergies!.isNotEmpty;
  bool get hasEmergencyContact =>
      emergencyContactName != null && emergencyContactPhone != null;
}
