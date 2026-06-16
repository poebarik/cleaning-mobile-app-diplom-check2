// lib/domain/usecases/auth/forgot_password_usecase.dart
import 'package:dartz/dartz.dart';
import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class ForgotPasswordUseCase {
  final IAuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> execute(String email) async {
    try {
      await repository.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}