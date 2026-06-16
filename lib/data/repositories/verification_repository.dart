// data/repositories/verification_repository.dart
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../models/verification/cleaner_verification.dart';
import '../../core/constants/api_constants.dart';

class VerificationRepository {
  final Dio _dio = DioClient.instance;

  Future<CleanerVerification> submitVerification(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.submitVerification}',
      data: data,
    );
    return CleanerVerification.fromJson(response.data);
  }

  Future<CleanerVerification?> getMyVerification() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.myVerification}',
      );
      return CleanerVerification.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<CleanerVerification>> getPendingVerifications() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.pendingVerifications}',
      );
      return (response.data as List)
          .map((e) => CleanerVerification.fromJson(e))
          .toList();
    } catch (e) {
      print('Error loading pending verifications: $e');
      return [];
    }
  }

  Future<void> reviewVerification(int id, String status, String comment) async {
    final url = ApiConstants.reviewVerification.replaceFirst('{id}', id.toString());
    await _dio.patch(
      '${ApiConstants.baseUrl}$url',
      data: {
        'status': status,
        'adminComment': comment,
      },
    );
  }
}