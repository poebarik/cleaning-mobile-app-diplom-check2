// data/models/user/user_profile_response.dart

import '../cleaner/cleaner.dart';

class UserProfileResponse {
  final int id;
  final String fullName;
  final String email;

  final String? avatarUrl;
  final double? rating;

  final int totalReviews;
  final List<Review> recentReviews;

  UserProfileResponse({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.rating,
    required this.totalReviews,
    required this.recentReviews,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      recentReviews: json['recentReviews'] != null
          ? (json['recentReviews'] as List)
          .map((e) => Review.fromJson(e))
          .toList()
          : [],
    );
  }
}