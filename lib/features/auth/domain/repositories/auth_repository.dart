import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String username, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> saveSession(UserEntity user);
  Future<void> clearSession();
  Future<bool> validateSession();
}
