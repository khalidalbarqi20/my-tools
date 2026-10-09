import 'dart:convert';
import 'dart:math';
import '../../core/fmt.dart';
import '../../core/num_parse.dart';
import '../extras/extras_logic.dart' show toWesternDigits;
import '../time/time_logic.dart' show weekdayAr;

// ───────────── أدوات مساعدة ─────────────
/// الحقل الفارغ = null، وغير الصالح يُفشل العملية كلها (null).
List<double?>? _opt(List<String> v) {
  final out = <double?>[];
  for (final s in v) {
    if (s.trim().isEmpty) {
      out.add(null);
      continue;
    }
    final n = parseNum(s);
    if (n == null || !n.isFinite) return null;
    out.add(n);
  }
  return out;
}

List<double>? _all(List<String> v, {bool positive = false}) {
  final o = _opt(v);
  if (o == null || o.any((e) => e == null)) return null;
  final r = [for (final e in o) e!];
  if (positive && r.any((e) => e <= 0)) return null;
  return r;
}

int _ceil(double x) => (x - 1e-9).ceil();
String _f(double x) => fmt(x, 3);

// ───────────── الهندسة ─────────────
Rows? geoRect(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final w = n[0], h = n[1];
  return [('المساحة', _f(w * h)), ('المحيط', _f(2 * (w + h))), ('القطر', _f(sqrt(w * w + h * h)))];
}

Rows? geoSquare(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final a = n[0];
  return [('المساحة', _f(a * a)), ('المحيط', _f(4 * a)), ('القطر', _f(a * sqrt2))];
}

Rows? geoTriangleSides(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final s3 = [...n]..sort();
  final a = s3[0], b = s3[1], c = s3[2];
  if (a + b <= c) return null; // لا يتكوّن مثلث
  final p = (a + b + c) / 2;
  final area = sqrt(p * (p - a) * (p - b) * (p - c));
  final sides = (a - b).abs() < 1e-9 && (b - c).abs() < 1e-9
      ? 'متساوي الأضلاع'
      : ((a - b).abs() < 1e-9 || (b - c).abs() < 1e-9 ? 'متساوي الساقين' : 'مختلف الأضلاع');
  final right = (a * a + b * b - c * c).abs() < 1e-9 * c * c;
  return [
    ('المساحة', _f(area)),
    ('المحيط', _f(a + b + c)),
    ('النوع', right ? '$sides، قائم الزاوية' : sides),
  ];
}

Rows? geoTriangleBH(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  return [('المساحة', _f(n[0] * n[1] / 2))];
}

Rows? geoCircle(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final r = n[0];
  return [('القطر', _f(2 * r)), ('المحيط', _f(2 * pi * r)), ('المساحة', _f(pi * r * r))];
}

Rows? geoTrapezoid(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  return [('المساحة', _f((n[0] + n[1]) / 2 * n[2]))];
}

Rows? geoParallelogram(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  return [('المساحة', _f(n[0] * n[1])), ('المحيط', _f(2 * (n[0] + n[2])))];
}

Rows? geoCube(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final a = n[0];
  return [
    ('الحجم', _f(a * a * a)),
    ('المساحة السطحية', _f(6 * a * a)),
    ('قطر المكعب', _f(a * sqrt(3))),
  ];
}

Rows? geoCuboid(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final l = n[0], w = n[1], h = n[2];
  return [
    ('الحجم', _f(l * w * h)),
    ('المساحة السطحية', _f(2 * (l * w + l * h + w * h))),
    ('القطر', _f(sqrt(l * l + w * w + h * h))),
  ];
}

Rows? geoCylinder(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final r = n[0], h = n[1];
  return [
    ('الحجم', _f(pi * r * r * h)),
    ('المساحة الجانبية', _f(2 * pi * r * h)),
    ('المساحة الكلية', _f(2 * pi * r * (r + h))),
  ];
}

