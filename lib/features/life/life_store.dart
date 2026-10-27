import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// تخزين قوائم JSON بسيطة في الجهاز (المتصفح أو التطبيق).
Future<List<Map<String, dynamic>>> loadList(String key) async {
  try {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    if (s == null) return [];
    return [for (final m in jsonDecode(s) as List<dynamic>) m as Map<String, dynamic>];
  } catch (_) {
    return [];
  }
}

Future<void> saveList(String key, List<Map<String, dynamic>> l) async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(l));
  } catch (_) {}
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
