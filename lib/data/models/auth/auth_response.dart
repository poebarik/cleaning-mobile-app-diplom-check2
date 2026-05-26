import '../../../domain/entities/user_entity.dart';
import '../../../domain/enums/user_role.dart';

class AuthResponse {
  final String token;
  final String? email;
  final String? fullName;
  final String? role;

  AuthResponse({
    required this.token,
    this.email,
    this.fullName,
    this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'fullName': fullName,
      'role': role,
    };
  }

  UserModel toUserModel() {
    return UserModel(
      id: 0, // Временно, пока бэкенд не возвращает id
      fullName: fullName ?? '',
      email: email ?? '',
      phone: '', // Бэкенд не возвращает phone
      role: role ?? 'CLIENT',
      isActive: true,
      avatar: null,
      rating: null,
      completedOrders: null,
    );
  }
}

// Добавьте этот класс если его нет
class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final String? avatar;
  final double? rating;
  final int? completedOrders;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.avatar,
    this.rating,
    this.completedOrders,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      avatar: json['avatar'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      completedOrders: json['completedOrders'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'avatar': avatar,
      'rating': rating,
      'completedOrders': completedOrders,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: UserRoleExtension.fromString(role),
      isActive: isActive,
      avatar: avatar,
      rating: rating,
      completedOrders: completedOrders,
    );
  }
}