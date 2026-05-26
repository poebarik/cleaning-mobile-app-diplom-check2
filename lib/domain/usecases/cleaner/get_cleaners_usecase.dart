import 'package:dartz/dartz.dart';
import '../../entities/cleaner_entity.dart';
import '../failure.dart';

class GetCleanersUseCase {
  GetCleanersUseCase();

  Future<Either<Failure, List<CleanerEntity>>> execute({bool? availableOnly}) async {
    try {
      // TODO: Implement repository call
      return Right([]);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}