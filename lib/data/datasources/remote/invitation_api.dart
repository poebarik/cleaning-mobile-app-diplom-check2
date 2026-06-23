// lib/data/datasources/remote/invitation_api.dart
import 'package:dio/dio.dart';
import '../../models/invitation/cleaner_invitation.dart';
import '../../models/order/order.dart'; // ✅ Добавляем импорт
import '../../../core/constants/api_constants.dart';
import '../../models/invitation/negotiation.dart';

class InvitationApi {
  final Dio _dio;

  InvitationApi(this._dio);

  // lib/data/datasources/remote/invitation_api.dart
  Future<CleanerInvitation> createInvitation(Map<String, dynamic> request) async {
    try {
      final orderId = request['orderId'];
      final cleanerId = request['cleanerId'];
      final proposedPrice = request['proposedPrice'];
      final message = request['message'] ?? '';

      print('📤 SENDING INVITATION:');
      print('  - orderId: $orderId');
      print('  - cleanerId: $cleanerId');
      print('  - proposedPrice: $proposedPrice');

      final response = await _dio.post(
        '/orders/$orderId/action',
        data: {
          'action': 'SEND_INVITATION',
          'payload': {
            'cleanerId': cleanerId,
            'proposedPrice': proposedPrice,  // ✅ Передаем цену
            'message': message,
          }
        },
      );

      print('✅ Invitation response: ${response.data}');

      // Парсим ответ
      final orderData = response.data as Map<String, dynamic>;

      // Если есть invitation в ответе
      if (orderData['invitation'] != null) {
        return CleanerInvitation.fromJson(orderData['invitation']);
      }

      // Если нет, создаем из данных заказа
      return CleanerInvitation(
        id: orderData['invitationId'] as int? ?? 0,
        orderId: orderData['id'] as int? ?? orderId,
        orderAddress: orderData['address'] as String? ?? '',
        serviceName: orderData['serviceName'] as String? ?? '',
        userId: orderData['userId'] as int? ?? 0,
        clientId: orderData['userId'] as int? ?? 0,
        clientName: orderData['clientName'] as String? ?? '',
        cleanerId: cleanerId,
        cleanerName: '',
        proposedPrice: proposedPrice,  // ✅ Правильная цена
        status: 'PENDING',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        negotiations: [],
        isExpired: false,
      );
    } catch (e) {
      print('❌ Error creating invitation: $e');
      rethrow;
    }
  }

  // ✅ Получение моих приглашений (для клиента)
  Future<List<CleanerInvitation>> getMyInvitations() async {
    try {
      final response = await _dio.get(
        '/invitations/my',  // ✅ Без ApiConstants.baseUrl
      );
      return (response.data as List)
          .map((e) => CleanerInvitation.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ Error loading my invitations: $e');
      return [];
    }
  }

  // ✅ Получение приглашений для клинера
  Future<List<CleanerInvitation>> getCleanerInvitations() async {
    try {
      final response = await _dio.get(
        '/invitations/cleaner',  // ✅ Без ApiConstants.baseUrl
      );
      return (response.data as List)
          .map((e) => CleanerInvitation.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ Error loading cleaner invitations: $e');
      return [];
    }
  }

  // ✅ Получение приглашения по ID
  Future<CleanerInvitation> getInvitationById(int id) async {
    final response = await _dio.get(
      '/invitations/$id',  // ✅ Без ApiConstants.baseUrl
    );
    return CleanerInvitation.fromJson(response.data);
  }

  // ✅ Принять приглашение
  Future<void> acceptInvitation(int id, {double? proposedPrice}) async {
    try {
      await _dio.post(
        '/invitations/$id/accept',  // ✅ Без ApiConstants.baseUrl
        data: proposedPrice != null ? {'proposedPrice': proposedPrice} : null,
      );
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      rethrow;
    }
  }

  // ✅ Отклонить приглашение
  Future<void> declineInvitation(int id) async {
    try {
      await _dio.post(
        '/invitations/$id/decline',  // ✅ Без ApiConstants.baseUrl
      );
    } catch (e) {
      print('❌ Error declining invitation: $e');
      rethrow;
    }
  }

  // ✅ Контрпредложение от клинера
  Future<CleanerInvitation> counterOffer(int id, double price, String? comment) async {
    try {
      final response = await _dio.post(
        '/invitations/$id/counter-offer',  // ✅ Без ApiConstants.baseUrl
        data: {
          'proposedPrice': price,
          'comment': comment,
        },
      );
      return CleanerInvitation.fromJson(response.data);
    } catch (e) {
      print('❌ Error making counter offer: $e');
      rethrow;
    }
  }

  // ✅ Принять цену (клиент принимает предложение клинера)
  Future<void> acceptPrice(int id) async {
    try {
      await _dio.post(
        '/invitations/$id/accept-price',  // ✅ Без ApiConstants.baseUrl
      );
    } catch (e) {
      print('❌ Error accepting price: $e');
      rethrow;
    }
  }

  // ✅ Отклонить цену (клиент отклоняет предложение клинера)
  Future<void> rejectPrice(int id) async {
    try {
      await _dio.post(
        '/invitations/$id/reject-price',  // ✅ Без ApiConstants.baseUrl
      );
    } catch (e) {
      print('❌ Error rejecting price: $e');
      rethrow;
    }
  }

  // ✅ Контрпредложение от клиента
  Future<CleanerInvitation> clientCounterOffer(int id, double price, String? comment) async {
    try {
      final response = await _dio.post(
        '/invitations/$id/client-counter-offer',  // ✅ Без ApiConstants.baseUrl
        data: {
          'proposedPrice': price,
          'comment': comment,
        },
      );
      return CleanerInvitation.fromJson(response.data);
    } catch (e) {
      print('❌ Error making client counter offer: $e');
      rethrow;
    }
  }

  // ✅ Получение истории переговоров
  Future<List<Negotiation>> getNegotiations(int id) async {
    try {
      final response = await _dio.get(
        '/invitations/$id/negotiations',  // ✅ Без ApiConstants.baseUrl
      );
      return (response.data as List)
          .map((e) => Negotiation.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ Error loading negotiations: $e');
      return [];
    }
  }
}