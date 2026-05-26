import 'package:dartz/dartz.dart';
import '../../entities/cleaner_entity.dart';
import '../failure.dart';

class GetCleanerDetailsUseCase {
  GetCleanerDetailsUseCase();

  Future<Either<Failure, CleanerEntity>> execute(int cleanerId) async {
    try {
      // TODO: Implement repository call
      return Left(const Failure('Not implemented yet'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}