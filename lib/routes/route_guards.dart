import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_provider.dart';
import 'route_names.dart';

class RouteGuard {
  static String? handleRedirect(ProviderRef ref, GoRouterState state) {
    final authState = ref.read(authProvider);

    // Проверяем авторизацию через extension
    final isAuthenticated = authState.isAuthenticated;

    // Проверяем, является ли маршрут auth-маршрутом
    final isAuthRoute = state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.register ||
        state.matchedLocation == RouteNames.splash;

    // Если пользователь не авторизован и пытается зайти на защищенный маршрут
    if (!isAuthenticated && !isAuthRoute) {
      return RouteNames.login;
    }

    // Если пользователь авторизован и пытается зайти на страницу логина/регистрации
    if (isAuthenticated && isAuthRoute && state.matchedLocation != RouteNames.splash) {
      return RouteNames.home;
    }

    return null;
  }
}