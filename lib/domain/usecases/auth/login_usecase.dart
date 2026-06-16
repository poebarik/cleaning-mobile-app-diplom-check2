import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../enums/user_role.dart';
import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String email, String password) async {
    try {
      final response = await repository.login(email, password);

      print('🔐 Login response FULL: ${response.toJson()}'); // ← Добавьте toJson метод

      print('🔐 Login response - userId: ${response.userId}, cleanerId: ${response.cleanerId}');

      final userEntity = UserEntity(
        id: response.userId ?? 0,
        fullName: response.fullName ?? '',
        email: response.email ?? email,
        phone: '',
        role: UserRoleExtension.fromString(response.role ?? 'CLIENT'),
        isActive: true,
        avatar: null,
        rating: null,
        completedOrders: null,
        cleanerId: response.cleanerId,
      );

      print('✅ UserEntity created - id: ${userEntity.id}, cleanerId: ${userEntity.cleanerId}');
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}