import 'dart:math';
import '../../core/fmt.dart';
import 'cas.dart';
import 'frac.dart';
import 'poly.dart';

String _num(Frac f) => f.isInt ? '$f' : '$f (≈ ${fmt(f.toDouble(), 4)})';

class _Eq {
  final String text;
  final Poly diff; // الطرف الأيسر - الطرف الأيمن
  final Set<String> vars; // متغيرات الطرفين (قبل أن تتلاشى بالطرح)
  _Eq(this.text, this.diff, this.vars);
}

_Eq _parseEq(String s) {
  final parts = s.split('=');
  if (parts.length != 2 || parts[0].trim().isEmpty || parts[1].trim().isEmpty) {
    throw FormatException('المعادلة «$s» يجب أن تحتوي على علامة = واحدة وطرفين');
  }
  final l = PolyParser.parse(parts[0]), r = PolyParser.parse(parts[1]);
  return _Eq(s.trim(), l - r, {...l.vars, ...r.vars});
}

// ───────────────────────── التبسيط ─────────────────────────
String simplifyText(String input) {
  final p = PolyParser.parse(input);
  return [
    'التعبير: ${ltr(input.trim())}',
    'نفك الأقواس ونجمع الحدود المتشابهة:',
    ltr(polyToString(p)),
  ].join('\n');
}

// ───────────────────────── التحليل إلى عوامل ─────────────────────────
String factorText(String input) {
  final p = PolyParser.parse(input);
  if (p.isZero) return 'التعبير يساوي صفرًا.';
  final vars = p.vars.toList()..sort();
  final head = 'التعبير: ${ltr(polyToString(p))}';
  if (vars.isEmpty) {
    return '$head\nهذا عدد ثابت: ${ltr(polyToString(p))}';
  }
  if (vars.length == 1) {
    final v = vars.first;
    final f = factorUni(p.coeffs(v)!)!;
    final nFactors = f.roots.fold<int>(0, (a, e) => a + e.$2) + (f.rest.isEmpty ? 0 : 1);
    if (nFactors + (f.xPow > 0 ? 1 : 0) + (f.content == Frac.one ? 0 : 1) <= 1 && f.xPow == 0 && f.content == Frac.one) {
      return '$head\nلا يمكن تحليله أكثر على الأعداد النسبية.';
    }
    final lines = [head, 'نخرج العامل المشترك ثم نبحث عن الجذور النسبية:'];
    lines.add(ltr(factoredToString(f, v)));
    if (f.rest.isNotEmpty) {
      lines.add('الباقي ليس له جذور نسبية، فلا يتحلل أكثر على الأعداد النسبية.');
    }
    return lines.join('\n');
  }
  // عدة متغيرات: نخرج العامل المشترك فقط
  var l = BigInt.one;
  for (final c in p.t.values) {
    l = l * c.d ~/ l.gcd(c.d);
  }
  var g = BigInt.zero;
  for (final c in p.t.values) {
    g = g.gcd(c.n * (l ~/ c.d));
  }
  if (g == BigInt.zero) g = BigInt.one;
  var content = Frac(g, l);
  final lead = (p.t.entries.toList()
        ..sort((a, b) => b.key.degree.compareTo(a.key.degree) != 0
            ? b.key.degree.compareTo(a.key.degree)
            : a.key.key.compareTo(b.key.key)))
      .first
      .value;
  if (lead.isNegative) content = -content;
  final minExp = <String, int>{};
  for (final v in vars) {
    minExp[v] = p.t.keys.map((m) => m.e[v] ?? 0).reduce(min);
  }
  final common = Mono(minExp);
  final rest = Poly({
    for (final e in p.t.entries)
      Mono({for (final k in e.key.e.keys) k: e.key.e[k]! - (minExp[k] ?? 0)}): e.value / content,
  });
  if (content == Frac.one && common.degree == 0) {
    return '$head\nلا يوجد عامل مشترك، ولا يدعم التطبيق تحليل أكثر من متغير واحد.';
  }
  final cs = content == Frac.one ? '' : (content == -Frac.one ? '-' : (content.isInt ? '${content}' : '($content)'));
  final ms = common.degree == 0
      ? ''
      : common.e.entries.map((e) => e.value == 1 ? e.key : '${e.key}^${e.value}').join();
  return [head, 'نخرج العامل المشترك الأكبر:', ltr('$cs$ms(${polyToString(rest)})')].join('\n');
}

