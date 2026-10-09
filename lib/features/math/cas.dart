import 'dart:math';
import '../../core/fmt.dart';
import '../extras/extras_logic.dart' show toWesternDigits;
import 'frac.dart';
import 'poly.dart';

// ───────────────────────── القراءة (Parser) ─────────────────────────
const _unsupportedFn = 'الدوال (sin, log, √...) والجذور داخل المعادلة غير مدعومة بعد، والمدعوم: كثيرات الحدود والكسور والأسس الصحيحة.';

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
bool _isLetter(String c) => c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122;

class PolyParser {
  final String s;
  int i = 0;
  PolyParser(this.s);

  static String normalize(String input) {
    var t = input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('٫', '.');
    t = toWesternDigits(t);
    return t.replaceAll(RegExp(r'\s'), '').toLowerCase();
  }

  static Poly parse(String input) {
    final t = normalize(input);
    if (t.isEmpty) throw const FormatException('تعبير فارغ');
    if (t.length > 300) throw const FormatException('التعبير طويل جدًا');
    if (RegExp(r'sin|cos|tan|log|ln|sqrt|exp|abs|√|π').hasMatch(t)) {
      throw const FormatException(_unsupportedFn);
    }
    final p = PolyParser(t);
    final v = p.expr();
    if (p.i != t.length) throw FormatException('تعبير غير صالح قرب «${t.substring(p.i)}»');
    return v;
  }

  bool get _end => i >= s.length;

  Poly expr() {
    var v = term();
    while (!_end && (s[i] == '+' || s[i] == '-')) {
      final o = s[i++];
      final r = term();
      v = o == '+' ? v + r : v - r;
    }
    return v;
  }

  Poly term() {
    var v = factor();
    while (!_end) {
      final c = s[i];
      if (c == '*') {
        i++;
        v = v * factor();
      } else if (c == '/') {
        i++;
        final d = factor();
        if (!d.isConstant || d.isZero) {
          throw const FormatException('القسمة مدعومة على عدد ثابت فقط (غير الصفر)');
        }
        v = v.scale(Frac.one / d.constantTerm);
      } else if (c == '(' || _isLetter(c)) {
        v = v * factor();
      } else {
        break;
      }
    }
    return v;
  }

  Poly factor() {
    if (!_end && s[i] == '-') {
      i++;
      return -factor();
    }
    if (!_end && s[i] == '+') {
      i++;
      return factor();
    }
    return power();
  }

  Poly power() {
    var b = atom();
    if (!_end && s[i] == '^') {
      i++;
      b = b.pow(_exponent());
    }
    return b;
  }

  int _exponent() {
    const err = 'الأس يجب أن يكون عددًا صحيحًا غير سالب (حتى 64)';
    if (!_end && s[i] == '(') {
      i++;
      final v = expr();
      if (_end || s[i] != ')') throw const FormatException('قوس غير مغلق');
      i++;
      if (!v.isConstant || !v.constantTerm.isInt || v.constantTerm.isNegative) {
        throw const FormatException(err);
      }
      final n = v.constantTerm.n;
      if (n > BigInt.from(64)) throw const FormatException(err);
      return n.toInt();
    }
    final st = i;
    while (!_end && _isDigit(s[i])) {
      i++;
    }
    if (st == i) throw const FormatException(err);
    final n = int.parse(s.substring(st, i));
    if (n > 64) throw const FormatException(err);
    return n;
  }

  Poly atom() {
    if (_end) throw const FormatException('تعبير ناقص');
    final c = s[i];
    if (c == '(') {
      i++;
      final v = expr();
      if (_end || s[i] != ')') throw const FormatException('قوس غير مغلق');
      i++;
      return v;
    }
    if (_isDigit(c) || c == '.') {
      final st = i;
      while (!_end && (_isDigit(s[i]) || s[i] == '.')) {
        i++;
      }
      final f = Frac.tryParse(s.substring(st, i));
      if (f == null) throw const FormatException('رقم غير صالح');
      return Poly.constant(f);
    }
    if (_isLetter(c)) {
      i++;
      return Poly.variable(c);
    }
    throw FormatException('رمز غير مدعوم: $c');
  }
}

