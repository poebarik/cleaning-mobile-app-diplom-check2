import 'package:dartz/dartz.dart';
import '../failure.dart';

class SelectCleanerUseCase {
  SelectCleanerUseCase();

  Future<Either<Failure, void>> execute(int orderId, int responseId) async {
    try {
      // TODO: Implement repository call
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}