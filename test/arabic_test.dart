import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/arabic/hijri_logic.dart';
import 'package:my_tools/features/arabic/tafqeet.dart';
import 'package:my_tools/features/currency/currency_logic.dart';
import 'package:my_tools/features/gold/gold_logic.dart';
import 'package:my_tools/features/qr/qr_logic.dart';
import 'package:my_tools/features/time/time_logic.dart' show weekdayAr;

void main() {
  test('رقم إلى كلمات', () {
    const w = {
      0: 'صفر', 1: 'واحد', 2: 'اثنان', 10: 'عشرة', 11: 'أحد عشر', 12: 'اثنا عشر',
      19: 'تسعة عشر', 20: 'عشرون', 21: 'واحد وعشرون', 25: 'خمسة وعشرون',
      99: 'تسعة وتسعون', 100: 'مئة', 101: 'مئة وواحد', 110: 'مئة وعشرة',
      111: 'مئة وأحد عشر', 200: 'مئتان', 250: 'مئتان وخمسون',
      999: 'تسعمئة وتسعة وتسعون', 1000: 'ألف', 1250: 'ألف ومئتان وخمسون',
      1002: 'ألف واثنان', 2000: 'ألفان', 3000: 'ثلاثة آلاف', 10000: 'عشرة آلاف',
      11000: 'أحد عشر ألفًا', 21000: 'واحد وعشرون ألفًا', 100000: 'مئة ألف',
      200000: 'مئتا ألف', 300000: 'ثلاثمئة ألف', 101000: 'مئة وألف', 102000: 'مئة وألفان',
      123456: 'مئة وثلاثة وعشرون ألفًا وأربعمئة وستة وخمسون',
      1000000: 'مليون', 2000000: 'مليونان', 5000000: 'خمسة ملايين',
      1000001: 'مليون وواحد', 1500000: 'مليون وخمسمئة ألف',
      12345678: 'اثنا عشر مليونًا وثلاثمئة وخمسة وأربعون ألفًا وستمئة وثمانية وسبعون',
      1000000000: 'مليار', 3500000000: 'ثلاثة مليارات وخمسمئة مليون',
    };
    w.forEach((n, e) => expect(wordsOf(n), e, reason: '$n'));
    expect(numberToWords('1250'), 'ألف ومئتان وخمسون');
    expect(numberToWords('\u0661\u0662\u0665\u0660'), 'ألف ومئتان وخمسون');
    expect(numberToWords('1,250'), 'ألف ومئتان وخمسون');
    expect(numberToWords('3.14'), 'ثلاثة فاصلة واحد أربعة');
    expect(numberToWords('0.05'), 'صفر فاصلة صفر خمسة');
    expect(numberToWords('-5'), 'سالب خمسة');
    expect(numberToWords('-0'), 'صفر');
    expect(() => numberToWords('abc'), throwsFormatException);
    expect(() => numberToWords(''), throwsFormatException);
    expect(() => numberToWords('1' * 16), throwsFormatException);
  });

  test('مبلغ إلى كلمات', () {
    String a(String v, [String c = 'sar', bool only = false]) => amountToWords(v, c, only: only);
    expect(a('1250.50'), 'ألف ومئتان وخمسون ريالًا وخمسون هللة');
    expect(a('1'), 'ريال واحد');
    expect(a('2.5'), 'ريالان وخمسون هللة');
    expect(a('3'), 'ثلاثة ريالات');
    expect(a('10'), 'عشرة ريالات');
    expect(a('11'), 'أحد عشر ريالًا');
    expect(a('100'), 'مئة ريال');
    expect(a('200'), 'مئتا ريال');
    expect(a('1200'), 'ألف ومئتا ريال');
    expect(a('2000'), 'ألفا ريال');
    expect(a('101'), 'مئة وريال واحد');
    expect(a('1002'), 'ألف وريالان');
    expect(a('1001'), 'ألف وريال واحد');
    expect(a('1013'), 'ألف وثلاثة عشر ريالًا');
    expect(a('1003'), 'ألف وثلاثة ريالات');
    expect(a('21'), 'واحد وعشرون ريالًا');
    expect(a('22'), 'اثنان وعشرون ريالًا');
    expect(a('2000000'), 'مليونا ريال');
    expect(a('0.75'), 'خمس وسبعون هللة');
    expect(a('0.01'), 'هللة واحدة');
    expect(a('0.02'), 'هللتان');
    expect(a('0.03'), 'ثلاث هللات');
    expect(a('0.11'), 'إحدى عشرة هللة');
    expect(a('0.12'), 'اثنتا عشرة هللة');
    expect(a('0.21'), 'إحدى وعشرون هللة');
    expect(a('0.22'), 'اثنتان وعشرون هللة');
    expect(a('0.23'), 'ثلاث وعشرون هللة');
    expect(a('5.05'), 'خمسة ريالات وخمس هللات');
    expect(a('0'), 'صفر ريال');
    expect(a('12.34', 'usd'), 'اثنا عشر دولارًا وأربعة وثلاثون سنتًا');
    expect(a('0.99', 'aed'), 'تسعة وتسعون فلسًا');
    expect(a('5', 'egp'), 'خمسة جنيهات مصرية');
    expect(a('1250.5', 'sar', true), 'فقط ألف ومئتان وخمسون ريالًا وخمسون هللة لا غير');
    expect(a('0', 'sar', true), 'فقط صفر ريال لا غير');
    // تقريب الخانة التالية
    expect(a('1.005'), 'ريال واحد وهللة واحدة');
    expect(a('1.999'), 'ريالان');
    expect(() => a('-5'), throwsFormatException);
    expect(() => a('abc'), throwsFormatException);
    expect(() => a('5', 'xyz'), throwsFormatException);
  });

  test('التاريخ الهجري', () {
    final g = hijriConvert('2025-03-01', toHijriDir: true);
    expect(g, contains('1 رمضان 1446 هـ'));
    expect(g, contains('1446/09/01'));
    expect(g, contains(weekdayAr(DateTime.utc(2025, 3, 1))));
    final h = hijriConvert('1446-09-01', toHijriDir: false);
    expect(h, contains('2025-03-01'));
    expect(hijriConvert('اليوم', toHijriDir: true, now: DateTime.utc(2025, 3, 1)), contains('1 رمضان 1446'));
    expect(() => hijriConvert('1800-01-01', toHijriDir: true), throwsFormatException);
    expect(() => hijriConvert('3000-01-01', toHijriDir: true), throwsFormatException);
    expect(() => hijriConvert('abc', toHijriDir: true), throwsFormatException);
    expect(() => hijriConvert('1446-13-01', toHijriDir: false), throwsFormatException);
    expect(() => hijriConvert('1446-09-31', toHijriDir: false), throwsFormatException);
    expect(() => hijriConvert('1100-01-01', toHijriDir: false), throwsFormatException);
  });

  test('سعر الذهب', () {
    final s = RatesSnapshot({'usd': 1, 'sar': 3.75, 'xau': 0.00025}, '2026-10-05', DateTime(2026, 10, 5));
    expect(goldOunceUsd(s), closeTo(4000, 1e-9));
    expect(goldOuncePrice(s, 'sar'), closeTo(15000, 1e-6));
    expect(goldGramPrice(s, 'sar', 24), closeTo(482.26119852941974, 1e-6));
    expect(goldGramPrice(s, 'sar', 22), closeTo(442.07276531863477, 1e-6));
    expect(goldGramPrice(s, 'sar', 21), closeTo(421.97854871324233, 1e-6));
    expect(goldGramPrice(s, 'sar', 18), closeTo(361.6958988970648, 1e-6));
    expect(goldGramPrice(s, 'sar', 25), isNull);
    expect(goldGramPrice(s, 'zzz', 24), isNull);
    final bad = RatesSnapshot({'usd': 1, 'sar': 3.75, 'xau': 1.0}, '', DateTime(2026));
    expect(goldOunceUsd(bad), isNull); // سعر غير منطقي
    final none = RatesSnapshot({'usd': 1, 'sar': 3.75}, '', DateTime(2026));
    expect(goldOunceUsd(none), isNull);
    expect(goldGramPrice(none, 'sar', 24), isNull);
  });

  test('QR الموقع', () {
    expect(buildGeo('24.7136', '46.6753'), 'geo:24.713600,46.675300');
    expect(buildGeo('-33.8688', '151.2093'), 'geo:-33.868800,151.209300');
    expect(() => buildGeo('91', '0'), throwsFormatException);
    expect(() => buildGeo('0', '181'), throwsFormatException);
    expect(() => buildGeo('x', '1'), throwsFormatException);
  });
}