// ───────────────────────── الكتابة ─────────────────────────
String _coef(Frac a) => a.isInt ? '$a' : '($a)';

String _mono(Mono m) =>
    m.e.entries.map((e) => e.value == 1 ? e.key : '${e.key}^${e.value}').join();

/// يكتب كثير الحدود مرتبًا من الأعلى درجة: 5x^2 - 3x + 1
String polyToString(Poly p) {
  if (p.isZero) return '0';
  final es = p.t.entries.toList()
    ..sort((a, b) {
      final d = b.key.degree.compareTo(a.key.degree);
      return d != 0 ? d : a.key.key.compareTo(b.key.key);
    });
  final sb = StringBuffer();
  for (var k = 0; k < es.length; k++) {
    final m = es[k].key, c = es[k].value;
    final neg = c.isNegative, a = c.abs();
    if (k == 0) {
      if (neg) sb.write('-');
    } else {
      sb.write(neg ? ' - ' : ' + ');
    }
    final ms = _mono(m);
    if (ms.isEmpty) {
      sb.write('$a');
    } else {
      if (a != Frac.one) sb.write(_coef(a));
      sb.write(ms);
    }
  }
  return sb.toString();
}

/// يفرض اتجاه اليسار لليمين على سطر رياضي داخل نص عربي.
String ltr(String s) => '\u202A$s\u202C';

String _num(Frac f) => f.isInt ? '$f' : '$f (≈ ${fmt(f.toDouble(), 4)})';
String _par(Frac f) => f.isNegative ? '(${f.toString()})' : f.toString();

// ───────────────────────── خوارزميات أحادية المتغير ─────────────────────────
Frac evalAt(List<Frac> c, Frac x) {
  var r = Frac.zero;
  for (var k = c.length - 1; k >= 0; k--) {
    r = r * x + c[k];
  }
  return r;
}

/// قسمة كثير حدود (المعاملات من الأصغر للأكبر) على (x - r).
List<Frac> divideByRoot(List<Frac> c, Frac r) {
  final n = c.length - 1;
  final q = List<Frac>.filled(n, Frac.zero);
  var carry = Frac.zero;
  for (var k = n; k >= 1; k--) {
    carry = c[k] + carry * r;
    q[k - 1] = carry;
  }
  return q;
}

BigInt _lcm(BigInt a, BigInt b) => a * b ~/ a.gcd(b);

/// الأصل = المحتوى × المعاملات الصحيحة الأولية (المعامل الأعلى موجب).
(List<BigInt>, Frac) primitive(List<Frac> c) {
  var l = BigInt.one;
  for (final x in c) {
    l = _lcm(l, x.d);
  }
  final ints = [for (final x in c) x.n * (l ~/ x.d)];
  var g = BigInt.zero;
  for (final x in ints) {
    g = g.gcd(x);
  }
  if (g == BigInt.zero) g = BigInt.one;
  var content = Frac(g, l);
  var out = [for (final x in ints) x ~/ g];
  if (out.last.isNegative) {
    out = [for (final x in out) -x];
    content = -content;
  }
  return (out, content);
}

List<int> _divisors(int n) {
  final r = <int>[];
  for (var k = 1; k * k <= n; k++) {
    if (n % k == 0) {
      r.add(k);
      if (k != n ~/ k) r.add(n ~/ k);
    }
  }
  return r;
}

List<Frac> _rationalCandidates(List<BigInt> c) {
  final a0 = c.first.abs(), an = c.last.abs();
  final lim = BigInt.from(1000000000);
  if (a0 == BigInt.zero || a0 > lim || an > lim) return [];
  final ds0 = _divisors(a0.toInt()), dsn = _divisors(an.toInt());
  if (ds0.length * dsn.length > 20000) return [];
  final seen = <Frac>{};
  final out = <Frac>[];
  for (final p in ds0) {
    for (final q in dsn) {
      for (final sg in const [1, -1]) {
        final f = Frac(BigInt.from(sg * p), BigInt.from(q));
        if (seen.add(f)) out.add(f);
      }
    }
  }
  return out;
}

class Factored {
  final Frac content;
  final int xPow;
  final List<(Frac, int)> roots; // (الجذر، التكرار)
  final List<Frac> rest; // الباقي (درجة ≥ 2) أو فارغ
  const Factored(this.content, this.xPow, this.roots, this.rest);
}

