import 'package:cleaning_mobile_application/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/admin/get_statistics_usecase.dart';

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final getStatistics = ref.read(getStatisticsUseCaseProvider);
  return AdminNotifier(getStatistics);
});

class AdminNotifier extends StateNotifier<AdminState> {
  final GetStatisticsUseCase _getStatistics;

  AdminNotifier(this._getStatistics) : super(const AdminState.initial());

  Future<void> loadStatistics() async {
    state = const AdminState.loading();
    final result = await _getStatistics.execute();
    result.fold(
          (failure) => state = AdminState.error(failure.message),
          (stats) => state = AdminState.loaded(stats),
    );
  }
}

class AdminState {
  final bool isLoading;
  final Map<String, dynamic>? statistics;
  final String? error;

  const AdminState({
    required this.isLoading,
    this.statistics,
    this.error,
  });

  const AdminState.initial() : this(isLoading: false);
  const AdminState.loading() : this(isLoading: true);
  const AdminState.loaded(Map<String, dynamic> statistics)
      : this(isLoading: false, statistics: statistics);
  const AdminState.error(String error)
      : this(isLoading: false, error: error);
}