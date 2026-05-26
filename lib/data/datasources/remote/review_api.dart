import 'package:dio/dio.dart';
import '../../models/cleaner/cleaner.dart';
import '../../../core/constants/api_constants.dart';

class ReviewApi {
  final Dio _dio;

  ReviewApi(this._dio);

  Future<void> createReview(Map<String, dynamic> request) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.reviews}',
      data: request,
    );
  }

  Future<List<Review>> getCleanerReviews(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/cleaners/$id',
    );
    return (response.data as List).map((e) => Review.fromJson(e)).toList();
  }
}