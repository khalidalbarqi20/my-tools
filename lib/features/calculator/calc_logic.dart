import '../../core/fmt.dart';
import '../../core/num_parse.dart';

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

Rows? age(List<String> v, [DateTime? now]) {
  final n = nums(v);
  if (n == null || n.any((x) => x != x.roundToDouble())) return null;
  final y = n[0].toInt(), m = n[1].toInt(), d = n[2].toInt();
  final t0 = now ?? DateTime.now();
  final today = DateTime.utc(t0.year, t0.month, t0.day);
  if (y < 1900 || y > today.year || m < 1 || m > 12 || d < 1 || d > 31) {
    return null;
  }
  final b = DateTime.utc(y, m, d);
  if (b.month != m || b.day != d || b.isAfter(today)) return null;
  var yy = today.year - y, mm = today.month - m, dd = today.day - d;
  if (dd < 0) {
    mm--;
    dd += DateTime.utc(today.year, today.month, 0).day;
  }
  if (mm < 0) {
    yy--;
    mm += 12;
  }
  var next = DateTime.utc(today.year, m, d);
  if (next.isBefore(today)) next = DateTime.utc(today.year + 1, m, d);
  return [
    ('العمر', '$yy سنة و $mm شهر و $dd يوم'),
    ('إجمالي الأيام', '${today.difference(b).inDays}'),
    ('باقي على عيد الميلاد', '${next.difference(today).inDays} يوم'),
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
