import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_logic.dart';

/// المصدر: fawazahmed0/exchange-api (رخصة CC0، بدون مفتاح).
/// الأسعار تتحدث يوميًا — ليست أسعارًا لحظية.
class CurrencyService {
  static const _key = 'fx_cache_v1';
  static const urls = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json',
    'https://latest.currency-api.pages.dev/v1/currencies/usd.json',
  ];

  static Future<RatesSnapshot?> loadCached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return null;
      return RatesSnapshot.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  /// يجرّب الرابط الأساسي ثم الاحتياطي. يرجع null عند الفشل (ولا يمسح القديم).
  static Future<RatesSnapshot?> fetchFresh({http.Client? client}) async {
    final c = client ?? http.Client();
    try {
      for (final u in urls) {
        try {
          final r = await c.get(Uri.parse(u)).timeout(const Duration(seconds: 10));
          if (r.statusCode != 200) continue;
          final snap = parseRates(utf8.decode(r.bodyBytes), DateTime.now());
          if (snap == null) continue;
          try {
            final p = await SharedPreferences.getInstance();
            await p.setString(_key, jsonEncode(snap.toJson()));
          } catch (_) {}
          return snap;
        } catch (_) {
          continue;
        }
      }
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
