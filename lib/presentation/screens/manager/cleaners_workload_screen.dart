import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/manager_provider.dart';

class CleanersWorkloadScreen extends ConsumerStatefulWidget {
  const CleanersWorkloadScreen({super.key});

  @override
  ConsumerState<CleanersWorkloadScreen> createState() =>
      _CleanersWorkloadScreenState();
}

class _CleanersWorkloadScreenState
    extends ConsumerState<CleanersWorkloadScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(managerProvider.notifier).loadAvailableCleaners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);
    final cleaners = managerState.cleaners ?? [];
    final filtered = _searchQuery.isEmpty
        ? cleaners
        : cleaners.where((c) {
            final name = (c['fullName'] ?? '').toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cleaners.length),
            _buildSearchBar(),
            Expanded(
              child: managerState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : cleaners.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            await ref
                                .read(managerProvider.notifier)
                                .loadAvailableCleaners();
                          },
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildCleanerCard(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF0984E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3000B894),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Клинеры',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count сотрудников',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(managerProvider.notifier).loadAvailableCleaners(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.refresh,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Search ───────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Поиск клинера...',
          hintStyle: const TextStyle(
              color: AppColors.textHint, fontFamily: 'Poppins'),
          prefixIcon: const Icon(CupertinoIcons.search,
              color: AppColors.textHint, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid,
                      color: AppColors.textHint, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  // ─────────────────────── Cleaner card ─────────────────────────────────────

  Widget _buildCleanerCard(Map<String, dynamic> cleaner) {
    final name = cleaner['fullName'] ?? 'Клинер';
    final activeOrders = cleaner['activeOrders'] ?? 0;
    final completedOrders = cleaner['completedOrders'] ?? 0;
    final rating = (cleaner['rating'] ?? 0.0).toDouble();
    final pricePerHour = cleaner['pricePerHour'];

    // Workload: active / max(5)
    final double workloadRatio = (activeOrders as num).clamp(0, 5) / 5.0;
    final workloadColor = workloadRatio > 0.7
        ? const Color(0xFFE17055)
        : workloadRatio > 0.4
            ? const Color(0xFFF39C12)
            : const Color(0xFF00B894);

    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B894), Color(0xFF0984E3)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _chip(
                            CupertinoIcons.star_fill,
                            rating.toStringAsFixed(1),
                            const Color(0xFFF39C12),
                          ),
                          const SizedBox(width: 6),
                          _chip(
                            CupertinoIcons.checkmark_circle_fill,
                            '$completedOrders',
                            const Color(0xFF00B894),
                          ),
                          if (pricePerHour != null) ...[
                            const SizedBox(width: 6),
                            _chip(
                              CupertinoIcons.money_dollar_circle_fill,
                              '$pricePerHour ₽/ч',
                              AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Active orders badge
                Column(
                  children: [
                    Text(
                      '$activeOrders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: workloadColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'активных',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Workload bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Загруженность',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${(workloadRatio * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: workloadColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: workloadRatio,
                    backgroundColor: const Color(0xFFF1F0FF),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(workloadColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Empty state ──────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.person_2_fill,
                size: 42, color: Color(0xFF00B894)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет данных о клинерах',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Клинеры ещё не добавлены',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}