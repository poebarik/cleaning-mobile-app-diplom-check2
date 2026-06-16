// lib/domain/usecases/auth/reset_password_usecase.dart
import 'package:dartz/dartz.dart';
import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class ResetPasswordUseCase {
  final IAuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> execute(String token, String newPassword) async {
    try {
      await repository.resetPassword(token, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}