Rows? geoCone(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final r = n[0], h = n[1];
  final l = sqrt(r * r + h * h);
  return [
    ('الحجم', _f(pi * r * r * h / 3)),
    ('الارتفاع المائل', _f(l)),
    ('المساحة الجانبية', _f(pi * r * l)),
    ('المساحة الكلية', _f(pi * r * (r + l))),
  ];
}

Rows? geoSphere(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final r = n[0];
  return [('الحجم', _f(4 / 3 * pi * r * r * r)), ('المساحة السطحية', _f(4 * pi * r * r))];
}

/// فيثاغورس: اترك ضلعًا واحدًا فارغًا ليُحسب. وإن ملأت الثلاثة نتحقق.
Rows? pythagoras(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 3 || o.any((e) => e != null && e <= 0)) return null;
  final blanks = [for (var i = 0; i < 3; i++) if (o[i] == null) i];
  if (blanks.length > 1) return null;
  const names = ['الضلع الأول (أ)', 'الضلع الثاني (ب)', 'الوتر (ج)'];
  if (blanks.isEmpty) {
    final a = o[0]!, b = o[1]!, c = o[2]!;
    final ok = (a * a + b * b - c * c).abs() <= 1e-9 * max(c * c, 1);
    return [('مثلث قائم؟', ok ? 'نعم' : 'لا')];
  }
  final i = blanks.first;
  double? r;
  if (i == 2) {
    r = sqrt(o[0]! * o[0]! + o[1]! * o[1]!);
  } else {
    final other = o[i == 0 ? 1 : 0]!, hyp = o[2]!;
    if (hyp <= other) return null;
    r = sqrt(hyp * hyp - other * other);
  }
  return [(names[i], _f(r))];
}

/// حل المثلث القائم: أدخل قيمتين على الأقل (ضلع واحد على الأقل). الزاوية بالدرجات.
Rows? rightTriangle(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 4) return null;
  final opp = o[0], adj = o[1], hyp = o[2], ang = o[3];
  if ([opp, adj, hyp].any((e) => e != null && e <= 0)) return null;
  if (ang != null && (ang <= 0 || ang >= 90)) return null;
  final given = [opp, adj, hyp, ang].where((e) => e != null).length;
  if (given != 2 || (opp == null && adj == null && hyp == null)) return null;
  const d2r = pi / 180;
  (double, double, double, double)? r;
  if (opp != null && adj != null) {
    r = (opp, adj, sqrt(opp * opp + adj * adj), atan(opp / adj) / d2r);
  } else if (opp != null && hyp != null) {
    if (hyp <= opp) return null;
    r = (opp, sqrt(hyp * hyp - opp * opp), hyp, asin(opp / hyp) / d2r);
  } else if (adj != null && hyp != null) {
    if (hyp <= adj) return null;
    r = (sqrt(hyp * hyp - adj * adj), adj, hyp, acos(adj / hyp) / d2r);
  } else if (ang != null && opp != null) {
    r = (opp, opp / tan(ang * d2r), opp / sin(ang * d2r), ang);
  } else if (ang != null && adj != null) {
    r = (adj * tan(ang * d2r), adj, adj / cos(ang * d2r), ang);
  } else if (ang != null && hyp != null) {
    r = (hyp * sin(ang * d2r), hyp * cos(ang * d2r), hyp, ang);
  }
  if (r == null) return null;
  final (o1, a1, h1, g1) = r;
  return [
    ('الضلع المقابل', _f(o1)),
    ('الضلع المجاور', _f(a1)),
    ('الوتر', _f(h1)),
    ('الزاوية (أ)', '${fmt(g1, 2)}°'),
    ('الزاوية الأخرى', '${fmt(90 - g1, 2)}°'),
    ('sin', fmt(sin(g1 * d2r), 4)),
    ('cos', fmt(cos(g1 * d2r), 4)),
    ('tan', fmt(tan(g1 * d2r), 4)),
  ];
}

