// presentation/providers/verification_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/verification_repository.dart';
import '../../data/models/verification/cleaner_verification.dart';

// Определяем состояния
sealed class VerificationState {
  const VerificationState();
}

class VerificationStateInitial extends VerificationState {
  const VerificationStateInitial();
}

class VerificationStateLoading extends VerificationState {
  const VerificationStateLoading();
}

class VerificationStateLoaded extends VerificationState {
  final CleanerVerification? verification;
  const VerificationStateLoaded(this.verification);
}

class VerificationStateSubmitted extends VerificationState {
  final CleanerVerification verification;
  const VerificationStateSubmitted(this.verification);
}

class VerificationStateError extends VerificationState {
  final String error;
  const VerificationStateError(this.error);
}

// Extension для удобства
extension VerificationStateExtension on VerificationState {
  bool get isLoading => this is VerificationStateLoading;
  bool get isLoaded => this is VerificationStateLoaded;
  bool get isSubmitted => this is VerificationStateSubmitted;
  bool get isError => this is VerificationStateError;

  CleanerVerification? get verification {
    if (this is VerificationStateLoaded) {
      return (this as VerificationStateLoaded).verification;
    }
    if (this is VerificationStateSubmitted) {
      return (this as VerificationStateSubmitted).verification;
    }
    return null;
  }

  String? get error {
    if (this is VerificationStateError) {
      return (this as VerificationStateError).error;
    }
    return null;
  }
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier();
});

class VerificationNotifier extends StateNotifier<VerificationState> {
  final VerificationRepository _repository = VerificationRepository();

  VerificationNotifier() : super(const VerificationStateInitial());

  Future<void> loadMyVerification() async {
    state = const VerificationStateLoading();
    try {
      final verification = await _repository.getMyVerification();
      state = VerificationStateLoaded(verification);
    } catch (e) {
      state = VerificationStateError(e.toString());
    }
  }

  Future<void> submitVerification(Map<String, dynamic> data) async {
    state = const VerificationStateLoading();
    try {
      final verification = await _repository.submitVerification(data);
      state = VerificationStateSubmitted(verification);
    } catch (e) {
      state = VerificationStateError(e.toString());
    }
  }
}