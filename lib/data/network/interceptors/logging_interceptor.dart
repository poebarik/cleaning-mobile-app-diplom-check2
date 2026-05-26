import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('REQUEST: ${options.method} ${options.path}');
    _logger.d('Headers: ${options.headers}');
    _logger.d('Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    _logger.d('Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
    _logger.e('Message: ${err.message}');
    handler.next(err);
  }
}