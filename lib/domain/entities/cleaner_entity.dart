class CleanerEntity {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final double? rating;
  final int? completedOrders;
  final bool? isAvailable;
  final double? pricePerHour;
  final String? bio;
  final List<String>? services;

  CleanerEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    this.rating,
    this.completedOrders,
    this.isAvailable,
    this.pricePerHour,
    this.bio,
    this.services,
  });
}