import '../datasources/remote/auth_api.dart';
import '../models/auth/auth_response.dart';
import '../network/dio_client.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository implements IAuthRepository {
  late final AuthApi _authApi;
  final FlutterSecureStorage _secureStorage;

  AuthRepository()
      : _secureStorage = const FlutterSecureStorage() {
    _authApi = AuthApi(DioClient.instance);
  }

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _authApi.login({
        'email': email,
        'password': password,
      });
      await _saveTokens(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponse> register(Map<String, dynamic> data) async {
    try {
      final response = await _authApi.register(data);
      await _saveTokens(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> _saveTokens(AuthResponse response) async {
    await _secureStorage.write(key: 'access_token', value: response.token);
    // Если есть refresh token
    // await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);
  }
}