import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/cleaner/cleaner.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/enums/order_action.dart';

final cleanerProvider = StateNotifierProvider<CleanerNotifier, CleanerState>((ref) {
  return CleanerNotifier();
});

class CleanerNotifier extends StateNotifier<CleanerState> {
  CleanerNotifier() : super(const CleanerStateInitial());

  Future<void> loadCleaners({bool? availableOnly}) async {
    state = const CleanerStateLoading();
    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.cleaners}',
        queryParameters: availableOnly != null ? {'availableOnly': availableOnly} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final cleaners = data.map((json) => Cleaner.fromJson(json)).toList();
        state = CleanerStateLoaded(cleaners);
      } else {
        state = CleanerStateError('Ошибка загрузки клинеров');
      }
    } catch (e) {
      state = CleanerStateError(e.toString());
    }
  }

  Future<void> loadCleanerDetails(int cleanerId) async {
    state = const CleanerStateLoading();
    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.cleaners}/$cleanerId',
      );

      if (response.statusCode == 200) {
        final cleaner = Cleaner.fromJson(response.data);
        state = CleanerStateDetailsLoaded(cleaner);
      } else {
        state = CleanerStateError('Клинер не найден');
      }
    } catch (e) {
      state = CleanerStateError(e.toString());
    }
  }
  Future<void> respondToJob(int orderId, double priceOffer, String message, int cleanerId) async {
    try {
      final repository = OrderRepository();
      await repository.executeAction(
        orderId,
        OrderAction.respond,
        {
          'cleanerId': cleanerId,
          'priceOffer': priceOffer,
          'message': message,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Состояния
sealed class CleanerState {
  const CleanerState();
}

class CleanerStateInitial extends CleanerState {
  const CleanerStateInitial();
}

class CleanerStateLoading extends CleanerState {
  const CleanerStateLoading();
}

class CleanerStateLoaded extends CleanerState {
  final List<Cleaner> cleaners;
  const CleanerStateLoaded(this.cleaners);
}

class CleanerStateDetailsLoaded extends CleanerState {
  final Cleaner cleaner;
  const CleanerStateDetailsLoaded(this.cleaner);
}

class CleanerStateError extends CleanerState {
  final String error;
  const CleanerStateError(this.error);
}

// Extension
extension CleanerStateExtension on CleanerState {
  bool get isLoading => this is CleanerStateLoading;
  bool get isLoaded => this is CleanerStateLoaded;
  bool get isDetailsLoaded => this is CleanerStateDetailsLoaded;
  bool get isError => this is CleanerStateError;

  List<Cleaner>? get cleaners {
    if (this is CleanerStateLoaded) {
      return (this as CleanerStateLoaded).cleaners;
    }
    return null;
  }

  Cleaner? get cleaner {
    if (this is CleanerStateDetailsLoaded) {
      return (this as CleanerStateDetailsLoaded).cleaner;
    }
    return null;
  }

  String? get error {
    if (this is CleanerStateError) {
      return (this as CleanerStateError).error;
    }
    return null;
  }

}