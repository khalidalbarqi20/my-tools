import '../../core/fmt.dart';
import 'calc_logic.dart' show nums;

/// السعرات اليومية. القيم: [الجنس m/f، العمر، الوزن كجم، الطول سم، معامل النشاط، الهدف lose/keep/gain].
/// معادلة Mifflin-St Jeor. الهدف لا ينزل أبدًا تحت معدل الحرق الأساسي.
Rows? calories(List<String> v) {
  if (v.length != 6 || (v[0] != 'm' && v[0] != 'f')) return null;
  final n = nums(v.sublist(1, 4));
  final act = double.tryParse(v[4]);
  if (n == null || act == null || act < 1.2 || act > 1.9) return null;
  final age = n[0], w = n[1], h = n[2];
  if (age != age.roundToDouble() || age < 18 || age > 90) return null;
  if (w < 30 || w > 300 || h < 120 || h > 250) return null;
  final bmr = 10 * w + 6.25 * h - 5 * age + (v[0] == 'm' ? 5 : -161);
  final tdee = bmr * act;
  var target = switch (v[5]) {
    'lose' => tdee - 500,
    'gain' => tdee + 300,
    _ => tdee,
  };
  var floored = false;
  if (target < bmr) {
    target = bmr;
    floored = true;
  }
  String r(double x) => '${x.round()} سعرة';
  return [
    ('معدل الحرق الأساسي (BMR)', r(bmr)),
    ('احتياجك للثبات (TDEE)', r(tdee)),
    ('السعرات المناسبة لهدفك', r(target)),
    if (v[5] == 'lose')
      ('الأثر التقريبي', floored ? 'نزول بطيء (لا يُنصح بأقل من معدل الحرق الأساسي)' : 'نزول نحو 0.5 كجم أسبوعيًا'),
    if (v[5] == 'gain') ('الأثر التقريبي', 'زيادة نحو 0.25 كجم أسبوعيًا'),
  ];
}

/// الماكروز. القيم: [الوزن كجم، السعرات اليومية، الهدف lose/keep/gain].
/// بروتين 1.8 / 1.4 / 1.8 جم لكل كجم، دهون 25% من السعرات، والباقي كربوهيدرات.
Rows? macros(List<String> v) {
  if (v.length != 3) return null;
  final n = nums(v.sublist(0, 2));
  if (n == null) return null;
  final w = n[0], kcal = n[1];
  if (w < 30 || w > 300 || kcal < 1000 || kcal > 6000) return null;
  final pg = w * (v[2] == 'keep' ? 1.4 : 1.8);
  final fg = kcal * 0.25 / 9;
  final cg = (kcal - pg * 4 - fg * 9) / 4;
  if (cg < 0) return null;
  String pct(double kc) => '${(kc / kcal * 100).round()}%';
  String line(double g, int per) => '${g.round()} جم (${pct(g * per)})';
  return [
    ('البروتين', line(pg, 4)),
    ('الكربوهيدرات', line(cg, 4)),
    ('الدهون', line(fg, 9)),
    ('البروتين لكل كجم', '${fmt(pg / w, 1)} جم'),
  ];
}
