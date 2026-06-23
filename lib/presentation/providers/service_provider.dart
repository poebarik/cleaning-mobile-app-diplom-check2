// lib/presentation/providers/service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service/popular_service.dart';
import '../../data/repositories/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

// ✅ Популярные услуги
final popularServicesProvider = FutureProvider<List<PopularService>>((ref) async {
  final repository = ref.read(serviceRepositoryProvider);
  return await repository.getPopularServices();
});

// ✅ Поиск услуг
final searchServicesProvider = FutureProvider.family<List<PopularService>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.read(serviceRepositoryProvider);
  return await repository.searchServices(query);
});

// ✅ Все услуги с фильтрацией - используем StateNotifier
final allServicesProvider = StateNotifierProvider<ServicesNotifier, AsyncValue<List<PopularService>>>((ref) {
  return ServicesNotifier(ref);
});

class ServicesNotifier extends StateNotifier<AsyncValue<List<PopularService>>> {
  final Ref ref;

  ServicesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final repository = ref.read(serviceRepositoryProvider);
      final services = await repository.getAllServices();
      state = AsyncValue.data(services);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadWithFilters({
    String? category,
    String? cleaningType,
    double? minPrice,
    double? maxPrice,
    bool? isPopular,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(serviceRepositoryProvider);
      final services = await repository.getAllServices(
        category: category,
        cleaningType: cleaningType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        isPopular: isPopular,
      );
      state = AsyncValue.data(services);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    _loadServices();
  }
  void updateResults(List<PopularService> results) {
    state = AsyncValue.data(results);
  }

}

// ✅ Услуги по категории
final servicesByCategoryProvider = FutureProvider.family<List<PopularService>, String>((ref, category) async {
  final repository = ref.read(serviceRepositoryProvider);
  return await repository.getServicesByCategory(category);
});

// ✅ Список категорий
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(serviceRepositoryProvider);
  return await repository.getCategories();
});

// ✅ Типы уборки
final cleaningTypesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(serviceRepositoryProvider);
  return await repository.getCleaningTypes();
});
