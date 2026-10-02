import 'dart:math';
import '../../core/fmt.dart';
import 'calc_logic.dart';

Rows? tax(List<String> v) {
  final n = nums(v);
  if (n == null || n[0] < 0 || n[1] < 0) return null;
  final p = n[0], r = n[1] / 100;
  final base = p / (1 + r);
  return [
    ('قيمة الضريبة', fmt(p * r)),
    ('الإجمالي بعد الضريبة', fmt(p + p * r)),
    ('لو السعر شامل الضريبة: قبل الضريبة', fmt(base)),
    ('لو السعر شامل الضريبة: قيمة الضريبة', fmt(p - base)),
  ];
}

Rows? profit(List<String> v) {
  final n = nums(v);
  if (n == null || n[0] < 0 || n[1] < 0) return null;
  final c = n[0], s = n[1], p = s - c;
  return [
    (p >= 0 ? 'الربح' : 'الخسارة', fmt(p.abs())),
    ('هامش الربح (من سعر البيع)', s == 0 ? '—' : '${fmt(p / s * 100)}%'),
    ('نسبة الربح على التكلفة', c == 0 ? '—' : '${fmt(p / c * 100)}%'),
  ];
}

Rows? tip(List<String> v) {
  final n = nums(v);
  if (n == null || n[0] < 0 || n[1] < 0) return null;
  final t = n[0] * n[1] / 100;
  return [('قيمة الإكرامية', fmt(t)), ('الإجمالي', fmt(n[0] + t))];
}

Rows? split(List<String> v) {
  final n = nums(v);
  if (n == null ||
      n[0] < 0 ||
      n[1] < 1 ||
      n[1] != n[1].roundToDouble() ||
      n[2] < 0) {
    return null;
  }
  final total = n[0] * (1 + n[2] / 100);
  return [
    ('نصيب كل شخص', fmt(total / n[1])),
    ('الإجمالي مع الإكرامية', fmt(total)),
  ];
}

Rows? loan(List<String> v) {
  final n = nums(v);
  if (n == null) return null;
  final p = n[0], rate = n[1], m = n[2];
  if (p <= 0 || rate < 0 || m < 1 || m != m.roundToDouble()) return null;
  final r = rate / 1200;
  final pay = r == 0 ? p / m : p * r / (1 - pow(1 + r, -m));
  final total = pay * m;
  return [
    ('القسط الشهري', fmt(pay)),
    ('إجمالي المسدد', fmt(total)),
    ('إجمالي الفوائد', fmt(total - p)),
  ];
}

Rows? savings(List<String> v) {
  final n = nums(v);
  if (n == null) return null;
  final init = n[0], mo = n[1], rate = n[2], years = n[3];
  if (init < 0 || mo < 0 || rate < 0 || years <= 0 || years > 100) return null;
  final k = (years * 12).round();
  final r = rate / 1200;
  final g = pow(1 + r, k).toDouble();
  final fv = r == 0 ? init + mo * k : init * g + mo * (g - 1) / r;
  final dep = init + mo * k;
  return [
    ('الرصيد النهائي المتوقع', fmt(fv)),
    ('إجمالي ما أودعته', fmt(dep)),
    ('العائد المتوقع', fmt(fv - dep)),
  ];
}

Rows? interest(List<String> v) {
  final n = nums(v);
  if (n == null || n.any((x) => x < 0)) return null;
  final p = n[0], r = n[1], t = n[2];
  final simple = p * r * t / 100;
  final comp = p * pow(1 + r / 100, t) - p;
  return [
    ('الفائدة البسيطة', fmt(simple)),
    ('الإجمالي (بسيطة)', fmt(p + simple)),
    ('الفائدة المركبة (سنويًا)', fmt(comp)),
    ('الإجمالي (مركبة)', fmt(p + comp)),
  ];
}
