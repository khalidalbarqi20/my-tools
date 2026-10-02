import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/fmt.dart';
import 'package:my_tools/core/registry.dart';
import 'package:my_tools/features/calculator/calc_logic.dart';
import 'package:my_tools/features/calculator/expr.dart';
import 'package:my_tools/features/calculator/finance_logic.dart';

void main() {
  test('fmt', () {
    expect(fmt(80), '80');
    expect(fmt(0.1 + 0.2, 10), '0.3');
    expect(fmt(-0.001), '0');
    expect(fmt(1234.5), '1234.5');
  });
  test('percent', () {
    final r = percent(['10', '500'])!;
    expect(r[0].$2, '50');
    expect(r[1].$2, '2%');
    expect(percent(['', '5']), isNull);
  });
  test('tax', () {
    final r = tax(['100', '15'])!;
    expect([r[0].$2, r[1].$2, r[2].$2], ['15', '115', '86.96']);
    expect(tax(['-1', '15']), isNull);
  });
  test('profit', () {
    final r = profit(['80', '100'])!;
    expect([r[0].$1, r[0].$2, r[1].$2, r[2].$2],
        ['الربح', '20', '20%', '25%']);
    expect(profit(['100', '80'])![0].$1, 'الخسارة');
    expect(profit(['0', '0'])![1].$2, '—');
  });
  test('tip & split', () {
    expect(tip(['200', '10'])![1].$2, '220');
    expect(split(['300', '4', '0'])![0].$2, '75');
    expect(split(['300', '4', '10'])![0].$2, '82.5');
    expect(split(['300', '0', '0']), isNull);
    expect(split(['300', '2.5', '0']), isNull);
  });
  test('bmi', () {
    final r = bmi(['70', '175'])!;
    expect([r[0].$2, r[1].$2], ['22.86', 'وزن طبيعي']);
    expect(bmi(['0', '175']), isNull);
  });
  test('age', () {
    final now = DateTime(2026, 10, 3);
    expect(age(['1990', '5', '15'], now)![0].$2, '36 سنة و 4 شهر و 18 يوم');
    expect(age(['2026', '2', '30'], now), isNull);
    expect(age(['2030', '1', '1'], now), isNull);
    expect(age(['1990', '13', '1'], now), isNull);
  });
  test('loan', () {
    expect(loan(['10000', '0', '10'])![0].$2, '1000');
    expect(loan(['100000', '12', '12'])![0].$2, '8884.88');
    expect(loan(['0', '5', '12']), isNull);
  });
  test('savings & interest', () {
    expect(savings(['0', '1000', '0', '1'])![0].$2, '12000');
    expect(savings(['1000', '0', '12', '1'])![0].$2, '1126.83');
    final r = interest(['1000', '10', '2'])!;
    expect([r[0].$2, r[2].$2, r[3].$2], ['200', '210', '1210']);
  });
  test('average', () {
    final r = average(['10, 20 30'])!;
    expect([r[0].$2, r[1].$2, r[2].$2], ['20', '60', '3']);
    expect(average(['١٠ ٢٠'])![0].$2, '15');
    expect(average(['a b']), isNull);
    expect(average(['']), isNull);
  });
  test('evalExpr', () {
    expect(evalExpr('100-20%'), closeTo(80, 1e-9));
    expect(evalExpr('200+10%'), closeTo(220, 1e-9));
    expect(evalExpr('50×10%'), closeTo(5, 1e-9));
    expect(evalExpr('10%'), closeTo(0.1, 1e-9));
    expect(evalExpr('2+3×4'), 14);
    expect(evalExpr('(2+3)×4'), 20);
    expect(evalExpr('-5+2'), -3);
    expect(evalExpr('١٠+٥'), 15);
    expect(evalExpr('٣٫٥×2'), 7);
    expect(evalExpr('0.1+0.2'), closeTo(0.3, 1e-9));
    for (final bad in ['10÷0', '2+', '', '1.2.3', '((2)', '2)']) {
      expect(evalExpr(bad), isNull, reason: bad);
    }
  });
  test('registry', () {
    final ids = allTools.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(allTools.every((t) => t.keywords.isNotEmpty), true);
    expect(allTools.firstWhere((t) => t.matches('جمع')).id, 'calculator');
  });
}
