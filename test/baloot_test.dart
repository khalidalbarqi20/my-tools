import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/baloot/baloot_logic.dart';

const _z4 = TeamInput([0, 0, 0, 0], 0);
const _z3 = TeamInput([0, 0, 0], 0);

void main() {
  test('تحويل الأوراق إلى أعداد (صن وحكم)', () {
    const sun = {3: 0, 5: 1, 14: 2, 15: 3, 16: 4, 25: 5, 35: 7, 45: 9, 65: 13, 130: 26};
    const hak = {3: 0, 5: 1, 14: 1, 15: 1, 16: 2, 25: 2, 35: 3, 45: 4, 65: 6, 130: 13};
    sun.forEach((x, e) => expect(balootConv(BalootKind.sun, x), e, reason: 'sun $x'));
    hak.forEach((x, e) => expect(balootConv(BalootKind.hakam, x), e, reason: 'hakam $x'));
  });

  test('صن بدون مشاريع', () {
    final r = balootEval(BalootKind.sun, 0, 80, _z4, _z4);
    expect(r.total, 130);
    expect(r.points, [80, 50]);
    expect(r.ok, true);
    expect(r.fin, [16, 10]);
  });

  test('صن: مشروع لكل فريق، الأعلى يحسب له فقط', () {
    final r = balootEval(BalootKind.sun, 1, 50,
        const TeamInput([1, 0, 0, 0], 0), const TeamInput([0, 1, 0, 0], 0));
    expect(r.total, 180);
    expect(r.points, [80, 100]);
    expect(r.cards, [80, 50]);
    expect(r.fin, [16, 20]);
  });

  test('صن: المشتري يخسر فتذهب كل النقاط للخصم', () {
    final r = balootEval(BalootKind.sun, 0, 65, _z4,
        const TeamInput([0, 0, 1, 0], 0));
    expect(r.ok, false);
    expect(r.tie, false);
    expect(r.points, [65, 165]);
    expect(r.fin, [0, 46]);
  });

  test('صن: أربعمية ضد سرا', () {
    final r = balootEval(BalootKind.sun, 1, 5,
        const TeamInput([0, 0, 0, 1], 0), const TeamInput([2, 0, 0, 0], 0));
    expect(r.total, 330);
    expect(r.points, [325, 5]);
    expect(r.fin, [66, 0]);
  });

  test('حكم: البلوت يضيف 20 للإجمالي و2 للأعداد', () {
    final r = balootEval(BalootKind.hakam, 0, 100,
        const TeamInput([0, 0, 0], 1), _z3);
    expect(r.total, 182);
    expect(r.points, [120, 62]);
    expect(r.counts, [12, 6]);
    expect(r.fin, [12, 6]);
  });

  test('حكم: مشاريع وبلوت للفريقين', () {
    final r = balootEval(BalootKind.hakam, 1, 70,
        const TeamInput([1, 1, 0], 0), const TeamInput([0, 0, 1], 1));
    expect(r.total, 282);
    expect(r.points, [92, 190]);
    expect(r.fin, [9, 19]);
  });

  test('حكم: كل الأوراق للمشتري، وخارج النطاق يُرفض', () {
    final r = balootEval(BalootKind.hakam, 0, 162, _z3, _z3);
    expect(r.points, [162, 0]);
    expect(r.fin, [16, 0]);
    expect(balootEval(BalootKind.hakam, 0, 170, _z3, _z3).outOfRange, true);
  });
}
