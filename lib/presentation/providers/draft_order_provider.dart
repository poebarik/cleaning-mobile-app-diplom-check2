// lib/presentation/providers/draft_order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/hive_service.dart';
import '../../data/models/order/order_draft.dart';

final draftOrderProvider = StateNotifierProvider<DraftOrderNotifier, OrderDraft?>((ref) {
  return DraftOrderNotifier();
});

class DraftOrderNotifier extends StateNotifier<OrderDraft?> {
  DraftOrderNotifier() : super(null) {
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draftJson = HiveService.draftsBox.get('current_draft');
    if (draftJson != null) {
      try {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final jsonMap = Map<String, dynamic>.from(draftJson);
        final draft = OrderDraft.fromJson(jsonMap);
        state = draft;
      } catch (e) {
        state = OrderDraft.empty();
      }
    } else {
      state = OrderDraft.empty();
    }
  }

  Future<void> updateDraft(OrderDraft Function(OrderDraft) update) async {
    if (state == null) return;
    final newDraft = update(state!);
    state = newDraft;
    await _saveDraft(newDraft);
  }

  Future<void> _saveDraft(OrderDraft draft) async {
    final jsonMap = draft.toJson();
    await HiveService.draftsBox.put('current_draft', jsonMap);
  }

  Future<void> clearDraft() async {
    await HiveService.draftsBox.delete('current_draft');
    state = OrderDraft.empty();
  }
}