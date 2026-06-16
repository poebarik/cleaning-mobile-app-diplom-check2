import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class FileRepository {
  final Dio _dio = DioClient.instance;

  // ✅ Теперь просто возвращаем URL для прямого доступа к файлу
  String getFileUrl(String objectName) {
    // Бэкенд теперь отдаёт файл напрямую, не нужен presigned URL
    return '${ApiConstants.baseUrl}/files/$objectName';
  }

  Future<String> getPresignedUrl(String objectName) async {
    try {
      final url = '${ApiConstants.baseUrl}/files/presigned/$objectName';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is String) {
        return response.data;
      }
      return '';
    } catch (e) {
      print('❌ Error getting presigned URL: $e');
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> uploadFiles(List<dynamic> files, String folder) async {
    final formData = FormData();

    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(file.path),
        ),
      );
    }

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.uploadFile}?folder=$folder',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    return List<Map<String, dynamic>>.from(response.data);
  }
}