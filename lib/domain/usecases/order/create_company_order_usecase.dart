import 'package:dartz/dartz.dart';
import '../../entities/order_entity.dart';
import '../failure.dart';

class CreateCompanyOrderUseCase {
  CreateCompanyOrderUseCase();

  Future<Either<Failure, OrderEntity>> execute(Map<String, dynamic> data) async {
    try {
      // TODO: Implement repository call
      // final order = await repository.createCompanyOrder(data);
      // return Right(order.toEntity());

      // Temporary return
      return Left(const Failure('Not implemented yet'));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}