class AuthResponse {
  final String token;
  final String? email;
  final String? fullName;
  final String? role;
  final int? cleanerId;
  final int? userId;

  AuthResponse({
    required this.token,
    this.email,
    this.fullName,
    this.role,
    this.cleanerId,
    this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String?,
      cleanerId: json['cleanerId'] as int?,
      userId: json['userId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'fullName': fullName,
      'role': role,
      'cleanerId': cleanerId,
      'userId': userId,
    };
  }
}