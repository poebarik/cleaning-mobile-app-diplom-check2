import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/invitation_api.dart';
import '../../data/network/dio_client.dart';
import '../../data/models/invitation/cleaner_invitation.dart';

final invitationProvider = StateNotifierProvider<InvitationNotifier, InvitationState>((ref) {
  return InvitationNotifier();
});

class InvitationNotifier extends StateNotifier<InvitationState> {
  late final InvitationApi _invitationApi;

  InvitationNotifier() : super(const InvitationStateInitial()) {
    _invitationApi = InvitationApi(DioClient.instance);
  }

  Future<void> createInvitation(Map<String, dynamic> data) async {
    state = const InvitationStateLoading();
    try {
      final invitation = await _invitationApi.createInvitation(data);
      state = InvitationStateCreated(invitation);
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> loadMyInvitations() async {
    state = const InvitationStateLoading();
    try {
      final invitations = await _invitationApi.getMyInvitations();
      state = InvitationStateMyInvitationsLoaded(invitations);
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> loadCleanerInvitations() async {
    state = const InvitationStateLoading();
    try {
      final invitations = await _invitationApi.getCleanerInvitations();
      state = InvitationStateCleanerInvitationsLoaded(invitations);
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> acceptInvitation(int id, {double? price}) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.acceptInvitation(id, proposedPrice: price);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> declineInvitation(int id) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.declineInvitation(id);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> counterOffer(int id, double price, String? comment) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.counterOffer(id, price, comment);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> acceptPrice(int id) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.acceptPrice(id);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> rejectPrice(int id) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.rejectPrice(id);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }

  Future<void> clientCounterOffer(int id, double price, String? comment) async {
    state = const InvitationStateLoading();
    try {
      await _invitationApi.clientCounterOffer(id, price, comment);
      state = const InvitationStateActionSuccess();
    } catch (e) {
      state = InvitationStateError(e.toString());
    }
  }
}

// States
sealed class InvitationState {
  const InvitationState();
}

class InvitationStateInitial extends InvitationState {
  const InvitationStateInitial();
}

class InvitationStateLoading extends InvitationState {
  const InvitationStateLoading();
}

class InvitationStateCreated extends InvitationState {
  final CleanerInvitation invitation;
  const InvitationStateCreated(this.invitation);
}

class InvitationStateMyInvitationsLoaded extends InvitationState {
  final List<CleanerInvitation> invitations;
  const InvitationStateMyInvitationsLoaded(this.invitations);
}

class InvitationStateCleanerInvitationsLoaded extends InvitationState {
  final List<CleanerInvitation> invitations;
  const InvitationStateCleanerInvitationsLoaded(this.invitations);
}

class InvitationStateActionSuccess extends InvitationState {
  const InvitationStateActionSuccess();
}

class InvitationStateError extends InvitationState {
  final String error;
  const InvitationStateError(this.error);
}

extension InvitationStateExtension on InvitationState {
  bool get isLoading => this is InvitationStateLoading;
  bool get isCreated => this is InvitationStateCreated;
  bool get isMyInvitationsLoaded => this is InvitationStateMyInvitationsLoaded;
  bool get isCleanerInvitationsLoaded => this is InvitationStateCleanerInvitationsLoaded;
  bool get isActionSuccess => this is InvitationStateActionSuccess; // ДОБАВИТЬ ЭТУ СТРОКУ
  bool get isError => this is InvitationStateError;  // ✅ Добавляем


  CleanerInvitation? get invitation {
    if (this is InvitationStateCreated) {
      return (this as InvitationStateCreated).invitation;
    }
    return null;
  }

  List<CleanerInvitation>? get myInvitations {
    if (this is InvitationStateMyInvitationsLoaded) {
      return (this as InvitationStateMyInvitationsLoaded).invitations;
    }
    return null;
  }

  List<CleanerInvitation>? get cleanerInvitations {
    if (this is InvitationStateCleanerInvitationsLoaded) {
      return (this as InvitationStateCleanerInvitationsLoaded).invitations;
    }
    return null;
  }

  String? get error {
    if (this is InvitationStateError) {
      return (this as InvitationStateError).error;
    }
    return null;
  }
}