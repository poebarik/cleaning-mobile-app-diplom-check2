// lib/data/models/user/user.dart
class User {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? description;
  final String role;
  final DateTime createdAt;
  final bool isBlocked;

  // Cleaner-specific
  final double? rating;
  final int? completedOrders;
  final int? experienceYears;
  final bool? isAvailable;
  final String? verificationStatus;
  final double? totalEarnings;

  User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.description,
    required this.role,
    required this.createdAt,
    this.isBlocked = false,
    this.rating,
    this.completedOrders,
    this.experienceYears,
    this.isAvailable,
    this.verificationStatus,
    this.totalEarnings,
  });

  bool get isCleaner => role.toUpperCase() == 'CLEANER';
  bool get isClient => role.toUpperCase() == 'CLIENT';
  bool get isVerified => verificationStatus == 'VERIFIED';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_object_name'] as String?,
      description: json['description'] as String?,
      role: json['role'] as String? ?? 'CLIENT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isBlocked: json['isBlocked'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      completedOrders: json['completedOrders'] as int?,
      experienceYears: json['experienceYears'] as int?,
      isAvailable: json['isAvailable'] as bool?,
      verificationStatus: json['verificationStatus'] as String?,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
    );
  }
}