import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/calculator/discount_logic.dart';

void main() {
  test('100 - 20% = 80', () {
    final r = calcDiscount('100', '20')!;
    expect(r.discount, 20);
    expect(r.finalPrice, 80);
  });
  test('أرقام عربية وفاصلة', () {
    expect(calcDiscount('٢٠٠٫٥', '10')!.discount, closeTo(20.05, 1e-9));
  });
  test('0% و 100%', () {
    expect(calcDiscount('50', '0')!.finalPrice, 50);
    expect(calcDiscount('50', '100')!.finalPrice, 0);
  });
  test('إدخال غير صالح', () {
    expect(calcDiscount('', '10'), isNull);
    expect(calcDiscount('abc', '10'), isNull);
    expect(calcDiscount('100', '-5'), isNull);
    expect(calcDiscount('100', '101'), isNull);
    expect(calcDiscount('-100', '10'), isNull);
  });
}
