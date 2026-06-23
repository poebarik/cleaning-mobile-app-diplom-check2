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

      print('🔐 Login response FULL: ${response.toJson()}');

      // ✅ Извлекаем avatarUrl из ответа
      String? avatarUrl = response.avatarUrl;

      // Если avatarUrl нет, пробуем из user данных
      if (avatarUrl == null && response.user != null) {
        avatarUrl = response.user?.avatarUrl;
      }

      print('📸 Avatar URL from response: $avatarUrl');

      final userEntity = UserEntity(
        id: response.userId ?? response.user?.id ?? 0,
        fullName: response.fullName ?? response.user?.fullName ?? '',
        email: response.email ?? response.user?.email ?? email,
        phone: response.phone ?? response.user?.phone ?? '',
        role: UserRoleExtension.fromString(response.role ?? response.user?.role ?? 'CLIENT'),
        isActive: true,
        avatar: avatarUrl,  // ✅ Сохраняем avatarUrl
        rating: response.rating ?? response.user?.rating,
        completedOrders: response.completedOrders ?? response.user?.completedOrders,
        cleanerId: response.cleanerId ?? response.user?.cleanerId,
        description: response.description ?? response.user?.description,
      );

      print('✅ UserEntity created:');
      print('  - id: ${userEntity.id}');
      print('  - fullName: ${userEntity.fullName}');
      print('  - avatar: ${userEntity.avatar}');
      print('  - cleanerId: ${userEntity.cleanerId}');

      return Right(userEntity);
    } catch (e) {
      print('❌ Login error: $e');
      return Left(Failure(e.toString()));
    }
  }
}