import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../providers/cleaner_provider.dart';
import '../../../routes/route_names.dart';
import '../common/profile_screen.dart';


class CleanerDetailsScreen extends StatelessWidget {
  final int cleanerId;

  const CleanerDetailsScreen({super.key, required this.cleanerId});

  @override
  Widget build(BuildContext context) {
    // Перенаправляем на единый экран профиля
    return ProfileScreen(userId: cleanerId);
  }
}