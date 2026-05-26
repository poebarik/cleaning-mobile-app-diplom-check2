import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import '../../core/constants/api_constants.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Добавляем логирование для отладки
      _dio!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          print('📤 REQUEST: ${options.method} ${options.uri}');
          print('📤 HEADERS: ${options.headers}');
          print('📤 BODY: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          print('📥 DATA: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR: ${error.message}');
          print('❌ URI: ${error.requestOptions.uri}');
          if (error.response != null) {
            print('❌ STATUS: ${error.response!.statusCode}');
            print('❌ DATA: ${error.response!.data}');
          }
          handler.next(error);
        },
      ));

      const secureStorage = FlutterSecureStorage();

      _dio!.interceptors.add(AuthInterceptor(secureStorage));
      _dio!.interceptors.add(LoggingInterceptor());
      _dio!.interceptors.add(ErrorInterceptor());
    }
    return _dio!;
  }
}