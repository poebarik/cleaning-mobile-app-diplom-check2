import 'package:dio/dio.dart';
import '../../models/invitation/cleaner_invitation.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/invitation/negotiation.dart';

class InvitationApi {
  final Dio _dio;

  InvitationApi(this._dio);

  Future<CleanerInvitation> createInvitation(Map<String, dynamic> request) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}',
      data: request,
    );
    return CleanerInvitation.fromJson(response.data);
  }

  Future<List<CleanerInvitation>> getMyInvitations() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.myInvitations}',
    );
    return (response.data as List)
        .map((e) => CleanerInvitation.fromJson(e))
        .toList();
  }

  Future<List<CleanerInvitation>> getCleanerInvitations() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.cleanerInvitations}',
    );
    return (response.data as List)
        .map((e) => CleanerInvitation.fromJson(e))
        .toList();
  }

  Future<CleanerInvitation> getInvitationById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id',
    );
    return CleanerInvitation.fromJson(response.data);
  }

  Future<void> acceptInvitation(int id, {double? proposedPrice}) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/accept',
      data: proposedPrice != null ? {'proposedPrice': proposedPrice} : null,
    );
  }

  Future<void> declineInvitation(int id) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/decline',
    );
  }

  Future<CleanerInvitation> counterOffer(int id, double price, String? comment) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/counter-offer',
      data: {
        'proposedPrice': price,
        'comment': comment,
      },
    );
    return CleanerInvitation.fromJson(response.data);
  }

  Future<void> acceptPrice(int id) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/accept-price',
    );
  }

  Future<void> rejectPrice(int id) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/reject-price',
    );
  }

  Future<CleanerInvitation> clientCounterOffer(int id, double price, String? comment) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/client-counter-offer',
      data: {
        'proposedPrice': price,
        'comment': comment,
      },
    );
    return CleanerInvitation.fromJson(response.data);
  }

  Future<List<Negotiation>> getNegotiations(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.invitations}/$id/negotiations',
    );
    return (response.data as List)
        .map((e) => Negotiation.fromJson(e))
        .toList();
  }
}