// ───────────── العلوم ─────────────
/// قانون من ثلاثة متغيرات: v0 = v1 × v2 (mul) أو v0 = v1 ÷ v2. اترك متغيرًا واحدًا فارغًا.
Rows? solveTriple(List<String> v, {required bool mul, required List<String> labels}) {
  final o = _opt(v);
  if (o == null || o.length != 3) return null;
  final blanks = [for (var i = 0; i < 3; i++) if (o[i] == null) i];
  if (blanks.length != 1) return null;
  final i = blanks.first;
  double? r;
  if (i == 0) {
    final b = o[1]!, c = o[2]!;
    r = mul ? b * c : (c == 0 ? null : b / c);
  } else if (i == 1) {
    final a = o[0]!, c = o[2]!;
    r = mul ? (c == 0 ? null : a / c) : a * c;
  } else {
    final a = o[0]!, b = o[1]!;
    r = mul ? (b == 0 ? null : a / b) : (a == 0 ? null : b / a);
  }
  if (r == null || !r.isFinite) return null;
  return [
    (labels[i], fmtSig(r)),
    ('القانون', '${labels[0]} = ${labels[1]} ${mul ? '×' : '÷'} ${labels[2]}'),
  ];
}

Rows? energyRows(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 3) return null;
  final m = o[0], vel = o[1], h = o[2];
  if (m == null || m <= 0 || (vel == null && h == null)) return null;
  if ((vel != null && vel < 0) || (h != null && h < 0)) return null;
  final rows = <(String, String)>[];
  var total = 0.0;
  if (vel != null) {
    final ke = 0.5 * m * vel * vel;
    total += ke;
    rows.add(('الطاقة الحركية (جول)', fmtSig(ke)));
  }
  if (h != null) {
    final pe = m * 9.80665 * h;
    total += pe;
    rows.add(('طاقة الوضع (جول)', fmtSig(pe)));
  }
  if (rows.length == 2) rows.add(('المجموع (جول)', fmtSig(total)));
  return rows;
}

List<double>? parseNumberList(String s) {
  final t = s.split(RegExp(r'[\s,،;؛]+')).where((e) => e.isNotEmpty).toList();
  if (t.isEmpty || t.length > 100000) return null;
  final out = <double>[];
  for (final e in t) {
    final n = parseNum(e);
    if (n == null || !n.isFinite) return null;
    out.add(n);
  }
  return out;
}

String statsText(String input) {
  final xs = parseNumberList(input);
  if (xs == null) {
    throw const FormatException('أدخل أرقامًا فقط، يفصل بينها مسافة أو فاصلة أو سطر جديد');
  }
  final n = xs.length;
  final sorted = [...xs]..sort();
  final sum = xs.fold<double>(0, (a, b) => a + b);
  final mean = sum / n;
  final median = n.isOdd ? sorted[n ~/ 2] : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  final freq = <double, int>{};
  for (final x in xs) {
    freq[x] = (freq[x] ?? 0) + 1;
  }
  final top = freq.values.reduce(max);
  final modes = top == 1 ? <double>[] : (freq.entries.where((e) => e.value == top).map((e) => e.key).toList()..sort());
  final ss = xs.fold<double>(0, (a, b) => a + (b - mean) * (b - mean));
  final popVar = ss / n;
  final lines = <String>[
    'العدد: $n',
    'المجموع: ${fmtSig(sum)}',
    'المتوسط: ${fmtSig(mean)}',
    'الوسيط: ${fmtSig(median)}',
    'المنوال: ${modes.isEmpty ? 'لا يوجد' : modes.take(6).map(fmtSig).join('، ')}',
    'أصغر قيمة: ${fmtSig(sorted.first)}',
    'أكبر قيمة: ${fmtSig(sorted.last)}',
    'المدى: ${fmtSig(sorted.last - sorted.first)}',
    'التباين (مجتمع): ${fmtSig(popVar)}',
    'الانحراف المعياري (مجتمع): ${fmtSig(sqrt(popVar))}',
  ];
  if (n > 1) {
    final sv = ss / (n - 1);
    lines.add('التباين (عينة): ${fmtSig(sv)}');
    lines.add('الانحراف المعياري (عينة): ${fmtSig(sqrt(sv))}');
  }
  return lines.join('\n');
}

