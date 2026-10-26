import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/video/video_engine.dart';

/// عملية سابقة: نتيجة محفوظة (ملف) يمكن حفظها أو مشاركتها لاحقًا.
class OpEntry {
  final String id, tool, name, mime, path;
  final int size, ts;
  const OpEntry({
    required this.id,
    required this.tool,
    required this.name,
    required this.mime,
    required this.path,
    required this.size,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool,
        'name': name,
        'mime': mime,
        'path': path,
        'size': size,
        'ts': ts,
      };

  factory OpEntry.fromJson(Map<String, dynamic> j) => OpEntry(
        id: '${j['id']}',
        tool: '${j['tool']}',
        name: '${j['name']}',
        mime: '${j['mime']}',
        path: '${j['path']}',
        size: (j['size'] as num?)?.toInt() ?? 0,
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );
}

/// سجل «عملياتي السابقة». يحتفظ بآخر 20 نتيجة (حتى 300 ميجابايت للملف الواحد).
class OpsHistory {
  static final ValueNotifier<List<OpEntry>> items = ValueNotifier<List<OpEntry>>([]);
  static const _k = 'ops_history_v1';
  static const maxItems = 20;
  static const maxBytes = 300 * 1024 * 1024;
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_k);
      if (s == null) return;
      final l = jsonDecode(s) as List<dynamic>;
      items.value = [for (final m in l) OpEntry.fromJson(m as Map<String, dynamic>)];
    } catch (_) {}
  }

  static Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_k, jsonEncode([for (final e in items.value) e.toJson()]));
    } catch (_) {}
  }

  /// يسجّل نتيجة عملية: ينسخ الملف لمكان دائم ويضيفه أول القائمة. لا يرمي أخطاء أبدًا.
  static Future<void> record({
    required String tool,
    required String name,
    required String mime,
    required String path,
    required int size,
  }) async {
    try {
      await load();
      if (size <= 0 || size > maxBytes) return;
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final kept = await persistOutput(path, id);
      final list = [
        OpEntry(
            id: id,
            tool: tool,
            name: name,
            mime: mime,
            path: kept,
            size: size,
            ts: DateTime.now().millisecondsSinceEpoch),
        ...items.value,
      ];
      while (list.length > maxItems) {
        final old = list.removeLast();
        await deletePersisted(old.path, old.id);
      }
      items.value = list;
      await _save();
    } catch (_) {}
  }

  static Future<void> remove(OpEntry e) async {
    await deletePersisted(e.path, e.id);
    items.value = [for (final x in items.value) if (x.id != e.id) x];
    await _save();
  }

  static Future<void> clear() async {
    for (final e in items.value) {
      await deletePersisted(e.path, e.id);
    }
    items.value = [];
    await _save();
  }
}
