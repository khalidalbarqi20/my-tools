import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_model.dart';

/// عنوان ملف الإعدادات المنشورة (من لوحة الإدارة). يُمرَّر وقت البناء:
/// --dart-define=REMOTE_CONFIG_URL=https://.../apps/my_tools/published.json
/// فارغ = الميزة معطّلة والتطبيق يستخدم إعداداته المضمّنة.
const kRemoteConfigUrl = String.fromEnvironment('REMOTE_CONFIG_URL');

class RemoteStore {
  static const _cacheKey = 'remote_cfg_v1';
  static const _atKey = 'remote_cfg_at';
  static const _annKey = 'remote_ann_seen';
  static const refreshEvery = Duration(hours: 6);

  static final ValueNotifier<RemoteConfig?> config = ValueNotifier(null);

  /// يحمّل آخر إعدادات محفوظة (سريع، محلي) قبل رسم الواجهة.
  static Future<void> loadCache() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_cacheKey);
      if (s == null) return;
      config.value = parseRemoteConfig(jsonDecode(s));
    } catch (_) {}
  }

  /// يجلب النسخة المنشورة إن مضى وقت كافٍ. أي فشل لا يؤثر (نبقى على المحفوظ).
  static Future<void> refresh({bool force = false, http.Client? client}) async {
    if (kRemoteConfigUrl.isEmpty) return;
    final c = client ?? http.Client();
    try {
      final p = await SharedPreferences.getInstance();
      final at = p.getInt(_atKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - at;
      if (!force && age >= 0 && age < refreshEvery.inMilliseconds) return;
      final r = await c.get(Uri.parse(kRemoteConfigUrl)).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return;
      final body = utf8.decode(r.bodyBytes);
      final cfg = parseRemoteConfig(jsonDecode(body));
      if (cfg == null) return; // "null" أو بيانات تالفة: نتجاهلها
      await p.setString(_cacheKey, body);
      await p.setInt(_atKey, DateTime.now().millisecondsSinceEpoch);
      config.value = cfg;
    } catch (_) {
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<bool> announcementSeen(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(_annKey) ?? const []).contains(id);
    } catch (_) {
      return true; // عند الشك لا نزعج المستخدم
    }
  }

  static Future<void> markAnnouncementSeen(String id) async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = [...(p.getStringList(_annKey) ?? const <String>[]), id];
      await p.setStringList(_annKey, l.length > 20 ? l.sublist(l.length - 20) : l);
    } catch (_) {}
  }
}
