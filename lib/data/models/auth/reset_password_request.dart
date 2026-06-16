// lib/data/models/auth/reset_password_request.dart
class ResetPasswordRequest {
  final String token;
  final String newPassword;

  ResetPasswordRequest({required this.token, required this.newPassword});

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
  };
}