import '../../core/fmt.dart';
import '../../core/num_parse.dart';
import 'package:hijri_core/hijri_core.dart';
import '../arabic/hijri_logic.dart' show hijriMonths;
import '../more/more_logic.dart' show fmtIsoDate;
import '../time/time_logic.dart' show weekdayAr;

List<double>? nums(List<String> v) {
  final out = <double>[];
  for (final s in v) {
    final n = parseNum(s);
    if (n == null) return null;
    out.add(n);
  }
  return out;
}

Rows? percent(List<String> v) {
  final n = nums(v);
  if (n == null) return null;
  final a = n[0], b = n[1];
  return [
    ('${fmt(a)}% من ${fmt(b)}', fmt(b * a / 100)),
    ('${fmt(a)} تمثل من ${fmt(b)}', b == 0 ? '—' : '${fmt(a / b * 100)}%'),
    ('التغير من ${fmt(a)} إلى ${fmt(b)}',
        a == 0 ? '—' : '${fmt((b - a) / a.abs() * 100)}%'),
  ];
}

Rows? bmi(List<String> v) {
  final n = nums(v);
  if (n == null || n[0] <= 0 || n[1] <= 0 || n[1] > 300 || n[0] > 700) {
    return null;
  }
  final m = n[1] / 100;
  final b = n[0] / (m * m);
  final c = b < 18.5
      ? 'نحافة'
      : b < 25
          ? 'وزن طبيعي'
          : b < 30
              ? 'زيادة وزن'
              : 'سمنة';
  return [('مؤشر كتلة الجسم', fmt(b)), ('التصنيف', c)];
}

int _hLen(int y, int m) => isValidHijriDate(y, m, 30) ? 30 : 29;

({int y, int m, int d}) _span(
    (int, int, int) from, (int, int, int) to, int Function() prevLen) {
  var yy = to.$1 - from.$1, mm = to.$2 - from.$2, dd = to.$3 - from.$3;
  if (dd < 0) {
    mm--;
    dd += prevLen();
  }
  if (mm < 0) {
    yy--;
    mm += 12;
  }
  return (y: yy, m: mm, d: dd);
}

String _spanText(({int y, int m, int d}) r) => '${r.y} سنة و ${r.m} شهر و ${r.d} يوم';

/// حاسبة العمر. القيم: [التقويم 'g' أو 'h'، السنة، الشهر، اليوم] (أو 3 قيم ميلادية فقط).
/// تعرض النتيجة بالميلادي والهجري معًا مهما كان تقويم الإدخال.
Rows? age(List<String> v, [DateTime? now]) {
  final hijriIn = v.length == 4 && v[0] == 'h';
  final n = nums(v.length == 4 ? v.sublist(1) : v);
  if (n == null || n.length != 3 || n.any((x) => x != x.roundToDouble())) {
    return null;
  }
  final y = n[0].toInt(), m = n[1].toInt(), d = n[2].toInt();
  final t0 = now ?? DateTime.now();
  final today = DateTime.utc(t0.year, t0.month, t0.day);
  DateTime b;
  if (hijriIn) {
    if (y < 1318 || y > 1500 || m < 1 || m > 12 || d < 1 || d > 30 ||
        !isValidHijriDate(y, m, d)) {
      return null;
    }
    final g = toGregorian(y, m, d);
    if (g == null) return null;
    b = DateTime.utc(g.year, g.month, g.day);
  } else {
    if (y < 1900 || y > today.year || m < 1 || m > 12 || d < 1 || d > 31) {
      return null;
    }
    b = DateTime.utc(y, m, d);
    if (b.month != m || b.day != d) return null;
  }
  if (b.isAfter(today)) return null;

  final gAge = _span((b.year, b.month, b.day), (today.year, today.month, today.day),
      () => DateTime.utc(today.year, today.month, 0).day);
  final hb = hijriIn ? null : toHijri(b);
  final bh = hijriIn ? (y, m, d) : (hb == null ? null : (hb.hy, hb.hm, hb.hd));
  final ht = toHijri(today);
  final th = ht == null ? null : (ht.hy, ht.hm, ht.hd);

  String? hAge;
  if (bh != null && th != null) {
    hAge = _spanText(_span(bh, th, () {
      final pm = th.$2 == 1 ? 12 : th.$2 - 1;
      final py = th.$2 == 1 ? th.$1 - 1 : th.$1;
      return _hLen(py, pm);
    }));
  }

  int? nextDays;
  if (hijriIn && bh != null && th != null) {
    DateTime? nx(int yr) {
      final g = toGregorian(yr, bh.$2, isValidHijriDate(yr, bh.$2, bh.$3) ? bh.$3 : 29);
      return g == null ? null : DateTime.utc(g.year, g.month, g.day);
    }
    var next = nx(th.$1);
    if (next != null && next.isBefore(today)) next = nx(th.$1 + 1);
    nextDays = next?.difference(today).inDays;
  } else {
    var next = DateTime.utc(today.year, b.month, b.day);
    if (next.month != b.month) next = DateTime.utc(today.year, b.month + 1, 0);
    if (next.isBefore(today)) {
      next = DateTime.utc(today.year + 1, b.month, b.day);
      if (next.month != b.month) next = DateTime.utc(today.year + 1, b.month + 1, 0);
    }
    nextDays = next.difference(today).inDays;
  }

  return [
    ('العمر بالميلادي', _spanText(gAge)),
    if (hAge != null) ('العمر بالهجري', hAge),
    ('تاريخ الميلاد (ميلادي)', '${fmtIsoDate(b)} (${weekdayAr(b)})'),
    if (bh != null) ('تاريخ الميلاد (هجري)', '${bh.$3} ${hijriMonths[bh.$2 - 1]} ${bh.$1} هـ'),
    ('إجمالي الأيام', '${today.difference(b).inDays}'),
    ('باقي على عيد الميلاد', nextDays == null ? '—' : '$nextDays يوم'),
  ];
}

Rows? average(List<String> v) {
  final toks =
      v[0].split(RegExp(r'[\s,،;؛]+')).where((s) => s.isNotEmpty).toList();
  if (toks.isEmpty) return null;
  final xs = <double>[];
  for (final t in toks) {
    final n = parseNum(t);
    if (n == null) return null;
    xs.add(n);
  }
  final sum = xs.fold<double>(0, (a, b) => a + b);
  final s = [...xs]..sort();
  final mid = s.length ~/ 2;
  final med = s.length.isOdd ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  return [
    ('المتوسط', fmt(sum / xs.length)),
    ('المجموع', fmt(sum)),
    ('العدد', '${xs.length}'),
    ('الوسيط', fmt(med)),
    ('الأصغر', fmt(s.first)),
    ('الأكبر', fmt(s.last)),
  ];
}
