import 'package:dartz/dartz.dart';
import '../../entities/order_entity.dart';
import '../failure.dart';

class CreateMarketplaceOrderUseCase {
  CreateMarketplaceOrderUseCase();

  Future<Either<Failure, OrderEntity>> execute(Map<String, dynamic> data) async {
    try {
      // TODO: Implement repository call
      return Left(const Failure('Not implemented yet'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}