import 'package:dartz/dartz.dart';
import '../../entities/user_entity.dart';
import '../../enums/user_role.dart';
import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class RegisterUseCase {
  final IAuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> execute(Map<String, dynamic> data) async {
    try {
      final response = await repository.register(data);
      // Создаем UserEntity из данных ответа
      final userEntity = UserEntity(
        id: 0, // Временно, пока бэкенд не возвращает id
        fullName: response.fullName ?? data['fullName'] ?? '',
        email: response.email ?? data['email'] ?? '',
        phone: data['phone'] ?? '',
        role: UserRoleExtension.fromString(response.role ?? data['role'] ?? 'CLIENT'),
        isActive: true,
        avatar: null,
        rating: null,
        completedOrders: null,
        cleanerId: response.cleanerId,
      );
      return Right(userEntity);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}