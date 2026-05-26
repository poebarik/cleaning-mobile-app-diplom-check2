import 'package:dartz/dartz.dart';
import '../failure.dart';

class GetStatisticsUseCase {
  GetStatisticsUseCase();

  Future<Either<Failure, Map<String, dynamic>>> execute() async {
    try {
      // TODO: Implement repository call
      return Right({});
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}