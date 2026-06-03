import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../models/file/file_upload_response.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:typed_data';

class FileApi {
  final Dio _dio;

  FileApi(this._dio);

  Future<List<FileUploadResponse>> uploadFiles(
      List<MapEntry<String, Uint8List>> files, {
        String? folder,
      }) async {
    final formData = FormData();

    for (final file in files) {
      final extension = file.key.split('.').last;

      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            file.value,
            filename: file.key,
            contentType: MediaType('image', extension),
          ),
        ),
      );
    }

    final queryParams =
    folder != null ? {'folder': folder} : <String, dynamic>{};

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.uploadFile}',
      data: formData,
      queryParameters: queryParams,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    final List<FileUploadResponse> uploadedFiles = [];

    if (response.data is List) {
      for (final item in response.data) {
        if (item is Map) {
          uploadedFiles.add(
            FileUploadResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    } else if (response.data is Map) {
      uploadedFiles.add(
        FileUploadResponse.fromJson(
          Map<String, dynamic>.from(response.data),
        ),
      );
    }

    return uploadedFiles;
  }

  String getFileUrl(String objectName) {
    return '${ApiConstants.baseUrl}${ApiConstants.getFile.replaceFirst('{objectName}', objectName)}';
  }

  Future<void> deleteFile(String objectName) async {
    await _dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.deleteFile}',
      data: {
        'objectName': objectName,
      },
    );
  }
}