import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/math/cas.dart';
import 'package:my_tools/features/math/cas_solve.dart';
import 'package:my_tools/features/math/frac.dart';
import 'package:my_tools/features/math/poly.dart';

String simp(String s) => polyToString(PolyParser.parse(s));

String fac(String s) {
  final p = PolyParser.parse(s);
  final v = p.vars.first;
  return factoredToString(factorUni(p.coeffs(v)!)!, v);
}

void main() {
  group('الكسور', () {
    test('اختصار وعمليات', () {
      expect(Frac(BigInt.from(6), BigInt.from(-4)).toString(), '-3/2');
      expect((Frac.fromInt(1) / Frac.fromInt(2) + Frac.fromInt(1) / Frac.fromInt(3)).toString(), '5/6');
      expect((Frac.fromInt(3) * Frac.fromInt(4) / Frac.fromInt(6)).toString(), '2');
      expect(Frac.tryParse('2.5')!.toString(), '5/2');
      expect(Frac.tryParse('abc'), isNull);
      expect(Frac.fromInt(1) < Frac.fromInt(2), true);
      expect(() => Frac.fromInt(1) / Frac.zero, throwsFormatException);
      expect(Frac.fromInt(2).pow(10).toString(), '1024');
    });
  });

  group('التبسيط', () {
    test('تعابير شائعة', () {
      expect(simp('2x + 3x - 5'), '5x - 5');
      expect(simp('(x+1)^2'), 'x^2 + 2x + 1');
      expect(simp('(x-2)(x-3)'), 'x^2 - 5x + 6');
      expect(simp('3(x+2)-2(x-1)'), 'x + 8');
      expect(simp('1/2 + 1/3'), '5/6');
      expect(simp('x/2 + x/3'), '(5/6)x');
      expect(simp('2.5x'), '(5/2)x');
      expect(simp('x*x*x'), 'x^3');
      expect(simp('xy + yx'), '2xy');
      expect(simp('-x^2'), '-x^2');
      expect(simp('-(x-1)'), '-x + 1');
      expect(simp('٢x+٣x'), '5x');
      expect(simp('x²-4'), 'x^2 - 4');
      expect(simp('x - x'), '0');
    });
    test('أخطاء', () {
      for (final bad in ['sin(x)', '2x+', 'x/y', 'x^-1', '', '(x', '3 \$', '2x^100']) {
        expect(() => PolyParser.parse(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('التحليل', () {
    test('جذور نسبية', () {
      expect(fac('x^2-5x+6'), '(x - 2)(x - 3)');
      expect(fac('x^2-4'), '(x + 2)(x - 2)');
      expect(fac('2x^2-8'), '2(x + 2)(x - 2)');
      expect(fac('x^2+2x+1'), '(x + 1)^2');
      expect(fac('6x^2+x-1'), '(2x + 1)(3x - 1)');
      expect(fac('4x^2-9'), '(2x + 3)(2x - 3)');
      expect(fac('x^3-6x^2+11x-6'), '(x - 1)(x - 2)(x - 3)');
      expect(fac('-x^2+1'), '-(x + 1)(x - 1)');
      expect(fac('x^3+x'), 'x(x^2 + 1)');
      expect(fac('x^2+1'), '(x^2 + 1)');
      expect(fac('x^2-2'), '(x^2 - 2)');
    });
    test('نص التحليل', () {
      expect(factorText('x^2-5x+6'), contains('(x - 2)(x - 3)'));
      expect(factorText('x^2+1'), contains('لا يمكن'));
      expect(factorText('6xy + 9x'), contains('3x(2y + 3)'));
    });
  });

  group('حل المعادلات', () {
    test('خطية', () {
      expect(solveAny('2x + 5 = 17'), contains('x = 6'));
      expect(solveAny('3x - 7 = 2x + 1'), contains('x = 8'));
      expect(solveAny('x/2 = 3'), contains('x = 6'));
      expect(solveAny('2x + 1 = 2x + 3'), contains('لا يوجد حل'));
      expect(solveAny('2x + 1 = 2x + 1'), contains('عدد لا نهائي'));
      expect(solveAny('2x = 3'), contains('x = 3/2 (≈ 1.5)'));
    });
    test('تربيعية', () {
      final a = solveAny('x^2 - 5x + 6 = 0');
      expect(a, contains('Δ = b^2 - 4ac'));
      expect(a, contains('x = 2'));
      expect(a, contains('x = 3'));
      final b = solveAny('x^2 - 2x - 1 = 0');
      expect(b, contains('x = 1 ± √2'));
      expect(b, contains('x ≈ -0.4142'));
      expect(b, contains('x ≈ 2.4142'));
      expect(solveAny('x^2 + x - 1 = 0'), contains('x = (-1 ± √5) / 2'));
      expect(solveAny('x^2 + x + 1 = 0'), contains('لا يوجد حل في الأعداد الحقيقية'));
      expect(solveAny('x^2 - 4x + 4 = 0'), contains('x = -b / 2a = 2'));
      final c = solveAny('2x^2 - 8 = 0');
      expect(c, contains('x = -2'));
      expect(c, contains('x = 2'));
    });
    test('درجات أعلى', () {
      final a = solveAny('x^3 - 6x^2 + 11x - 6 = 0');
      expect(a, contains('(x - 1)(x - 2)(x - 3) = 0'));
      expect(a, contains('x = 1'));
      expect(a, contains('x = 3'));
      expect(solveAny('x^3 = 8'), contains('x = 2'));
    });
    test('نظام معادلتين', () {
      final a = solveAny('x + y = 5\nx - y = 1');
      expect(a, contains('x = Dx / D = 3'));
      expect(a, contains('y = Dy / D = 2'));
      expect(solveAny('x + y = 1\nx + y = 2'), contains('لا يوجد حل'));
      expect(solveAny('x + y = 2\n2x + 2y = 4'), contains('عدد لا نهائي'));
    });
    test('متباينات', () {
      expect(solveAny('2x + 3 > 7'), contains('x > 2'));
      expect(solveAny('2x + 3 > 7'), contains('(2, ∞)'));
      final b = solveAny('-2x + 4 >= 0');
      expect(b, contains('x ≤ 2'));
      expect(b, contains('(-∞, 2]'));
      final c = solveAny('x^2 - 4 < 0');
      expect(c, contains('-2 < x < 2'));
      expect(c, contains('(-2, 2)'));
      final d = solveAny('x^2 - 4 >= 0');
      expect(d, contains('x ≤ -2'));
      expect(d, contains('x ≥ 2'));
      expect(d, contains('(-∞, -2] ∪ [2, ∞)'));
      expect(solveAny('x^2 + 1 > 0'), contains('كل الأعداد الحقيقية'));
      expect(solveAny('x^2 + 1 < 0'), contains('لا يوجد حل'));
      expect(solveAny('x^2 <= 0'), contains('x = 0'));
    });
    test('دخل التعبير بدون مساواة يُبسَّط', () {
      expect(solveAny('2x + 3x - 5'), contains('5x - 5'));
    });
    test('أخطاء', () {
      for (final bad in ['', '2x + y = 3', 'sin(x) = 1', '1 < x < 3', 'x = 1\ny = 2\nz = 3', '2x +']) {
        expect(() => solveAny(bad), throwsFormatException, reason: bad);
      }
    });
  });

  group('الجذور العددية', () {
    test('جذور حقيقية تقريبية', () {
      final r = realRootsNumeric([
        Frac.fromInt(-2), Frac.zero, Frac.zero, Frac.fromInt(1), // x^3 - 2
      ]);
      expect(r.length, 1);
      expect(r.first, closeTo(1.259921, 1e-5));
    });
  });
}
