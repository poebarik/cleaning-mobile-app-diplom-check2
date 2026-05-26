import 'package:dio/dio.dart';
import '../../models/cleaner/cleaner.dart';
import '../../../core/constants/api_constants.dart';

class CleanerApi {
  final Dio _dio;

  CleanerApi(this._dio);

  Future<List<Cleaner>> getCleaners({bool? availableOnly}) async {
    final queryParams = <String, dynamic>{};
    if (availableOnly != null) {
      queryParams['availableOnly'] = availableOnly;
    }

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.cleaners}',
      queryParameters: queryParams,
    );
    return (response.data as List).map((e) => Cleaner.fromJson(e)).toList();
  }

  Future<Cleaner> getCleanerById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.cleaners}/$id',
    );
    return Cleaner.fromJson(response.data);
  }
}