import 'package:dio/dio.dart';
import '../../models/order/order.dart';
import '../../../core/constants/api_constants.dart';

class OrderApi {
  final Dio _dio;

  OrderApi(this._dio);

  Future<Order> createCompanyOrder(Map<String, dynamic> request) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.orders}',
      data: request,
    );
    return Order.fromJson(response.data);
  }

  Future<List<Order>> getClientOrders() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.clientOrders}',
    );
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> getOrderById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$id',
    );
    return Order.fromJson(response.data);
  }

  Future<Order> updateOrderStatus(int id, Map<String, dynamic> request) async {
    final response = await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$id/status',
      data: request,
    );
    return Order.fromJson(response.data);
  }
}