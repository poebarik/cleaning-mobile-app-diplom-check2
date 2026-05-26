import 'package:dartz/dartz.dart';
import '../../entities/order_entity.dart';
import '../failure.dart';

class GetOpenOrdersUseCase {
  GetOpenOrdersUseCase();

  Future<Either<Failure, List<OrderEntity>>> execute() async {
    try {
      // TODO: Implement repository call
      return Right([]);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}