import 'package:dio/dio.dart';
import '../../models/auth/auth_response.dart';
import '../../../core/constants/api_constants.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResponse> login(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> refreshToken(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.auth}/refresh',
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      print('Refresh token error: $e');
      rethrow;
    }
  }
}