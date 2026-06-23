// lib/data/models/service/popular_service.dart
class PopularService {
  final int id;
  final String name;
  final String? description;
  final double? price;
  final String? icon;
  final String? imageUrl;
  final String? defaultCleaningType;
  final String? defaultLocationType;
  final bool isPopular;
  final String? category;  // ✅ Добавляем категорию

  PopularService({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.icon,
    this.imageUrl,
    this.defaultCleaningType,
    this.defaultLocationType,
    this.isPopular = false,
    this.category,
  });

  factory PopularService.fromJson(Map<String, dynamic> json) {
    return PopularService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: json['price']?.toDouble(),
      icon: json['icon'],
      imageUrl: json['imageUrl'],
      defaultCleaningType: json['defaultCleaningType'],
      defaultLocationType: json['defaultLocationType'],
      isPopular: json['isPopular'] ?? false,
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'icon': icon,
      'imageUrl': imageUrl,
      'defaultCleaningType': defaultCleaningType,
      'defaultLocationType': defaultLocationType,
      'isPopular': isPopular,
      'category': category,
    };
  }
}