// ───────────────────────── حل معادلة بمتغير واحد ─────────────────────────
List<String> _solveUni(String text, Poly diff, String v) {
  final lines = <String>['المعادلة: ${ltr(text)}'];
  final c0 = diff.coeffs(v)!;
  var c = [...c0];
  while (c.length > 1 && c.last.isZero) {
    c.removeLast();
  }
  lines.add('ننقل كل الحدود إلى طرف واحد ونبسّط:');
  lines.add(ltr('${polyToString(diff)} = 0'));
  final deg = c.length - 1;
  if (deg == 0) {
    lines.add(c[0].isZero ? 'المعادلة صحيحة لكل قيم $v (عدد لا نهائي من الحلول).' : 'لا يوجد حل (التناقض: ${c[0]} = 0).');
    return lines;
  }
  if (deg == 1) {
    final a = c[1], b = c[0];
    lines.add('معادلة من الدرجة الأولى، نعزل $v:');
    lines.add(ltr('${polyToString(Poly.fromCoeffs([Frac.zero, a], v))} = ${-b}'));
    if (a != Frac.one) {
      lines.add(ltr('$v = ${-b} ÷ ${a.isNegative ? '($a)' : '$a'}'));
    }
    lines.add('الحل: ${ltr('$v = ${_num(-b / a)}')}');
    return lines;
  }
  if (deg == 2) {
    lines.add('معادلة تربيعية: نستخدم القانون العام.');
    final (steps, roots) = quadraticSteps(c[2], c[1], c[0], v);
    lines.addAll(steps);
    if (roots.isEmpty) lines.add('لا توجد جذور حقيقية.');
    return lines;
  }
  // درجة ≥ 3
  final f = factorUni(c)!;
  lines.add('معادلة من الدرجة $deg. نحللها بالجذور النسبية:');
  lines.add(ltr('${factoredToString(f, v)} = 0'));
  final sols = <String>[];
  if (f.xPow > 0) sols.add('$v = 0');
  for (final (r, m) in f.roots) {
    sols.add('$v = ${_num(r)}${m > 1 ? '   (مكرر $m مرات)' : ''}');
  }
  if (f.rest.isNotEmpty) {
    final rd = f.rest.length - 1;
    if (rd == 2) {
      lines.add('الباقي تربيعي:');
      final (steps, roots) = quadraticSteps(f.rest[2], f.rest[1], f.rest[0], v);
      lines.addAll(steps);
      for (final r in roots) {
        sols.add('$v ≈ ${fmt(r, 4)}');
      }
    } else {
      final roots = realRootsNumeric(f.rest);
      lines.add('الباقي من الدرجة $rd بدون جذور نسبية، فنحسب الجذور الحقيقية تقريبيًا.');
      for (final r in roots.take(12)) {
        sols.add('$v ≈ ${fmt(r, 4)}');
      }
      if (roots.isEmpty) lines.add('لا توجد جذور حقيقية إضافية.');
    }
  }
  lines.add('الحلول الحقيقية:');
  for (final s in sols) {
    lines.add(ltr(s));
  }
  if (sols.isEmpty) lines.add('لا توجد حلول حقيقية.');
  return lines;
}

// ───────────────────────── نظام معادلتين خطيتين ─────────────────────────
List<String> _solveSystem(List<_Eq> eqs, List<String> vs) {
  final x = vs[0], y = vs[1];
  final co = <List<Frac>>[]; // a, b, c  حيث a x + b y = c
  for (final e in eqs) {
    if (e.diff.degree > 1) {
      throw const FormatException('حل الأنظمة مدعوم للمعادلات الخطية فقط (بدون حدود مثل x^2 أو xy)');
    }
    Frac cf(String v) => e.diff.t[Mono(<String, int>{v: 1})] ?? Frac.zero;
    co.add([cf(x), cf(y), -e.diff.constantTerm]);
  }
  final lines = <String>['نظام معادلتين خطيتين بمجهولين:'];
  for (var k = 0; k < 2; k++) {
    lines.add('المعادلة ${k + 1}: ${ltr(eqs[k].text)}');
  }
  lines.add('نكتبهما بالصيغة a$x + b$y = c:');
  for (var k = 0; k < 2; k++) {
    lines.add(ltr('(${co[k][0]})$x + (${co[k][1]})$y = ${co[k][2]}'));
  }
  final a1 = co[0][0], b1 = co[0][1], c1 = co[0][2];
  final a2 = co[1][0], b2 = co[1][1], c2 = co[1][2];
  final d = a1 * b2 - a2 * b1;
  final dx = c1 * b2 - c2 * b1;
  final dy = a1 * c2 - a2 * c1;
  lines.add('نستخدم طريقة كرامر (المحددات):');
  lines.add(ltr('D = a1·b2 - a2·b1 = $d'));
  lines.add(ltr('D$x = c1·b2 - c2·b1 = $dx'));
  lines.add(ltr('D$y = a1·c2 - a2·c1 = $dy'));
  if (d.isZero) {
    lines.add(dx.isZero && dy.isZero
        ? 'D = 0 والمعادلتان متكافئتان: عدد لا نهائي من الحلول.'
        : 'D = 0 والمستقيمان متوازيان: لا يوجد حل.');
    return lines;
  }
  lines.add('الحل:');
  lines.add(ltr('$x = D$x / D = ${_num(dx / d)}'));
  lines.add(ltr('$y = D$y / D = ${_num(dy / d)}'));
  return lines;
}

