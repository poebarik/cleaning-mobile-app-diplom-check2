// lib/domain/entities/user_entity.dart
import '../enums/user_role.dart';

class UserEntity {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final String? avatar;  // ← Здесь будет полный URL
  final double? rating;
  final int? completedOrders;
  final int? cleanerId;
  final String? description;
  final bool? isVerified;
  final String? verificationStatus;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    this.avatar,
    this.rating,
    this.completedOrders,
    this.cleanerId,
    this.description,
    this.isVerified,
    this.verificationStatus,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    // ✅ Берем avatarUrl из ответа сервера
    String? avatarUrl = json['avatarUrl'] as String?;

    // Если нет avatarUrl, пробуем avatarObjectName
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final avatarObjectName = json['avatarObjectName'] as String?;
      if (avatarObjectName != null && avatarObjectName.isNotEmpty) {
        // Если это просто имя объекта, формируем URL
        if (!avatarObjectName.startsWith('http')) {
          avatarUrl = 'http://localhost:9000/cleaning-app/$avatarObjectName';
        } else {
          avatarUrl = avatarObjectName;
        }
      }
    }

    // ✅ Если avatarUrl все еще null, пробуем avatar из корня
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final avatarRaw = json['avatar'] as String?;
      if (avatarRaw != null && avatarRaw.isNotEmpty) {
        if (!avatarRaw.startsWith('http')) {
          avatarUrl = 'http://localhost:9000/cleaning-app/$avatarRaw';
        } else {
          avatarUrl = avatarRaw;
        }
      }
    }

    print('📸 UserEntity.fromJson:');
    print('  - avatarUrl from server: ${json['avatarUrl']}');
    print('  - avatarUrl after processing: $avatarUrl');
    print('  - fullName: ${json['fullName']}');

    // ✅ Парсим isVerified с проверкой на null
    bool? isVerified = json['isVerified'] as bool?;
    if (isVerified == null) {
      // Пробуем получить из verificationStatus
      final verificationStatus = json['verificationStatus'] as String?;
      if (verificationStatus != null) {
        isVerified = verificationStatus == 'VERIFIED';
      }

    }


    return UserEntity(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      avatar: avatarUrl,
      rating: (json['rating'] ?? 0).toDouble(),
      completedOrders: json['completedOrders'] ?? json['completed_orders'],
      cleanerId: json['cleanerId'] ?? json['cleaner_id'],
      description: json['description'],
      isVerified: isVerified,
      verificationStatus: json['verificationStatus'] as String?,

    );
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.client;
    final roleStr = role.toString().toUpperCase();
    switch (roleStr) {
      case 'CLIENT': return UserRole.client;
      case 'CLEANER': return UserRole.cleaner;
      case 'MANAGER': return UserRole.manager;
      case 'ADMIN': return UserRole.admin;
      default: return UserRole.client;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'avatar': avatar,
      'rating': rating,
      'completedOrders': completedOrders,
      'cleanerId': cleanerId,
      'description': description,
      'isVerified': isVerified,
    };
  }
}