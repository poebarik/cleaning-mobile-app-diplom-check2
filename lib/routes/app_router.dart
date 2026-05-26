import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/screens/client/order_details_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/client/home_screen.dart';
import '../presentation/screens/client/create_order_screen.dart';
import '../presentation/screens/client/create_company_order_screen.dart';
import '../presentation/screens/client/create_marketplace_order_screen.dart';
import '../presentation/screens/client/my_orders_screen.dart';
import '../presentation/screens/client/cleaner_list_screen.dart';
import '../presentation/screens/client/cleaner_details_screen.dart';
import '../presentation/screens/cleaner/home_screen.dart';
import '../presentation/screens/cleaner/open_jobs_screen.dart';
import '../presentation/screens/cleaner/assigned_orders_screen.dart';
import '../presentation/screens/admin/dashboard_screen.dart';
import '../presentation/screens/cleaner/job_details_screen.dart';
import '../presentation/screens/manager/manager_dashboard_screen.dart';
import '../presentation/screens/manager/pending_orders_screen.dart';
import '../presentation/screens/manager/assign_cleaner_screen.dart';
import '../presentation/screens/manager/cleaners_workload_screen.dart';
import '../presentation/screens/manager/manager_stats_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      return RouteGuard.handleRedirect(ref, state);
    },
    routes: [
      // Auth routes
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Client routes
      GoRoute(
        path: RouteNames.clientHome,
        name: RouteNames.clientHome,
        builder: (context, state) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.createOrder,
        name: RouteNames.createOrder,
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: RouteNames.createCompanyOrder,
        name: RouteNames.createCompanyOrder,
        builder: (context, state) => const CreateCompanyOrderScreen(),
      ),
      GoRoute(
        path: RouteNames.createMarketplaceOrder,
        name: RouteNames.createMarketplaceOrder,
        builder: (context, state) => const CreateMarketplaceOrderScreen(),
      ),
      GoRoute(
        path: RouteNames.myOrders,
        name: RouteNames.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.cleanerList,
        name: RouteNames.cleanerList,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          return CleanerListScreen(orderId: orderId != null ? int.parse(orderId) : null);
        },
      ),
      GoRoute(
        path: '${RouteNames.cleanerDetails}/:id',
        name: RouteNames.cleanerDetails,
        builder: (context, state) {
          final cleanerId = int.parse(state.pathParameters['id']!);
          return CleanerDetailsScreen(cleanerId: cleanerId);
        },
      ),

      // Cleaner routes
      GoRoute(
        path: '${RouteNames.orderDetails}/:id',
        name: RouteNames.orderDetails,
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['id']!);
          // Получаем данные заказа из extra если есть
          final extraData = state.extra as Map<String, dynamic>?;
          return OrderDetailsScreen(orderId: orderId, orderData: extraData);
        },
      ),
      GoRoute(
        path: '${RouteNames.jobDetails}/:id',
        name: RouteNames.jobDetails,
        builder: (context, state) {
          final jobId = int.parse(state.pathParameters['id']!);
          return JobDetailsScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: RouteNames.cleanerHome,
        name: RouteNames.cleanerHome,
        builder: (context, state) => const CleanerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.openJobs,
        name: RouteNames.openJobs,
        builder: (context, state) => const OpenJobsScreen(),
      ),
      GoRoute(
        path: RouteNames.assignedOrders,
        name: RouteNames.assignedOrders,
        builder: (context, state) => const AssignedOrdersScreen(),
      ),

      // Admin routes
      GoRoute(
        path: RouteNames.adminDashboard,
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

// Manager routes
      GoRoute(
        path: RouteNames.managerDashboard,
        name: RouteNames.managerDashboard,
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.pendingOrders,
        name: RouteNames.pendingOrders,
        builder: (context, state) => const PendingOrdersScreen(),
      ),
      GoRoute(
        path: '${RouteNames.assignCleaner}/:orderId',
        name: RouteNames.assignCleaner,
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          return AssignCleanerScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: RouteNames.cleanersWorkload,
        name: RouteNames.cleanersWorkload,
        builder: (context, state) => const CleanersWorkloadScreen(),
      ),
      GoRoute(
        path: RouteNames.managerStats,
        name: RouteNames.managerStats,
        builder: (context, state) => const ManagerStatsScreen(),
      ),

      GoRoute(
        path: RouteNames.home,
        name: RouteNames.home,
        redirect: (context, state) {
          // TODO: Определить роль пользователя и перенаправить на соответствующий home
          return RouteNames.clientHome;
        },
      ),
    ],
  );
});