Rows? probabilityRows(List<String> v) {
  final n = _all(v);
  if (n == null) return null;
  final f = n[0], t = n[1];
  if (f < 0 || t <= 0 || f > t) return null;
  final p = f / t;
  return [
    ('الاحتمال', fmt(p, 4)),
    ('كنسبة مئوية', '${fmt(p * 100, 2)}%'),
    ('احتمال عدم الحدوث', '${fmt((1 - p) * 100, 2)}%'),
    ('الفرص (حدوث : عدم حدوث)', '${fmt(f)} : ${fmt(t - f)}'),
  ];
}

String _big(BigInt b) {
  final s = b.toString();
  if (s.length <= 15) return s;
  return '${s[0]}.${s.substring(1, 6)} × 10^${s.length - 1}';
}

Rows? combinatoricsRows(List<String> v) {
  final n = _all(v);
  if (n == null || n.any((e) => e != e.roundToDouble() || e < 0)) return null;
  final nn = n[0].toInt(), r = n[1].toInt();
  if (nn > 500 || r > nn) return null;
  BigInt fact(int k) {
    var x = BigInt.one;
    for (var i = 2; i <= k; i++) {
      x *= BigInt.from(i);
    }
    return x;
  }

  final f = fact(nn);
  final perm = f ~/ fact(nn - r);
  final comb = perm ~/ fact(r);
  return [('التباديل P($nn,$r)', _big(perm)), ('التوافيق C($nn,$r)', _big(comb)), ('$nn!', _big(f))];
}

// ───────────── المال ─────────────
String unitPriceText(String input) {
  const err = 'اكتب في كل سطر الكمية ثم السعر، مثال:\n12 18\n20 27';
  final items = <(double, double, String)>[];
  var line = 0;
  for (final raw in input.split('\n')) {
    line++;
    if (raw.trim().isEmpty) continue;
    final t = toWesternDigits(raw).replaceAll('٫', '.').replaceAll(',', '.');
    final nums = RegExp(r'\d+(?:\.\d+)?').allMatches(t).map((m) => m[0]!).toList();
    if (nums.length < 2) throw FormatException('السطر $line: $err');
    final q = double.parse(nums[0]), p = double.parse(nums[1]);
    if (q <= 0) throw FormatException('السطر $line: الكمية يجب أن تكون أكبر من صفر');
    final label = t.replaceAll(RegExp(r'[\d.=:؛;]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    items.add((q, p, label));
  }
  if (items.isEmpty) throw const FormatException(err);
  final units = [for (final e in items) e.$2 / e.$1];
  final minU = units.reduce(min), maxU = units.reduce(max);
  final best = units.indexOf(minU);
  final out = <String>[];
  for (var i = 0; i < items.length; i++) {
    final name = items[i].$3.isEmpty ? 'الخيار ${i + 1}' : items[i].$3;
    out.add('${i + 1}) $name: ${fmt(items[i].$1, 3)} بسعر ${fmt(items[i].$2, 2)} ← ${fmt(units[i], 4)} للوحدة${i == best ? '  ✓ الأرخص' : ''}');
  }
  if (items.length > 1 && maxU > minU) {
    out.add('');
    out.add('الأرخص: ${items[best].$3.isEmpty ? 'الخيار ${best + 1}' : items[best].$3}، أرخص من الأغلى بنسبة ${fmt((maxU - minU) / maxU * 100, 1)}%');
  } else if (items.length > 1) {
    out.add('');
    out.add('كل الخيارات بنفس سعر الوحدة');
  }
  return out.join('\n');
}

Rows? successiveDiscount(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 4 || o[0] == null || o[0]! <= 0) return null;
  final price = o[0]!;
  final ds = [for (final d in o.skip(1)) if (d != null) d];
  if (ds.isEmpty || ds.any((d) => d < 0 || d > 100)) return null;
  var cur = price;
  final rows = <(String, String)>[];
  for (var i = 0; i < ds.length; i++) {
    cur *= 1 - ds[i] / 100;
    rows.add(('بعد الخصم ${i + 1} (${fmt(ds[i])}%)', fmt(cur)));
  }
  rows.add(('السعر النهائي', fmt(cur)));
  rows.add(('إجمالي الخصم الفعلي', '${fmt((1 - cur / price) * 100)}%'));
  rows.add(('قيمة التوفير', fmt(price - cur)));
  return rows;
}

Rows? finalPrice(List<String> v) {
  final n = _all(v);
  if (n == null) return null;
  final p = n[0], d = n[1], t = n[2];
  if (p < 0 || d < 0 || d > 100 || t < 0) return null;
  final after = p * (1 - d / 100);
  final tax = after * t / 100;
  return [
    ('قيمة الخصم', fmt(p - after)),
    ('السعر بعد الخصم', fmt(after)),
    ('قيمة الضريبة', fmt(tax)),
    ('السعر النهائي', fmt(after + tax)),
  ];
}

Rows? salaryRows(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 6 || o[0] == null || o[0]! <= 0) return null;
  final basic = o[0]!, housing = o[1] ?? 0.0, transport = o[2] ?? 0.0, other = o[3] ?? 0.0;
  final pct = o[4] ?? 0.0, ded = o[5] ?? 0.0;
  if ([housing, transport, other, pct, ded].any((e) => e < 0) || pct > 100) return null;
  final gross = basic + housing + transport + other;
  final cut = (basic + housing) * pct / 100 + ded;
  final net = gross - cut;
  return [
    ('إجمالي الراتب', fmt(gross)),
    ('إجمالي الاستقطاعات', fmt(cut)),
    ('الصافي', fmt(net)),
    ('الصافي لليوم (÷30)', fmt(net / 30)),
  ];
}