// ───────────────────────── المتباينات ─────────────────────────
String _fmtB(double x) => fmt(x, 4);

List<String> _solveIneq(String t) {
  final m = RegExp(r'(≤|≥|<|>)').firstMatch(t);
  if (m == null || RegExp(r'(≤|≥|<|>)').allMatches(t).length != 1) {
    throw const FormatException('اكتب متباينة واحدة بعلامة واحدة (<  >  ≤  ≥)');
  }
  final op = m[0]!;
  final l = PolyParser.parse(t.substring(0, m.start));
  final r = PolyParser.parse(t.substring(m.end));
  final diff = l - r; // diff op 0
  final vs = diff.vars.toList();
  final lines = <String>['المتباينة: ${ltr(t.trim())}', 'ننقل كل شيء إلى طرف واحد:', ltr('${polyToString(diff)} $op 0')];
  if (vs.length > 1) throw const FormatException('المتباينات مدعومة بمتغير واحد فقط');
  if (vs.isEmpty) {
    final k = diff.constantTerm.toDouble();
    final ok = switch (op) { '<' => k < 0, '>' => k > 0, '≤' => k <= 0, _ => k >= 0 };
    lines.add(ok ? 'المتباينة صحيحة دائمًا.' : 'المتباينة غير صحيحة أبدًا (لا حل).');
    return lines;
  }
  final v = vs.first;
  var c = [...diff.coeffs(v)!];
  while (c.length > 1 && c.last.isZero) {
    c.removeLast();
  }
  final strict = op == '<' || op == '>';
  bool holds(double val) => switch (op) { '<' => val < 0, '>' => val > 0, '≤' => val <= 0, _ => val >= 0 };
  double ev(double x) {
    var s = 0.0;
    for (var k = c.length - 1; k >= 0; k--) {
      s = s * x + c[k].toDouble();
    }
    return s;
  }

  if (c.length == 2) {
    final a = c[1], b = c[0];
    final bound = -b / a;
    var o2 = op;
    if (a.isNegative) {
      lines.add('نقسم على عدد سالب فتنعكس إشارة المتباينة.');
      o2 = switch (op) { '<' => '>', '>' => '<', '≤' => '≥', _ => '≤' };
    }
    lines.add('الحل: ${ltr('$v $o2 ${_num(bound)}')}');
    final bs = bound.isInt ? '$bound' : _fmtB(bound.toDouble());
    final less = o2 == '<' || o2 == '≤';
    final closeB = strict ? ')' : ']';
    final openB = strict ? '(' : '[';
    final interval = less ? '(-∞, $bs$closeB' : '$openB$bs, ∞)';
    lines.add('بصيغة الفترة: ${ltr(interval)}');
    return lines;
  }
  if (c.length != 3) {
    throw const FormatException('المتباينات مدعومة حتى الدرجة الثانية');
  }
  lines.add('متباينة تربيعية: نجد جذور المعادلة المرافقة ثم ندرس الإشارة.');
  final (steps, roots) = quadraticSteps(c[2], c[1], c[0], v);
  lines.addAll(steps);
  final rs = [...roots]..sort();
  final pts = <double>[];
  for (final r in rs) {
    if (pts.isEmpty || (r - pts.last).abs() > 1e-12) pts.add(r);
  }
  // فترات الاختبار
  final tests = <double>[];
  final bounds = <(double, double)>[];
  if (pts.isEmpty) {
    tests.add(0);
    bounds.add((double.negativeInfinity, double.infinity));
  } else {
    tests.add(pts.first - 1);
    bounds.add((double.negativeInfinity, pts.first));
    for (var k = 0; k + 1 < pts.length; k++) {
      tests.add((pts[k] + pts[k + 1]) / 2);
      bounds.add((pts[k], pts[k + 1]));
    }
    tests.add(pts.last + 1);
    bounds.add((pts.last, double.infinity));
  }
  final parts = <String>[];
  final sets = <String>[];
  for (var k = 0; k < tests.length; k++) {
    if (!holds(ev(tests[k]))) continue;
    final (lo, hi) = bounds[k];
    final loS = lo.isInfinite ? '-∞' : _fmtB(lo);
    final hiS = hi.isInfinite ? '∞' : _fmtB(hi);
    final lb = lo.isInfinite || strict ? '(' : '[';
    final rb = hi.isInfinite || strict ? ')' : ']';
    sets.add('$lb$loS, $hiS$rb');
    if (lo.isInfinite && hi.isInfinite) {
      parts.add('كل الأعداد الحقيقية');
    } else if (lo.isInfinite) {
      parts.add('$v ${strict ? '<' : '≤'} $hiS');
    } else if (hi.isInfinite) {
      parts.add('$v ${strict ? '>' : '≥'} $loS');
    } else {
      parts.add('$loS ${strict ? '<' : '≤'} $v ${strict ? '<' : '≤'} $hiS');
    }
  }
  // نقاط الجذور المنفردة عند ≤ أو ≥ (مثل جذر مضاعف)
  if (!strict) {
    for (final p in pts) {
      final covered = sets.any((s) => s.contains(_fmtB(p)));
      if (!covered && ev(p).abs() < 1e-9) {
        sets.add('{${_fmtB(p)}}');
        parts.add('$v = ${_fmtB(p)}');
      }
    }
  }
  if (sets.isEmpty) {
    lines.add('لا يوجد حل (المتباينة غير محققة لأي قيمة).');
  } else {
    lines.add('الحل: ${ltr(parts.join('  أو  '))}');
    lines.add('بصيغة الفترات: ${ltr(sets.join(' ∪ '))}');
  }
  return lines;
}

