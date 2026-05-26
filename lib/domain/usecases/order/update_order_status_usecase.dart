import 'package:dartz/dartz.dart';
import '../../entities/order_entity.dart';
import '../failure.dart';

class UpdateOrderStatusUseCase {
  UpdateOrderStatusUseCase();

  Future<Either<Failure, OrderEntity>> execute(int orderId, String status) async {
    try {
      // TODO: Implement repository call
      return Left(const Failure('Not implemented yet'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}