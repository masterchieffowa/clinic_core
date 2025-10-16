import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String username;
  final String email;
  final String role; // 'admin', 'receptionist', 'doctor'
  final String name;
  final String? phone;
  final String? address;
  final String? nationalId;
  final double? salary;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
    this.address,
    this.nationalId,
    this.salary,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        username,
        email,
        role,
        name,
        phone,
        address,
        nationalId,
        salary,
        isActive,
        createdAt,
        updatedAt,
      ];

  bool get isAdmin => role == 'admin';
  bool get isReceptionist => role == 'receptionist';
  bool get isDoctor => role == 'doctor';

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'receptionist':
        return 'Receptionist';
      case 'doctor':
        return 'Doctor';
      default:
        return 'User';
    }
  }
}