/// تحليل كثير حدود أحادي المتغير بالجذور النسبية. يرجع null للصفر.
Factored? factorUni(List<Frac> c) {
  var cc = [...c];
  while (cc.length > 1 && cc.last.isZero) {
    cc.removeLast();
  }
  if (cc.length == 1 && cc[0].isZero) return null;
  var xPow = 0;
  while (cc.length > 1 && cc.first.isZero) {
    cc = cc.sublist(1);
    xPow++;
  }
  var (ints, content) = primitive(cc);
  var cur = [for (final x in ints) Frac(x)];
  final found = <Frac, int>{};
  var guard = 0;
  while (cur.length > 1 && guard++ < 64) {
    final cands = _rationalCandidates([for (final x in cur) x.n]);
    Frac? root;
    for (final r in cands) {
      if (evalAt(cur, r).isZero) {
        root = r;
        break;
      }
    }
    if (root == null) break;
    final q = divideByRoot(cur, root);
    final (qi, qc) = primitive(q);
    cur = [for (final x in qi) Frac(x)];
    content = content * (qc / Frac(root.d));
    found[root] = (found[root] ?? 0) + 1;
  }
  if (cur.length == 1) {
    content = content * cur[0];
    cur = [];
  }
  final roots = [for (final e in found.entries) (e.key, e.value)]
    ..sort((a, b) => a.$1.compareTo(b.$1));
  return Factored(content, xPow, roots, cur);
}

String _linearFactor(Frac root, String v) {
  final p = Poly.fromCoeffs([Frac(-root.n), Frac(root.d)], v);
  return '(${polyToString(p)})';
}

String factoredToString(Factored f, String v) {
  final sb = StringBuffer();
  if (f.content == Frac.one) {
    // لا شيء
  } else if (f.content == -Frac.one) {
    sb.write('-');
  } else {
    sb.write(f.content.isInt ? '${f.content}' : '(${f.content})');
  }
  if (f.xPow == 1) sb.write(v);
  if (f.xPow > 1) sb.write('$v^${f.xPow}');
  for (final (r, m) in f.roots) {
    sb.write(_linearFactor(r, v));
    if (m > 1) sb.write('^$m');
  }
  if (f.rest.isNotEmpty) sb.write('(${polyToString(Poly.fromCoeffs(f.rest, v))})');
  final s = sb.toString();
  return s.isEmpty ? '1' : (s == '-' ? '-1' : s);
}

BigInt isqrt(BigInt n) {
  if (n < BigInt.two) return n;
  var x = BigInt.one << ((n.bitLength + 1) ~/ 2);
  while (true) {
    final y = (x + n ~/ x) >> 1;
    if (y >= x) return x;
    x = y;
  }
}

