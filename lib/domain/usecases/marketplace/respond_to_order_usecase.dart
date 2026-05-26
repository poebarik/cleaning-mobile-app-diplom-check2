import 'package:dartz/dartz.dart';
import '../failure.dart';

class RespondToOrderUseCase {
  RespondToOrderUseCase();

  Future<Either<Failure, void>> execute(int orderId, Map<String, dynamic> data) async {
    try {
      // TODO: Implement repository call
      return const Right(null);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}