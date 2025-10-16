import 'dart:convert';

class UserModel {
  final String userId;
  final String username;
  final String email;
  final String passwordHash;
  final String role;
  final String name;
  final String? phone;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.name,
    this.phone,
    this.address,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'role': role,
      'name': name,
      'phone': phone,
      'address': address,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      role: json['role'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());
  static UserModel fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString));
}