// ───────────── السيارة ─────────────
Rows? fuelEconomy(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final km = n[0], l = n[1];
  return [('لتر لكل 100 كم', fmt(l / km * 100)), ('كم لكل لتر', fmt(km / l))];
}

const _mpgUs = 235.214583, _mpgUk = 282.480936;

String fuelUnitsText(String input, String from) {
  final x = parseNum(input);
  if (x == null || x <= 0 || !x.isFinite) throw const FormatException('أدخل رقمًا أكبر من صفر');
  final l100 = switch (from) {
    'kmpl' => 100 / x,
    'mpgus' => _mpgUs / x,
    'mpguk' => _mpgUk / x,
    _ => x,
  };
  return 'لتر لكل 100 كم: ${fmt(l100, 2)}\n'
      'كم لكل لتر: ${fmt(100 / l100, 2)}\n'
      'ميل لكل غالون (أمريكي): ${fmt(_mpgUs / l100, 2)}\n'
      'ميل لكل غالون (بريطاني): ${fmt(_mpgUk / l100, 2)}';
}

Rows? tripDuration(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 3 || o[0] == null || o[1] == null) return null;
  final km = o[0]!, speed = o[1]!, brk = o[2] ?? 0.0;
  if (km <= 0 || speed <= 0 || brk < 0) return null;
  final mins = (km / speed * 60 + brk).round();
  return [
    ('مدة الرحلة', hoursMinutes(mins)),
    ('بالساعات', fmt(mins / 60)),
  ];
}

String hoursMinutes(int mins) {
  final h = mins ~/ 60, m = mins % 60;
  if (h == 0) return '$m دقيقة';
  if (m == 0) return '$h ساعة';
  return '$h ساعة و$m دقيقة';
}

