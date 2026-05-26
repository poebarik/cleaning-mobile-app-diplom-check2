import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/marketplace_order_card.dart';
import '../../../routes/route_names.dart';
import '../../providers/marketplace_provider.dart';
import '../../providers/auth_provider.dart';

class CleanerHomeScreen extends ConsumerStatefulWidget {
  const CleanerHomeScreen({super.key});

  @override
  ConsumerState<CleanerHomeScreen> createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends ConsumerState<CleanerHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(marketplaceProvider.notifier).loadOpenOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceState = ref.watch(marketplaceProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(RouteNames.profile);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(marketplaceProvider.notifier).loadOpenOrders();
        },
        child: marketplaceState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : marketplaceState.orders != null && marketplaceState.orders!.isNotEmpty
            ? ListView.builder(
          itemCount: marketplaceState.orders!.length,
          itemBuilder: (context, index) {
            final order = marketplaceState.orders![index];
            return MarketplaceOrderCard(
              order: order,
              onTap: () {
                context.push(
                  '${RouteNames.jobDetails}/${order.id}',
                );
              },
            );
          },
        )
            : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_off_outlined, size: 80),
              SizedBox(height: 16),
              Text('Нет доступных заказов'),
            ],
          ),
        ),
      ),
    );
  }
}