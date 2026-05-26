import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../providers/manager_provider.dart';

class AssignCleanerScreen extends ConsumerStatefulWidget {
  final int orderId;
  const AssignCleanerScreen({super.key, required this.orderId});

  @override
  ConsumerState<AssignCleanerScreen> createState() => _AssignCleanerScreenState();
}

class _AssignCleanerScreenState extends ConsumerState<AssignCleanerScreen> {
  int? _selectedCleanerId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(managerProvider.notifier).loadAvailableCleaners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Назначить клинера'),
        elevation: 0,
      ),
      body: managerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : managerState.cleaners == null || managerState.cleaners!.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет доступных клинеров'),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: managerState.cleaners!.length,
              itemBuilder: (context, index) {
                final cleaner = managerState.cleaners![index];
                return RadioListTile<int>(
                  title: Text(cleaner['fullName']),
                  subtitle: Text('${cleaner['pricePerHour']} ₽/час'),
                  value: cleaner['id'],
                  groupValue: _selectedCleanerId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCleanerId = value;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedCleanerId == null
                  ? null
                  : () async {
                await ref
                    .read(managerProvider.notifier)
                    .assignCleaner(widget.orderId, _selectedCleanerId!);
                if (context.mounted) {
                  CustomSnackbar.showSuccess(context, 'Клинер назначен');
                  context.go(RouteNames.managerDashboard);
                }
              },
              child: const Text('Назначить'),
            ),
          ),
        ],
      ),
    );
  }
}