Rows? tripSplit(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 5 || o[0] == null || o[1] == null || o[2] == null || o[4] == null) {
    return null;
  }
  final km = o[0]!, c = o[1]!, price = o[2]!, extra = o[3] ?? 0.0, people = o[4]!;
  if (km < 0 || c <= 0 || price < 0 || extra < 0 || people < 1 || people != people.roundToDouble() || people > 1000) {
    return null;
  }
  final fuel = km * c / 100 * price;
  final total = fuel + extra;
  return [
    ('تكلفة الوقود', fmt(fuel)),
    ('إجمالي الرحلة', fmt(total)),
    ('نصيب كل شخص', fmt(total / people)),
  ];
}

// ───────────── المنزل ─────────────
Rows? roomAreaRows(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 3 || o[0] == null || o[1] == null) return null;
  final l = o[0]!, w = o[1]!, h = o[2];
  if (l <= 0 || w <= 0 || (h != null && h <= 0)) return null;
  return [
    ('مساحة الأرضية', '${_f(l * w)} م²'),
    ('المحيط', '${_f(2 * (l + w))} م'),
    if (h != null) ('مساحة الجدران', '${_f(2 * (l + w) * h)} م²'),
    if (h != null) ('حجم الغرفة', '${_f(l * w * h)} م³'),
  ];
}

Rows? tilesRows(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 6 || o[0] == null || o[1] == null || o[2] == null || o[3] == null) {
    return null;
  }
  final l = o[0]!, w = o[1]!, tl = o[2]!, tw = o[3]!, waste = o[4] ?? 10.0, box = o[5] ?? 0.0;
  if (l <= 0 || w <= 0 || tl <= 0 || tw <= 0 || waste < 0 || waste > 100 || box < 0) return null;
  final area = l * w;
  final one = tl * tw / 10000;
  final raw = _ceil(area / one);
  final withWaste = _ceil(area / one * (1 + waste / 100));
  return [
    ('مساحة الغرفة', '${_f(area)} م²'),
    ('مساحة البلاطة', '${fmt(one, 4)} م²'),
    ('عدد البلاط بدون هدر', '$raw'),
    ('عدد البلاط مع الهدر (${fmt(waste)}%)', '$withWaste'),
    ('المساحة المشتراة', '${_f(withWaste * one)} م²'),
    if (box >= 1) ('عدد الكراتين', '${_ceil(withWaste / box)}'),
  ];
}

Rows? paintRows(List<String> v) {
  final o = _opt(v);
  if (o == null || o.length != 6 || o[0] == null || o[1] == null || o[2] == null) return null;
  final l = o[0]!, w = o[1]!, h = o[2]!, open = o[3] ?? 0.0, coats = o[4] ?? 2.0, cover = o[5] ?? 10.0;
  if (l <= 0 || w <= 0 || h <= 0 || open < 0 || coats < 1 || cover <= 0) return null;
  final walls = 2 * (l + w) * h - open;
  if (walls <= 0) return null;
  final liters = walls * coats / cover;
  return [
    ('مساحة الجدران المطلوب دهانها', '${_f(walls)} م²'),
    ('كمية الدهان', '${fmt(liters, 2)} لتر'),
    ('مع احتياطي 10%', '${fmt(liters * 1.1, 2)} لتر'),
    ('مساحة السقف (إن أردت دهانه)', '${_f(l * w)} م²'),
  ];
}

Rows? tankRect(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final m3 = n[0] * n[1] * n[2];
  return [('الحجم', '${fmt(m3, 3)} م³'), ('السعة', '${fmt(m3 * 1000, 1)} لتر')];
}

Rows? tankCylinder(List<String> v) {
  final n = _all(v, positive: true);
  if (n == null) return null;
  final r = n[0] / 2;
  final m3 = pi * r * r * n[1];
  return [('الحجم', '${fmt(m3, 3)} م³'), ('السعة', '${fmt(m3 * 1000, 1)} لتر')];
}

