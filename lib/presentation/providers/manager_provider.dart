import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/manager_api.dart';
import '../../data/network/dio_client.dart';

final managerProvider = StateNotifierProvider<ManagerNotifier, ManagerState>((ref) {
  return ManagerNotifier();
});

class ManagerNotifier extends StateNotifier<ManagerState> {
  late final ManagerApi _managerApi;

  ManagerNotifier() : super(const ManagerStateInitial()) {
    _managerApi = ManagerApi(DioClient.instance);
  }

  Future<void> loadPendingOrders() async {
    state = const ManagerStateLoading();
    try {
      final orders = await _managerApi.getPendingOrders();
      state = ManagerStatePendingOrdersLoaded(orders);
    } catch (e) {
      state = ManagerStateError(e.toString());
    }
  }

  Future<void> loadAvailableCleaners() async {
    state = const ManagerStateLoading();
    try {
      final cleaners = await _managerApi.getAvailableCleaners();
      state = ManagerStateCleanersLoaded(cleaners);
    } catch (e) {
      state = ManagerStateError(e.toString());
    }
  }

  Future<void> assignCleaner(int orderId, int cleanerId) async {
    state = const ManagerStateLoading();
    try {
      await _managerApi.assignCleanerToOrder(orderId, cleanerId);
      state = const ManagerStateAssigned();
    } catch (e) {
      state = ManagerStateError(e.toString());
    }
  }

  Future<void> loadStats() async {
    state = const ManagerStateLoading();
    try {
      final stats = await _managerApi.getStats();
      state = ManagerStateStatsLoaded(stats);
    } catch (e) {
      state = ManagerStateError(e.toString());
    }
  }
}

// States
sealed class ManagerState {
  const ManagerState();
}

class ManagerStateInitial extends ManagerState {
  const ManagerStateInitial();
}

class ManagerStateLoading extends ManagerState {
  const ManagerStateLoading();
}

class ManagerStatePendingOrdersLoaded extends ManagerState {
  final List<Map<String, dynamic>> orders;
  const ManagerStatePendingOrdersLoaded(this.orders);
}

class ManagerStateCleanersLoaded extends ManagerState {
  final List<Map<String, dynamic>> cleaners;
  const ManagerStateCleanersLoaded(this.cleaners);
}

class ManagerStateStatsLoaded extends ManagerState {
  final Map<String, dynamic> stats;
  const ManagerStateStatsLoaded(this.stats);
}

class ManagerStateAssigned extends ManagerState {
  const ManagerStateAssigned();
}

class ManagerStateError extends ManagerState {
  final String error;
  const ManagerStateError(this.error);
}

extension ManagerStateExtension on ManagerState {
  bool get isLoading => this is ManagerStateLoading;
  List<Map<String, dynamic>>? get pendingOrders {
    if (this is ManagerStatePendingOrdersLoaded) {
      return (this as ManagerStatePendingOrdersLoaded).orders;
    }
    return null;
  }
  List<Map<String, dynamic>>? get cleaners {
    if (this is ManagerStateCleanersLoaded) {
      return (this as ManagerStateCleanersLoaded).cleaners;
    }
    return null;
  }
  Map<String, dynamic>? get stats {
    if (this is ManagerStateStatsLoaded) {
      return (this as ManagerStateStatsLoaded).stats;
    }
    return null;
  }
}