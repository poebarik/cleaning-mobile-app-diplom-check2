// lib/data/repositories/invitation_repository.dart
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/invitation/cleaner_invitation.dart';
import '../models/invitation/negotiation.dart';
import '../../domain/enums/order_action.dart';
import '../network/dio_client.dart';

class InvitationRepository {
  final Dio _dio = DioClient.instance;

  // ✅ Создание приглашения через action
  Future<CleanerInvitation> createInvitation({
    required int orderId,
    required int cleanerId,
    required double proposedPrice,
    String? message,
  }) async {
    try {
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
            'proposedPrice': proposedPrice,
            'message': message ?? '',
          }
        },
      );

      print('✅ Invitation created successfully');
      return CleanerInvitation.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating invitation: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Отмена приглашения
  Future<void> cancelInvitation(int invitationId) async {
    try {
      print('📤 CANCELING INVITATION: $invitationId');
      await _dio.delete('/invitations/$invitationId');
      print('✅ Invitation cancelled successfully');
    } catch (e) {
      print('❌ Error canceling invitation: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Получение приглашений для заказа (универсальный метод)
  Future<List<CleanerInvitation>> getInvitationsForOrder(int orderId, {String? role}) async {
    try {
      List<CleanerInvitation> allInvitations = [];

      // Если роль не указана или это CLIENT - используем /invitations/my
      if (role == null || role == 'CLIENT') {
        final response = await _dio.get('/invitations/my');
        final List data = response.data;
        allInvitations = data.map((e) => CleanerInvitation.fromJson(e)).toList();
      }
      // Если это CLEANER - используем /invitations/cleaner
      else if (role == 'CLEANER') {
        final response = await _dio.get('/invitations/cleaner');
        final List data = response.data;
        allInvitations = data.map((e) => CleanerInvitation.fromJson(e)).toList();
      }

      // Фильтруем по orderId
      return allInvitations.where((inv) => inv.orderId == orderId).toList();
    } catch (e) {
      print('❌ Error loading invitations: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      return [];
    }
  }

  // ✅ Получение истории переговоров (контрпредложений) по приглашению
  Future<List<Negotiation>> getNegotiations(int invitationId) async {
    try {
      print('📤 GETTING NEGOTIATIONS for invitation: $invitationId');

      final response = await _dio.get(
        '/invitations/$invitationId/negotiations',
      );

      final List data = response.data;
      return data.map((e) => Negotiation.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error loading negotiations: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      return [];
    }
  }

  // ✅ Получение приглашений для клинера
  Future<List<CleanerInvitation>> getCleanerInvitations() async {
    try {
      final response = await _dio.get('/invitations/cleaner');
      final List data = response.data;
      return data.map((e) => CleanerInvitation.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error loading cleaner invitations: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      return [];
    }
  }


  Future<List<CleanerInvitation>> getMyInvitations() async {
    try {
      final response = await _dio.get('/invitations/my');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => CleanerInvitation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading invitations: $e');
      return [];
    }
  }

  Future<CleanerInvitation> getInvitationById(int invitationId) async {
    try {
      final response = await _dio.get('/invitations/$invitationId');
      return CleanerInvitation.fromJson(response.data);
    } catch (e) {
      print('❌ Error loading invitation: $e');
      rethrow;
    }
  }

  // ✅ НОВЫЙ МЕТОД: Получить данные клинера по ID приглашения
  // lib/data/repositories/invitation_repository.dart

  // lib/data/repositories/invitation_repository.dart
  Future<Map<String, dynamic>> getCleanerByInvitationId(int invitationId) async {
    try {
      print('📤 GET /invitations/$invitationId/cleaner-info');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/invitations/$invitationId/cleaner-info',
      );
      print('📥 Response data: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting cleaner by invitation: $e');
      rethrow;
    }
  }

  // ✅ НОВЫЙ МЕТОД: Получить userId по invitationId
  Future<int?> getUserIdByInvitationId(int invitationId) async {
    try {
      final data = await getCleanerByInvitationId(invitationId);
      final userId = data['userId'] as int?;
      print('✅ Found userId: $userId for invitationId: $invitationId');
      return userId;
    } catch (e) {
      print('❌ Error getting userId by invitation: $e');
      return null;
    }
  }

  Future<void> acceptPrice(int invitationId) async {
    try {
      await _dio.post('/invitations/$invitationId/accept-price');
    } catch (e) {
      print('❌ Error accepting price: $e');
      rethrow;
    }
  }

  Future<void> rejectPrice(int invitationId) async {
    try {
      await _dio.post('/invitations/$invitationId/reject-price');
    } catch (e) {
      print('❌ Error rejecting price: $e');
      rethrow;
    }
  }


  // ✅ Принять приглашение
  Future<void> acceptInvitation(int invitationId, {double? proposedPrice}) async {
    try {
      await _dio.post(
        '/invitations/$invitationId/accept',
        data: proposedPrice != null ? {'proposedPrice': proposedPrice} : null,
      );
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      rethrow;
    }
  }

  // ✅ Отклонить приглашение
  Future<void> declineInvitation(int invitationId) async {
    try {
      await _dio.post('/invitations/$invitationId/decline');
    } catch (e) {
      print('❌ Error declining invitation: $e');
      rethrow;
    }
  }

  // ✅ Контрпредложение
  Future<CleanerInvitation> counterOffer(int invitationId, double price, String? comment) async {
    try {
      final response = await _dio.post(
        '/invitations/$invitationId/counter-offer',
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

  Future<void> acceptCounterOffer(int invitationId) async {
    try {
      await _dio.post('/invitations/$invitationId/accept-price');
    } catch (e) {
      print('❌ Error accepting counter offer: $e');
      rethrow;
    }
  }

// ✅ Отклонить контрпредложение
  Future<void> rejectCounterOffer(int invitationId) async {
    try {
      await _dio.post('/invitations/$invitationId/reject-price');
    } catch (e) {
      print('❌ Error rejecting counter offer: $e');
      rethrow;
    }
  }
}