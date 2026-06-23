// lib/data/models/auth/auth_response.dart

import '../user/user.dart';

class AuthResponse {
  final String token;
  final String? refreshToken;
  final int? userId;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatarUrl;  // ✅ Добавляем поле
  final int? cleanerId;
  final double? rating;
  final int? completedOrders;
  final String? description;
  final User? user;  // Если сервер возвращает вложенный объект user

  AuthResponse({
    required this.token,
    this.refreshToken,
    this.userId,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.avatarUrl,
    this.cleanerId,
    this.rating,
    this.completedOrders,
    this.description,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Пробуем получить avatarUrl из разных мест
    String? avatarUrl;

    // Сначала из корня
    if (json['avatarUrl'] != null) {
      avatarUrl = json['avatarUrl'];
    }
    // Потом из user объекта
    else if (json['user'] != null && json['user']['avatarUrl'] != null) {
      avatarUrl = json['user']['avatarUrl'];
    }
    // Или из avatar
    else if (json['avatar'] != null) {
      avatarUrl = json['avatar'];
    }

    return AuthResponse(
      token: json['token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      userId: json['userId'] ?? json['user']?['id'],
      fullName: json['fullName'] ?? json['user']?['fullName'],
      email: json['email'] ?? json['user']?['email'],
      phone: json['phone'] ?? json['user']?['phone'],
      role: json['role'] ?? json['user']?['role'],
      avatarUrl: avatarUrl,  // ✅ Сохраняем
      cleanerId: json['cleanerId'] ?? json['user']?['cleanerId'],
      rating: (json['rating'] ?? json['user']?['rating'])?.toDouble(),
      completedOrders: json['completedOrders'] ?? json['user']?['completedOrders'],
      description: json['description'] ?? json['user']?['description'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatarUrl': avatarUrl,
      'cleanerId': cleanerId,
      'rating': rating,
      'completedOrders': completedOrders,
      'description': description,
      'user': user?.toJson(),
    };
  }
}