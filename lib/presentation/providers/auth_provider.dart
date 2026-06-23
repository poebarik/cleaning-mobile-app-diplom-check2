// lib/presentation/providers/auth_provider.dart

import 'package:cleaning_mobile_application/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user/user.dart';
import '../../domain/enums/user_role.dart';
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
      ) : super(const AuthStateUnauthenticated());

  Future<void> login(String email, String password) async {
    state = const AuthStateLoading();
    final result = await _loginUseCase.execute(email, password);
    result.fold(
          (failure) => state = AuthStateError(failure.message),
          (user) {
        // ✅ user уже должен быть UserEntity, если LoginUseCase возвращает UserEntity
        // Если нет - конвертируем
        final userEntity = user is UserEntity
            ? user
            : _convertUserToEntity(user as User);

        print('✅ Login success:');
        print('  - id: ${userEntity.id}');
        print('  - avatar: ${userEntity.avatar}');
        state = AuthStateAuthenticated(user: userEntity);
      },
    );
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AuthStateLoading();
    final result = await _registerUseCase.execute(data);
    result.fold(
          (failure) => state = AuthStateError(failure.message),
          (user) {
        final userEntity = user is UserEntity
            ? user
            : _convertUserToEntity(user as User);
        state = AuthStateAuthenticated(user: userEntity);
      },
    );
  }

  Future<void> logout() async {
    await _logoutUseCase.execute();
    state = const AuthStateUnauthenticated();
  }

  Future<bool> checkAuthStatus() async {
    final hasToken = await _logoutUseCase.hasToken();
    if (hasToken) {
      return true;
    } else {
      state = const AuthStateUnauthenticated();
      return false;
    }
  }

  void updateUser(UserEntity user) {
    print('🔄 Updating user:');
    print('  - id: ${user.id}');
    print('  - avatar: ${user.avatar}');
    state = AuthStateAuthenticated(user: user);
  }

  // ─── КОНВЕРТЕР User → UserEntity ─────────────────────────────────

  UserEntity _convertUserToEntity(User user) {
    print('📸 Converting User to UserEntity:');
    print('  - User.avatarUrl: ${user.avatarUrl}');

    return UserEntity(
      id: user.id,
      fullName: user.fullName,
      email: user.email ?? '',
      phone: user.phone ?? '',
      role: _stringToUserRole(user.role),
      isActive: !user.isBlocked,
      avatar: user.avatarUrl,
      rating: user.rating,
      completedOrders: user.completedOrders,
      cleanerId: user.cleanerId,
      description: user.description,
    );
  }

  UserRole _stringToUserRole(String role) {
    switch (role.toUpperCase()) {
      case 'CLIENT': return UserRole.client;
      case 'CLEANER': return UserRole.cleaner;
      case 'MANAGER': return UserRole.manager;
      case 'ADMIN': return UserRole.admin;
      default: return UserRole.client;
    }
  }

  String _userRoleToString(UserRole role) {
    switch (role) {
      case UserRole.client: return 'CLIENT';
      case UserRole.cleaner: return 'CLEANER';
      case UserRole.manager: return 'MANAGER';
      case UserRole.admin: return 'ADMIN';
    }
  }
}

// ─── СОСТОЯНИЯ ──────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final UserEntity user;

  const AuthStateAuthenticated({required this.user});
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String error;

  const AuthStateError(this.error);
}

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