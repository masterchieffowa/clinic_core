import 'dart:convert';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.username,
    required super.email,
    required super.role,
    required super.name,
    super.phone,
    super.address,
    super.nationalId,
    super.salary,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  // From JSON (from database)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      nationalId: json['national_id'] as String?,
      salary:
          json['salary'] != null ? (json['salary'] as num).toDouble() : null,
      isActive: (json['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  // To JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'address': address,
      'national_id': nationalId,
      'salary': salary,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // To JSON for Hive (String storage)
  String toJsonString() => jsonEncode(toJson());

  // From JSON String (from Hive)
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString));
  }

  // From Entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      userId: entity.userId,
      username: entity.username,
      email: entity.email,
      role: entity.role,
      name: entity.name,
      phone: entity.phone,
      address: entity.address,
      nationalId: entity.nationalId,
      salary: entity.salary,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? role,
    String? name,
    String? phone,
    String? address,
    String? nationalId,
    double? salary,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      salary: salary ?? this.salary,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
