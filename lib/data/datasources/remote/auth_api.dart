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
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send reset email');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}