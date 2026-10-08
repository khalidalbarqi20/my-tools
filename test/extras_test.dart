import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/extras/extras_logic.dart';

void main() {
  test('الأرقام العربية والغربية', () {
    expect(toWesternDigits('\u0661\u0662\u0663 \u06F4\u06F5\u06F6 abc 7'), '123 456 abc 7');
    expect(toArabicIndicDigits('2026 a'), '\u0662\u0660\u0662\u0666 a');
  });

  test('إزالة التشكيل والتطويل', () {
    expect(
        stripArabicMarks('\u0645\u064F\u062D\u064E\u0645\u0651\u064E\u062F\u064C'),
        '\u0645\u062D\u0645\u062F');
    expect(stripArabicMarks('\u0627\u0644\u0640\u0640\u0640\u0633\u0644\u0627\u0645'),
        '\u0627\u0644\u0633\u0644\u0627\u0645');
    expect(stripArabicMarks('\u0627\u0644\u0640\u0633', tatweel: false), '\u0627\u0644\u0640\u0633');
    expect(stripArabicMarks('abc'), 'abc');
  });

  test('تحويل الأنظمة العددية', () {
    expect(convertBase('255', 10), {2: '11111111', 8: '377', 10: '255', 16: 'FF'});
    expect(convertBase('ff', 16)![10], '255');
    expect(convertBase('0xFF', 16)![2], '11111111');
    expect(convertBase(' 1010 ', 2)![10], '10');
    expect(convertBase('\u0662\u0665\u0665', 10)![16], 'FF');
    expect(convertBase('-10', 10)![2], '-1010');
    expect(convertBase('102', 2), isNull);
    expect(convertBase('--5', 10), isNull);
    expect(convertBase('', 10), isNull);
    expect(convertBase('1' * 201, 10), isNull);
    expect(convertBase('12345678901234567890', 10)![16], 'AB54A98CEB1F0AD2');
  });

  test('الأرقام الرومانية', () {
    expect(toRoman(4), 'IV');
    expect(toRoman(9), 'IX');
    expect(toRoman(14), 'XIV');
    expect(toRoman(1994), 'MCMXCIV');
    expect(toRoman(3999), 'MMMCMXCIX');
    expect(toRoman(0), isNull);
    expect(toRoman(4000), isNull);
    expect(fromRoman('MCMXCIV'), 1994);
    expect(fromRoman('xiv'), 14);
    expect(fromRoman('IIII'), isNull);
    expect(fromRoman('IC'), isNull);
    expect(fromRoman('abc'), isNull);
    for (var i = 1; i <= 3999; i++) {
      expect(fromRoman(toRoman(i)!), i);
    }
    expect(romanConvert('2026'), 'MMXXVI');
    expect(romanConvert('\u0662\u0660\u0662\u0666'), 'MMXXVI');
    expect(romanConvert('MMXXVI'), '2026');
    expect(() => romanConvert('0'), throwsFormatException);
    expect(() => romanConvert('hello'), throwsFormatException);
  });

  test('تكلفة الوقود', () {
    final r = fuelCost(100, 8, 2)!;
    expect(r.liters, 8);
    expect(r.cost, 16);
    expect(fuelCost(0, 8, 2)!.cost, 0);
    expect(fuelCost(-1, 8, 2), isNull);
    expect(fuelCost(100, 0, 2), isNull);
    expect(fuelCost(100, 8, -2), isNull);
    expect(fuelRows(['100', '8', '2'])!.first.$2, '8 لتر');
    expect(fuelRows(['x', '8', '2']), isNull);
  });

  test('الزكاة', () {
    final a = zakat(100000, 300)!;
    expect(a.nisab, 25500);
    expect(a.due, true);
    expect(a.amount, 2500);
    final b = zakat(20000, 300)!;
    expect(b.due, false);
    expect(b.amount, 0);
    expect(zakat(25500, 300)!.due, true);
    expect(zakat(-1, 300), isNull);
    expect(zakat(1000, 0), isNull);
    expect(zakatRows(['100000', '300'])![2].$2, '2500');
  });
}
