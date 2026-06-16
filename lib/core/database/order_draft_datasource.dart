// lib/core/database/order_draft_datasource.dart
import 'package:uuid/uuid.dart';
import 'hive_service.dart';
import '../../data/models/order/order_draft.dart';

class OrderDraftDataSource {
  static const String _currentDraftId = 'current_draft';

  Future<OrderDraft> saveDraft(String id, OrderDraft draft) async {
    await HiveService.saveDraft(id, draft);
    return draft;
  }

  Future<OrderDraft?> getDraft(String id) async {
    final jsonMap = await HiveService.getDraft(id);
    if (jsonMap == null) return null;
    return OrderDraft.fromJson(jsonMap);
  }

  Future<OrderDraft?> getCurrentDraft() async {
    return await getDraft(_currentDraftId);
  }

  Future<void> saveCurrentDraft(OrderDraft draft) async {
    await saveDraft(_currentDraftId, draft);
  }

  Future<void> deleteDraft(String id) async {
    await HiveService.deleteDraft(id);
  }

  Future<void> deleteCurrentDraft() async {
    await deleteDraft(_currentDraftId);
  }

  String generateId() => const Uuid().v4();
}