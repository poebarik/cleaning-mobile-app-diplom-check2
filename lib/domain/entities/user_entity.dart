import '../enums/user_role.dart';

class UserEntity {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isActive;
  final String? avatar;
  final double? rating;
  final int? completedOrders;
  final int? cleanerId;  // ✅ ДОЛЖНО БЫТЬ

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
    this.cleanerId,  // ✅ ДОЛЖНО БЫТЬ
  });
}