import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../providers/cleaner_provider.dart';
import '../../../data/models/cleaner/cleaner.dart';

class CleanerListScreen extends ConsumerStatefulWidget {
  final int? orderId;
  const CleanerListScreen({super.key, this.orderId});

  @override
  ConsumerState<CleanerListScreen> createState() => _CleanerListScreenState();
}

class _CleanerListScreenState extends ConsumerState<CleanerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cleanerProvider.notifier).loadCleaners(availableOnly: true));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          if (state.isLoading)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate((_, __) => _shimmerCard(), childCount: 5)),
            )
          else if (state.isError)
            SliverToBoxAdapter(child: _buildError(state.error ?? '', ref))
          else if (state.cleaners == null || state.cleaners!.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _buildCleanerCard(state.cleaners![i]),
                    childCount: state.cleaners!.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Выбрать клинера', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  const Text('Доступные специалисты', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('${RouteNames.cleanerDetails}/${cleaner.id}', extra: {'orderId': widget.orderId}),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cleaner.fullName.isNotEmpty ? cleaner.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cleaner.fullName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                          const SizedBox(width: 3),
                          Text(cleaner.rating?.toStringAsFixed(1) ?? '—', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
                          const SizedBox(width: 10),
                          const Icon(Icons.cleaning_services_rounded, size: 13, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Text('${cleaner.completedOrders ?? 0} заказов', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      if (cleaner.pricePerHour != null) ...[
                        const SizedBox(height: 4),
                        Text('${cleaner.pricePerHour} ₽/час', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: cleaner.isAvailable == true ? AppColors.success : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cleaner.isAvailable == true ? 'Свободен' : 'Занят', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: cleaner.isAvailable == true ? AppColors.success : AppColors.textHint)),
                    const SizedBox(height: 10),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 90, margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _buildError(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => ref.read(cleanerProvider.notifier).loadCleaners(availableOnly: true), child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.people_outline_rounded, size: 50, color: AppColors.primary)),
            const SizedBox(height: 20),
            const Text('Нет доступных клинеров', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}