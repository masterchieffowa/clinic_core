import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({required AuthLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<UserEntity?> login(String username, String password) async {
    final UserModel? user = await _localDataSource.login(username, password);
    if (user != null) {
      await _localDataSource.saveSession(user);
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearSession();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _localDataSource.getCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    final UserEntity? user = await getCurrentUser();
    if (user == null) return false;
    return await validateSession();
  }

  @override
  Future<void> saveSession(UserEntity user) async {
    await _localDataSource.saveSession(UserModel.fromEntity(user));
  }

  @override
  Future<void> clearSession() async {
    await _localDataSource.clearSession();
  }

  @override
  Future<bool> validateSession() async {
    return await _localDataSource.validateSession();
  }
}