// ───────────── التاريخ والوقت ─────────────
DateTime? parseDate(String s) {
  final t = toWesternDigits(s).trim();
  var m = RegExp(r'^(\d{4})\D+(\d{1,2})\D+(\d{1,2})$').firstMatch(t);
  int? y, mo, d;
  if (m != null) {
    y = int.parse(m[1]!);
    mo = int.parse(m[2]!);
    d = int.parse(m[3]!);
  } else {
    m = RegExp(r'^(\d{1,2})\D+(\d{1,2})\D+(\d{4})$').firstMatch(t);
    if (m == null) return null;
    d = int.parse(m[1]!);
    mo = int.parse(m[2]!);
    y = int.parse(m[3]!);
  }
  if (y < 1 || y > 9999 || mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final r = DateTime.utc(y, mo, d);
  return r.month == mo && r.day == d ? r : null;
}

String fmtIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime addToDate(DateTime d, {int years = 0, int months = 0, int days = 0}) {
  final total = d.year * 12 + (d.month - 1) + years * 12 + months;
  final y = total ~/ 12, m = total % 12 + 1;
  final last = DateTime.utc(y, m + 1, 0).day;
  return DateTime.utc(y, m, min(d.day, last)).add(Duration(days: days));
}

Rows? addDatesRows(List<String> v) {
  final d = parseDate(v[0]);
  if (d == null) return null;
  final o = _opt(v.sublist(1));
  if (o == null || o.any((e) => e != null && e != e.roundToDouble())) return null;
  final days = (o[0] ?? 0.0).toInt(), months = (o[1] ?? 0.0).toInt(), years = (o[2] ?? 0.0).toInt();
  if (days.abs() > 3660000 || months.abs() > 120000 || years.abs() > 10000) return null;
  final r = addToDate(d, years: years, months: months, days: days);
  if (r.year < 1 || r.year > 9999) return null;
  return [('التاريخ الناتج', fmtIsoDate(r)), ('يوم الأسبوع', weekdayAr(r))];
}

int _weeksInYear(int y) {
  int p(int x) => (x + x ~/ 4 - x ~/ 100 + x ~/ 400) % 7;
  return (p(y) == 4 || p(y - 1) == 3) ? 53 : 52;
}

int isoWeek(DateTime d) {
  final doy = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
  final w = (doy - d.weekday + 10) ~/ 7;
  if (w < 1) return _weeksInYear(d.year - 1);
  if (w > _weeksInYear(d.year)) return 1;
  return w;
}

bool isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

Rows? weekdayRows(List<String> v) {
  final d = parseDate(v[0]);
  if (d == null) return null;
  final doy = d.difference(DateTime.utc(d.year, 1, 1)).inDays + 1;
  return [
    ('يوم الأسبوع', weekdayAr(d)),
    ('ترتيب اليوم في السنة', '$doy'),
    ('رقم الأسبوع في السنة', '${isoWeek(d)}'),
    ('السنة', isLeap(d.year) ? 'كبيسة' : 'عادية'),
  ];
}

/// "9", "9:30", "17:45", "30:15:10" (الساعات مفتوحة). يرجع الثواني أو null.
int? parseClock(String s) {
  final t = toWesternDigits(s).trim();
  final m = RegExp(r'^(\d{1,3})(?::(\d{1,2}))?(?::(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final h = int.parse(m[1]!), mi = int.parse(m[2] ?? '0'), se = int.parse(m[3] ?? '0');
  if (mi > 59 || se > 59) return null;
  return h * 3600 + mi * 60 + se;
}

String fmtHms(int secs) {
  final h = secs ~/ 3600, m = secs % 3600 ~/ 60, s = secs % 60;
  String p(int x) => x.toString().padLeft(2, '0');
  return '${p(h)}:${p(m)}:${p(s)}';
}

Rows? workHoursRows(List<String> v) {
  final a = parseClock(v[0]), b = parseClock(v[1]);
  if (a == null || b == null || a >= 86400 || b >= 86400 || a == b) return null;
  final o = _opt(v.sublist(2));
  if (o == null || o.length != 3) return null;
  final brk = o[0] ?? 0.0, rate = o[1] ?? 0.0, days = o[2] ?? 1.0;
  if (brk < 0 || rate < 0 || days < 1 || days != days.roundToDouble() || days > 366) return null;
  var mins = (b - a) ~/ 60;
  if (mins < 0) mins += 1440; // دوام ليلي يمتد لليوم التالي
  mins -= brk.round();
  if (mins <= 0) return null;
  final hrs = mins / 60;
  return [
    ('ساعات العمل اليومية', hoursMinutes(mins)),
    ('بالساعات العشرية', fmt(hrs, 2)),
    if (days > 1) ('إجمالي ${days.toInt()} يوم', '${fmt(hrs * days, 2)} ساعة'),
    if (rate > 0) ('الأجر اليومي', fmt(hrs * rate)),
    if (rate > 0 && days > 1) ('إجمالي الأجر', fmt(hrs * rate * days)),
  ];
}

Rows? addTimeRows(List<String> v) {
  final a = parseClock(v[0]), b = parseClock(v[1]);
  if (a == null || b == null) return null;
  final diff = a - b;
  return [
    ('المجموع', fmtHms(a + b)),
    ('الفرق', '${diff < 0 ? '-' : ''}${fmtHms(diff.abs())}'),
  ];
}

// ───────────── النصوص ─────────────
int _depth(Object? j) {
  if (j is Map) return 1 + (j.values.isEmpty ? 0 : j.values.map(_depth).reduce(max));
  if (j is List) return 1 + (j.isEmpty ? 0 : j.map(_depth).reduce(max));
  return 0;
}

String jsonTool(String input, String mode) {
  if (input.trim().isEmpty) throw const FormatException('الصق نص JSON أولًا');
  Object? j;
  try {
    j = jsonDecode(input);
  } on FormatException catch (e) {
    final lm = RegExp(r'line (\d+), character (\d+)').firstMatch(e.message);
    if (lm != null) throw FormatException('JSON غير صالح قرب السطر ${lm[1]}، الحرف ${lm[2]}');
    final cm = RegExp(r'character (\d+)').firstMatch(e.message);
    if (e.message.contains('end of input')) {
      throw const FormatException('JSON غير صالح: انتهى النص قبل اكتمال البيانات');
    }
    if (cm != null) throw FormatException('JSON غير صالح قرب الحرف ${cm[1]}');
    throw const FormatException('JSON غير صالح');
  }
  switch (mode) {
    case 'minify':
      return jsonEncode(j);
    case 'validate':
      final type = j is Map ? 'كائن (Object)' : (j is List ? 'مصفوفة (Array)' : 'قيمة مفردة');
      final count = j is Map ? j.length : (j is List ? j.length : 1);
      return 'JSON صالح ✓\nالنوع: $type\nعدد العناصر في المستوى الأول: $count\nعمق التداخل: ${_depth(j)}';
    default:
      return const JsonEncoder.withIndent('  ').convert(j);
  }
}

String base64Tool(String input, {required bool decode, bool urlSafe = false}) {
  if (!decode) {
    var s = base64Encode(utf8.encode(input));
    if (urlSafe) s = s.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
    return s;
  }
  var t = input.replaceAll(RegExp(r'\s'), '').replaceAll('-', '+').replaceAll('_', '/');
  while (t.length % 4 != 0) {
    t += '=';
  }
  try {
    return utf8.decode(base64Decode(t));
  } on FormatException {
    throw const FormatException('نص Base64 غير صالح، أو أن ناتجه ليس نصًا');
  }
}

String urlTool(String input, {required bool decode, bool full = false}) {
  if (!decode) return full ? Uri.encodeFull(input) : Uri.encodeComponent(input);
  try {
    return full ? Uri.decodeFull(input) : Uri.decodeComponent(input);
  } catch (_) {
    throw const FormatException('النص يحتوي ترميزًا غير صالح');
  }
}
