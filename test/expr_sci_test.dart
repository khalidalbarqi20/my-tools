import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/calculator/expr.dart';

void main() {
  double? e(String s, {bool deg = false, Map<String, double> v = const {}}) =>
      evalExprWith(s, degrees: deg, vars: v);

  test('الأسس والجذور والمضروب', () {
    expect(e('2^3'), 8);
    expect(e('2^3^2'), 512);
    expect(e('-2^2'), -4);
    expect(e('2^-1'), 0.5);
    expect(e('√9'), 3);
    expect(e('√(16)+1'), 5);
    expect(e('5!'), 120);
    expect(e('0!'), 1);
    expect(e('3!+2'), 8);
    expect(e('3²'), 9);
    expect(e('sqrt(2)^2'), closeTo(2, 1e-12));
    expect(e('cbrt(27)'), closeTo(3, 1e-12));
    expect(e('cbrt(-8)'), closeTo(-2, 1e-12));
  });

  test('الثوابت والضرب الضمني', () {
    expect(e('2π'), closeTo(6.283185307179586, 1e-12));
    expect(e('π'), closeTo(3.141592653589793, 1e-12));
    expect(e('e'), closeTo(2.718281828459045, 1e-12));
    expect(e('2(3+4)'), 14);
    expect(e('(1+2)(3+4)'), 21);
    expect(e('3sin(90)', deg: true), closeTo(3, 1e-12));
  });

  test('الدوال والزوايا', () {
    expect(e('sin(30)', deg: true), closeTo(0.5, 1e-12));
    expect(e('cos(60)', deg: true), closeTo(0.5, 1e-12));
    expect(e('tan(45)', deg: true), closeTo(1, 1e-12));
    expect(e('tan(90)', deg: true), isNull);
    expect(e('asin(0.5)', deg: true), closeTo(30, 1e-9));
    expect(e('sin(0)'), 0);
    expect(e('ln(e)'), closeTo(1, 1e-12));
    expect(e('log(1000)'), closeTo(3, 1e-9));
    expect(e('log2(8)'), closeTo(3, 1e-9));
    expect(e('abs(-5)'), 5);
    expect(e('floor(2.7)'), 2);
    expect(e('ceil(2.1)'), 3);
    expect(e('round(2.5)'), 3);
    expect(e('exp(0)'), 1);
  });

  test('المتغيرات', () {
    expect(e('x^2-4x+3', v: {'x': 2}), -1);
    expect(e('2x+1', v: {'x': 3}), 7);
    expect(e('x(x+1)', v: {'x': 2}), 6);
    expect(e('xsin(x)', v: {'x': 0}), 0);
    expect(e('x'), isNull);
  });

  test('حالات غير صحيحة', () {
    for (final bad in ['5.5!', '(-1)!', 'sin(', 'foo(1)', '2^', 'ln(0)', 'log(-1)', '1/0', '√(-4)', '171!', '2+*3']) {
      expect(e(bad), isNull, reason: bad);
    }
  });

  test('سلوك النسبة المئوية لم يتغير', () {
    expect(evalExpr('200+10%'), closeTo(220, 1e-9));
    expect(evalExpr('100-20%'), closeTo(80, 1e-9));
    expect(evalExpr('50×10%'), closeTo(5, 1e-9));
  });
}
