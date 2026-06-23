// lib/data/repositories/file_repository.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class FileRepository {
  final Dio _dio = DioClient.instance;

  String getFileUrl(String objectName) {
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

  // ✅ Исправленный метод загрузки файлов
  Future<List<Map<String, dynamic>>> uploadFiles(List<dynamic> files, String folder) async {
    final formData = FormData();

    for (final file in files) {
      MultipartFile multipartFile;
      String fileName;
      String mimeType;

      if (kIsWeb) {
        // ✅ Для веб-платформы
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          // ✅ Получаем правильное имя файла с расширением
          fileName = file.name.isNotEmpty ? file.name : file.path.split('/').last;
          // ✅ Добавляем расширение если его нет
          if (!fileName.contains('.')) {
            // Пробуем определить тип из MIME
            final mime = file.mimeType ?? 'image/jpeg';
            final ext = _getExtensionFromMimeType(mime);
            fileName = '$fileName.$ext';
          }
          mimeType = file.mimeType ?? _getMimeType(fileName);
          print('📸 Веб-файл: $fileName, MIME: $mimeType');
          multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType),
          );
        } else if (file is File) {
          final bytes = await file.readAsBytes();
          fileName = file.path.split('/').last;
          mimeType = _getMimeType(fileName);
          multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType),
          );
        } else {
          throw Exception('Unsupported file type on web: ${file.runtimeType}');
        }
      } else {
        // ✅ Для мобильных платформ
        if (file is File) {
          fileName = file.path.split('/').last;
          mimeType = _getMimeType(fileName);
          multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType),
          );
        } else if (file is XFile) {
          fileName = file.path.split('/').last;
          mimeType = _getMimeType(fileName);
          final filePath = file.path;
          if (filePath.startsWith('http')) {
            final response = await Dio().get(
              filePath,
              options: Options(responseType: ResponseType.bytes),
            );
            final bytes = response.data as Uint8List;
            multipartFile = MultipartFile.fromBytes(
              bytes,
              filename: fileName,
              contentType: DioMediaType.parse(mimeType),
            );
          } else {
            multipartFile = await MultipartFile.fromFile(
              filePath,
              filename: fileName,
              contentType: DioMediaType.parse(mimeType),
            );
          }
        } else {
          throw Exception('Unsupported file type on mobile: ${file.runtimeType}');
        }
      }

      print('📸 Добавляем файл: $fileName, тип: $mimeType');
      formData.files.add(
        MapEntry(
          'files',
          multipartFile,
        ),
      );
    }

    final response = await _dio.post(
      '${ApiConstants.baseUrl}/files/upload?folder=$folder',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    print('📥 Ответ сервера: ${response.statusCode}');
    print('📥 Данные: ${response.data}');

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic>) {
        return [data];
      }
    }

    if (response.statusCode == 500 || response.statusCode == 400) {
      final errorData = response.data as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Unknown error';
      throw Exception(message);
    }

    return [];
  }

  // ✅ Метод для загрузки одного файла
  Future<Map<String, dynamic>?> uploadFile(dynamic file, String folder) async {
    final results = await uploadFiles([file], folder);
    return results.isNotEmpty ? results.first : null;
  }

  // ✅ Определяем MIME тип по расширению файла
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg';
    }
  }

  // ✅ Получаем расширение из MIME типа
  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }
}