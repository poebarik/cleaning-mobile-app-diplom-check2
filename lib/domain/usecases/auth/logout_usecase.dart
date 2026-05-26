import 'package:dartz/dartz.dart';
import '../../repositories/i_auth_repository.dart';
import '../failure.dart';

class LogoutUseCase {
  final IAuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> execute() async {
    try {
      await repository.logout();
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<bool> hasToken() async {
    return await repository.isLoggedIn();
  }
}