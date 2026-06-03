import 'package:cleaning_mobile_application/domain/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat.dart';
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
import '../presentation/screens/client/order_details_screen.dart';
import '../presentation/screens/cleaner/home_screen.dart';
import '../presentation/screens/cleaner/open_jobs_screen.dart';
import '../presentation/screens/cleaner/assigned_orders_screen.dart';
import '../presentation/screens/cleaner/job_details_screen.dart';
import '../presentation/screens/admin/dashboard_screen.dart';
import '../presentation/screens/manager/manager_dashboard_screen.dart';
import '../presentation/screens/manager/pending_orders_screen.dart';
import '../presentation/screens/manager/assign_cleaner_screen.dart';
import '../presentation/screens/manager/cleaners_workload_screen.dart';
import '../presentation/screens/manager/manager_stats_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';

import '../presentation/screens/client/invitation_details_screen.dart';
import '../presentation/screens/client/invitation_screen.dart';
import '../presentation/screens/cleaner/my_invitations_screen.dart';
import '../presentation/screens/chat/chat_list_screen.dart';
import '../presentation/screens/chat/chat_detail_screen.dart';
import '../presentation/providers/auth_provider.dart';

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

      // Order routes
      GoRoute(
        path: '${RouteNames.orderDetails}/:id',
        name: RouteNames.orderDetails,
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['id']!);
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

      // Cleaner routes
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

      // Notifications
      GoRoute(
        path: RouteNames.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // V4 - Invitation routes
      GoRoute(
        path: '${RouteNames.invitationDetails}/:id',
        name: RouteNames.invitationDetails,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          // Получаем роль пользователя из authProvider
          final authState = ref.read(authProvider);
          final userRole = authState.user?.role.value ?? 'CLIENT';
          return InvitationDetailsScreen(invitationId: id, userRole: userRole);
        },
      ),
      GoRoute(
        path: RouteNames.myInvitations,
        name: RouteNames.myInvitations,
        builder: (context, state) => const MyInvitationsScreen(),
      ),
      GoRoute(
        path: '${RouteNames.createInvitation}/:orderId/:cleanerId',
        name: RouteNames.createInvitation,
        builder: (context, state) {
          final orderId = int.parse(state.pathParameters['orderId']!);
          final cleanerId = int.parse(state.pathParameters['cleanerId']!);
          final cleanerName = state.uri.queryParameters['cleanerName'] ?? '';
          final cleanerRating = double.tryParse(state.uri.queryParameters['cleanerRating'] ?? '');
          return InvitationScreen(
            orderId: orderId,
            cleanerId: cleanerId,
            cleanerName: cleanerName,
            cleanerRating: cleanerRating,
          );
        },
      ),

      // V5 - Chat routes
      GoRoute(
        path: RouteNames.chatList,
        name: RouteNames.chatList,
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '${RouteNames.chatDetail}/:id',
        name: RouteNames.chatDetail,
        builder: (context, state) {
          final chatId = int.parse(state.pathParameters['id']!);
          final chat = state.extra as Chat?;
          return ChatDetailScreen(chatId: chatId, chat: chat!);
        },
      ),

      // Home redirect
      GoRoute(
        path: RouteNames.home,
        name: RouteNames.home,
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          final userRole = authState.user?.role.value ?? 'CLIENT';

          switch (userRole) {
            case 'CLIENT':
              return RouteNames.clientHome;
            case 'CLEANER':
              return RouteNames.cleanerHome;
            case 'MANAGER':
              return RouteNames.managerDashboard;
            case 'ADMIN':
              return RouteNames.adminDashboard;
            default:
              return RouteNames.clientHome;
          }
        },
      ),
    ],
  );
});