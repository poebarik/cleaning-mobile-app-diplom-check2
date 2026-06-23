import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/invitation_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import '../../domain/usecases/order/create_company_order_usecase.dart';
import '../../domain/usecases/order/get_client_orders_usecase.dart';
import '../../domain/usecases/order/update_order_status_usecase.dart';
import '../../domain/usecases/marketplace/create_marketplace_order_usecase.dart';
import '../../domain/usecases/marketplace/respond_to_order_usecase.dart';
import '../../domain/usecases/marketplace/select_cleaner_usecase.dart';
import '../../domain/usecases/marketplace/get_open_orders_usecase.dart';
import '../../domain/usecases/cleaner/get_cleaners_usecase.dart';
import '../../domain/usecases/cleaner/get_cleaner_details_usecase.dart';
import '../../domain/usecases/admin/get_statistics_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/network/dio_client.dart';


// Auth Providers
final authRepositoryProvider = Provider((ref) => AuthRepository());

final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.read(authRepositoryProvider)));

final registerUseCaseProvider = Provider((ref) => RegisterUseCase(ref.read(authRepositoryProvider)));

final logoutUseCaseProvider = Provider((ref) => LogoutUseCase(ref.read(authRepositoryProvider)));

// Order Providers
final createCompanyOrderUseCaseProvider = Provider((ref) => CreateCompanyOrderUseCase());
final getClientOrdersUseCaseProvider = Provider((ref) => GetClientOrdersUseCase());
final updateOrderStatusUseCaseProvider = Provider((ref) => UpdateOrderStatusUseCase());

// Marketplace Providers
final createMarketplaceOrderUseCaseProvider = Provider((ref) => CreateMarketplaceOrderUseCase());
final respondToOrderUseCaseProvider = Provider((ref) => RespondToOrderUseCase());
final selectCleanerUseCaseProvider = Provider((ref) => SelectCleanerUseCase());
final getOpenOrdersUseCaseProvider = Provider((ref) => GetOpenOrdersUseCase());

// Cleaner Providers
final getCleanersUseCaseProvider = Provider((ref) => GetCleanersUseCase());
final getCleanerDetailsUseCaseProvider = Provider((ref) => GetCleanerDetailsUseCase());

// Admin Providers
final getStatisticsUseCaseProvider = Provider((ref) => GetStatisticsUseCase());

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return ForgotPasswordUseCase(authRepository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return ResetPasswordUseCase(authRepository);
});
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});
final invitationApiProvider = Provider<InvitationApi>((ref) {
  return InvitationApi(DioClient.instance);
});

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});