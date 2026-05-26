import 'package:dio/dio.dart';
import '../../models/order/marketplace_order.dart';
import '../../../core/constants/api_constants.dart';

class MarketplaceApi {
  final Dio _dio;

  MarketplaceApi(this._dio);

  Future<MarketplaceOrder> createMarketplaceOrder(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.marketplaceOrders}',
        data: request,
      );
      return MarketplaceOrder.fromJson(response.data);
    } catch (e) {
      print('Create marketplace order error: $e');
      rethrow;
    }
  }

  Future<List<MarketplaceOrder>> getOpenOrders() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.openOrders}',
      );
      return (response.data as List).map((e) => MarketplaceOrder.fromJson(e)).toList();
    } catch (e) {
      print('Get open orders error: $e');
      rethrow;
    }
  }
}