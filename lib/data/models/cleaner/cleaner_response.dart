// lib/data/models/cleaner/cleaner_response.dart
class CleanerResponse {
  final int id;
  final int? userId;  // ← Убедитесь, что это поле есть!
  final String fullName;
  final String? email;
  final String? phone;
  final double? rating;
  final bool? isAvailable;
  final String? avatarUrl;
  final int? completedOrders;
  final String? verificationStatus;

  CleanerResponse({
    required this.id,
    this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.rating,
    this.isAvailable,
    this.avatarUrl,
    this.completedOrders,
    this.verificationStatus,
  });

  factory CleanerResponse.fromJson(Map<String, dynamic> json) {
    print('📦 Parsing CleanerResponse:');
    print('  - id: ${json['id']}');
    print('  - userId: ${json['userId']}');
    print('  - fullName: ${json['fullName']}');

    return CleanerResponse(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int?,  // ← Убедитесь, что парсится!
      fullName: json['fullName'] as String? ?? json['cleanerName'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool?,
      avatarUrl: json['avatarUrl'] as String?,
      completedOrders: json['completedOrders'] as int?,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }
}