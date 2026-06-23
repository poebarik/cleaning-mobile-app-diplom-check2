// lib/data/models/service/service_category.dart
class ServiceCategory {
  final String name;
  final String icon;
  final String? id;

  ServiceCategory({
    required this.name,
    required this.icon,
    this.id,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🧹',
      id: json['id'],
    );
  }
}