/// جذور حقيقية تقريبية لكثير حدود (للدرجات الأعلى التي لا تنحل).
List<double> realRootsNumeric(List<Frac> c) {
  final d = [for (final x in c) x.toDouble()];
  double f(double x) {
    var r = 0.0;
    for (var k = d.length - 1; k >= 0; k--) {
      r = r * x + d[k];
    }
    return r;
  }

  final lead = d.last.abs();
  var bound = 1.0;
  for (var k = 0; k < d.length - 1; k++) {
    bound = max(bound, 1 + d[k].abs() / lead);
  }
  const steps = 40000;
  final out = <double>[];
  var px = -bound, pf = f(px);
  for (var k = 1; k <= steps; k++) {
    final x = -bound + 2 * bound * k / steps;
    final fx = f(x);
    if (pf == 0) {
      out.add(px);
    } else if (pf.sign != fx.sign && fx != 0) {
      var lo = px, hi = x;
      for (var it = 0; it < 100; it++) {
        final mid = (lo + hi) / 2;
        if (f(lo).sign == f(mid).sign) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      out.add((lo + hi) / 2);
    }
    px = x;
    pf = fx;
  }
  final res = <double>[];
  for (final r in out) {
    if (res.isEmpty || (r - res.last).abs() > 1e-7) res.add(r);
  }
  return res;
}

// ───────────────────────── المعادلة التربيعية ─────────────────────────
/// يرجع أسطر الشرح وجذورها (تقريبية) بالتسلسل.
(List<String>, List<double>) quadraticSteps(Frac a0, Frac b0, Frac c0, String v) {
  final lines = <String>[];
  final (ints, _) = primitive([c0, b0, a0]);
  final a = Frac(ints[2]), b = Frac(ints[1]), c = Frac(ints[0]);
  if (a != a0 || b != b0 || c != c0) {
    lines.add('نبسّط المعاملات (نضرب المعادلة في عدد مناسب) لتصبح صحيحة:');
  }
  final eq = Poly.fromCoeffs([c, b, a], v);
  lines.add(ltr('${polyToString(eq)} = 0'));
  lines.add(ltr('a = $a ، b = $b ، c = $c'));
  final dD = b * b - Frac.fromInt(4) * a * c;
  lines.add(ltr('Δ = b^2 - 4ac = ${_par(b)}^2 - 4(${a})(${_par(c)}) = $dD'));
  final twoA = Frac.fromInt(2) * a;
  final dd = dD.toDouble();
  if (dD.isNegative) {
    lines.add('Δ أقل من الصفر: لا يوجد حل في الأعداد الحقيقية.');
    final re = (-b / twoA).toDouble(), im = sqrt(-dd) / (2 * a.toDouble());
    lines.add('الجذران مركبان: ${ltr('$v = ${fmt(re, 4)} ± ${fmt(im.abs(), 4)}i')}');
    return (lines, <double>[]);
  }
  if (dD.isZero) {
    final r = -b / twoA;
    lines.add('Δ = 0: جذر مكرر واحد:');
    lines.add(ltr('$v = -b / 2a = ${_num(r)}'));
    return (lines, [r.toDouble()]);
  }
  // مربع كامل نسبي؟
  final sn = isqrt(dD.n), sd = isqrt(dD.d);
  if (sn * sn == dD.n && sd * sd == dD.d) {
    final s = Frac(sn, sd);
    final r1 = (-b - s) / twoA, r2 = (-b + s) / twoA;
    lines.add('Δ أكبر من الصفر ومربع كامل: جذران نسبيان:');
    lines.add(ltr('$v = (-b ± √Δ) / 2a = (${-b} ± $s) / $twoA'));
    final lo = r1 < r2 ? r1 : r2, hi = r1 < r2 ? r2 : r1;
    lines.add(ltr('$v = ${_num(lo)}'));
    lines.add(ltr('$v = ${_num(hi)}'));
    return (lines, [lo.toDouble(), hi.toDouble()]);
  }
  final x1 = (-b.toDouble() - sqrt(dd)) / twoA.toDouble();
  final x2 = (-b.toDouble() + sqrt(dd)) / twoA.toDouble();
  lines.add('Δ أكبر من الصفر وليس مربعًا كاملًا: جذران حقيقيان:');
  if (dD.isInt && b.isInt && a.isInt) {
    // الصيغة الجذرية المبسطة
    final m = dD.n;
    if (m <= BigInt.from(1000000000000)) {
      var k = 1, r = m.toInt();
      for (var p = 2; p * p <= r; p++) {
        while (r % (p * p) == 0) {
          r ~/= p * p;
          k *= p;
        }
      }
      final bi = (-b.n).toInt(), ai2 = (twoA.n).toInt();
      var g = BigInt.from(bi.abs()).gcd(BigInt.from(k)).gcd(BigInt.from(ai2.abs())).toInt();
      if (g == 0) g = 1;
      var bn = bi ~/ g, kn = k ~/ g, dn = ai2 ~/ g;
      if (dn < 0) {
        bn = -bn;
        dn = -dn;
      }
      final rad = '${kn == 1 ? '' : kn}√$r';
      final num0 = bn == 0 ? '± $rad' : '$bn ± $rad';
      lines.add(ltr(dn == 1 ? '$v = $num0' : '$v = ($num0) / $dn'));
    }
  }
  final lo = min(x1, x2), hi = max(x1, x2);
  lines.add(ltr('$v ≈ ${fmt(lo, 4)}'));
  lines.add(ltr('$v ≈ ${fmt(hi, 4)}'));
  return (lines, [lo, hi]);
}