// ───────────────────────── نقطة الدخول ─────────────────────────
String solveAny(String input) {
  final raw = input.trim();
  if (raw.isEmpty) throw const FormatException('اكتب المسألة أولًا، مثال: 2x + 5 = 17');
  final t = raw.replaceAll('<=', '≤').replaceAll('>=', '≥').replaceAll('=<', '≤').replaceAll('=>', '≥');
  if (RegExp(r'[<>≤≥]').hasMatch(t)) return _solveIneq(t).join('\n');
  final lines = t.split(RegExp(r'[\n;؛]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (lines.length > 2) throw const FormatException('أدخل معادلة واحدة، أو معادلتين لنظام');
  if (!lines.every((l) => l.contains('='))) {
    if (lines.length == 1) return simplifyText(lines.first);
    throw const FormatException('اكتب معادلات كاملة (تحتوي على =)');
  }
  final eqs = [for (final l in lines) _parseEq(l)];
  final all = <String>{for (final e in eqs) ...e.vars}.toList()..sort();
  if (eqs.length == 1) {
    if (all.length > 1) {
      throw const FormatException('معادلة واحدة بمتغيرين: أضف معادلة ثانية في سطر جديد لحل نظام');
    }
    if (all.isEmpty) {
      final z = eqs[0].diff.constantTerm.isZero;
      return '${eqs[0].text}\n${z ? 'المعادلة صحيحة دائمًا.' : 'المعادلة غير صحيحة (لا حل).'}';
    }
    return _solveUni(eqs[0].text, eqs[0].diff, all.first).join('\n');
  }
  if (all.length == 2) return _solveSystem(eqs, all).join('\n');
  if (all.length > 2) throw const FormatException('النظام مدعوم بمجهولين فقط');
  final out = <String>[];
  for (final e in eqs) {
    if (e.vars.isEmpty) {
      out.add('${e.text}\n${e.diff.constantTerm.isZero ? 'صحيحة دائمًا.' : 'غير صحيحة.'}');
    } else {
      out.add(_solveUni(e.text, e.diff, e.vars.first).join('\n'));
    }
  }
  return out.join('\n\n');
}
