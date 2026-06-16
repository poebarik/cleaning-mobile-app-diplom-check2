// lib/core/database/hive_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class HiveService {
  static const String _draftsBox = 'order_drafts';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_draftsBox);
  }

  static Box<Map> get draftsBox => Hive.box<Map>(_draftsBox);

  // Add missing methods
  static Future<void> saveDraft(String id, dynamic draft) async {
    final jsonMap = draft.toJson();
    await draftsBox.put(id, jsonMap);
  }

  static Future<dynamic> getDraft(String id) async {
    final jsonMap = draftsBox.get(id);
    if (jsonMap == null) return null;
    // Convert Map<dynamic, dynamic> to Map<String, dynamic>
    return Map<String, dynamic>.from(jsonMap);
  }

  static Future<void> deleteDraft(String id) async {
    await draftsBox.delete(id);
  }
}