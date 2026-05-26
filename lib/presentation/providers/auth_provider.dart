import 'package:cleaning_mobile_application/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/entities/user_entity.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.read(loginUseCaseProvider);
  final registerUseCase = ref.read(registerUseCaseProvider);
  final logoutUseCase = ref.read(logoutUseCaseProvider);
  return AuthNotifier(loginUseCase, registerUseCase, logoutUseCase);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthNotifier(
      this._loginUseCase,
      this._registerUseCase,
      this._logoutUseCase,
      ) : super(const AuthStateUnauthenticated()); // Изменено с initial на Unauthenticated

  Future<void> login(String email, String password) async {
    state = const AuthStateLoading(); // Изменено с loading() на AuthStateLoading()
    final result = await _loginUseCase.execute(email, password);
    result.fold(
          (failure) => state = AuthStateError(failure.message),
          (user) => state = AuthStateAuthenticated(user),
    );
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AuthStateLoading();
    final result = await _registerUseCase.execute(data);
    result.fold(
          (failure) => state = AuthStateError(failure.message),
          (user) => state = AuthStateAuthenticated(user),
    );
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    state = const AuthStateUnauthenticated();
  }

  void checkAuthStatus() async {
    final hasToken = await _logoutUseCase.hasToken();
    if (hasToken) {
      state = const AuthStateAuthenticated(null);
    } else {
      state = const AuthStateUnauthenticated();
    }
  }
}

// Определяем все классы состояния
sealed class AuthState {
  const AuthState();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final UserEntity? user;

  const AuthStateAuthenticated(this.user);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String error;

  const AuthStateError(this.error);
}

// Extension методы для удобной работы с состоянием
extension AuthStateExtension on AuthState {
  bool get isLoading => this is AuthStateLoading;
  bool get isAuthenticated => this is AuthStateAuthenticated;
  bool get isUnauthenticated => this is AuthStateUnauthenticated;
  bool get isError => this is AuthStateError;

  UserEntity? get user {
    final state = this;
    if (state is AuthStateAuthenticated) {
      return state.user;
    }
    return null;
  }

  String? get error {
    final state = this;
    if (state is AuthStateError) {
      return state.error;
    }
    return null;
  }
}