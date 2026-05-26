import '../../data/models/auth/auth_response.dart';

abstract class IAuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(Map<String, dynamic> data);
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isLoggedIn();
}