import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/currency/currency_logic.dart';

String body({String date = '2026-10-04', int n = 25, Map<String, Object?>? extra}) {
  final m = <String, Object?>{'usd': 1, 'sar': 3.75, 'eur': 0.5};
  for (var i = 0; i < n; i++) {
    m['x$i'] = 2.0 + i;
  }
  if (extra != null) m.addAll(extra);
  final inner = m.entries.map((e) => '"${e.key}": ${e.value}').join(',');
  return '{"date":"$date","usd":{$inner}}';
}

void main() {
  final now = DateTime(2026, 10, 4, 12);
  test('تحليل الأسعار والتحويل', () {
    final s = parseRates(body(), now)!;
    expect(s.apiDate, '2026-10-04');
    expect(convertCurrency(100, 'sar', 'usd', s), closeTo(26.6667, 1e-3));
    expect(convertCurrency(1, 'usd', 'eur', s), closeTo(0.5, 1e-9));
    expect(convertCurrency(0, 'sar', 'eur', s), 0);
    expect(convertCurrency(1, 'sar', 'zzz', s), isNull);
  });
  test('رفض البيانات الناقصة أو التالفة', () {
    expect(parseRates('', now), isNull);
    expect(parseRates('not json', now), isNull);
    expect(parseRates('{"date":"x"}', now), isNull);
    expect(parseRates('{"usd":{"sar":3.75}}', now), isNull);
    expect(parseRates(body(extra: {'sar': -1, 'eur': 0}), now)!.perUsd.containsKey('eur'), false);
  });
  test('التخزين والاسترجاع', () {
    final s = parseRates(body(), now)!;
    final r = RatesSnapshot.fromJson(s.toJson())!;
    expect(r.perUsd['sar'], 3.75);
    expect(r.fetchedAt, now);
    expect(RatesSnapshot.fromJson({'perUsd': 5}), isNull);
    expect(RatesSnapshot.fromJson(null), isNull);
  });
  test('عمر التحديث بالعربية', () {
    expect(ageLabel(now, now), 'قبل لحظات');
    expect(ageLabel(now.subtract(const Duration(minutes: 5)), now), 'منذ 5 دقائق');
    expect(ageLabel(now.subtract(const Duration(hours: 1)), now), 'منذ ساعة');
    expect(ageLabel(now.subtract(const Duration(hours: 2)), now), 'منذ ساعتين');
    expect(ageLabel(now.subtract(const Duration(hours: 5)), now), 'منذ 5 ساعات');
    expect(ageLabel(now.subtract(const Duration(days: 3)), now), 'منذ 3 أيام');
  });
  test('الأسعار القديمة', () {
    final fresh = parseRates(body(), now)!;
    expect(isStale(fresh, now), false);
    final old = parseRates(body(date: '2026-09-20'), now)!;
    expect(isStale(old, now), true);
  });
  test('الأسماء', () {
    expect(currencyName('sar'), 'ريال سعودي (SAR)');
    expect(currencyName('abc'), 'ABC');
  });
}
