import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';import '../../enums/user_role.dart';

import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(String email, String password) async {
    try {
      final response = await repository.login(email, password);
      // Создаем UserEntity из данных ответа
      final userEntity = UserEntity(
        id: 0, // Временно, пока бэкенд не возвращает id
        fullName: response.fullName ?? '',
        email: response.email ?? email,
        phone: '', // Бэкенд не возвращает phone
        role: UserRoleExtension.fromString(response.role ?? 'CLIENT'),
        isActive: true,
        avatar: null,
        rating: null,
        completedOrders: null,
      );
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}