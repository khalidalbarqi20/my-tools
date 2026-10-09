import 'dart:math';
import 'frac.dart';

/// وحيد حد (متغيرات وأسس). المفتاح نص قياسي مثل x2y1.
class Mono {
  final Map<String, int> e;
  final String key;
  Mono._(this.e, this.key);

  factory Mono(Map<String, int> m) {
    final ks = [
      for (final k in m.keys)
        if ((m[k] ?? 0) > 0) k
    ]..sort();
    final clean = {for (final k in ks) k: m[k]!};
    return Mono._(clean, ks.map((k) => '$k${clean[k]}').join());
  }

  static final one = Mono(const <String, int>{});

  int get degree => e.values.fold(0, (a, b) => a + b);

  Mono mul(Mono o) {
    final r = Map<String, int>.from(e);
    o.e.forEach((k, v) => r[k] = (r[k] ?? 0) + v);
    return Mono(r);
  }

  @override
  bool operator ==(Object other) => other is Mono && key == other.key;
  @override
  int get hashCode => key.hashCode;
}

/// كثير حدود بمعاملات كسرية دقيقة وعدة متغيرات.
class Poly {
  final Map<Mono, Frac> t;
  Poly._(this.t);

  factory Poly(Map<Mono, Frac> m) =>
      Poly._({for (final e in m.entries) if (!e.value.isZero) e.key: e.value});

  static Poly constant(Frac c) => Poly({Mono.one: c});
  static Poly variable(String v) => Poly({
        Mono(<String, int>{v: 1}): Frac.one,
      });

  Poly operator +(Poly o) {
    final r = Map<Mono, Frac>.from(t);
    o.t.forEach((m, c) => r[m] = (r[m] ?? Frac.zero) + c);
    return Poly(r);
  }

  Poly operator -() => Poly._({for (final e in t.entries) e.key: -e.value});
  Poly operator -(Poly o) => this + (-o);

  Poly operator *(Poly o) {
    if (t.length * o.t.length > 20000) {
      throw const FormatException('التعبير كبير جدًا');
    }
    final r = <Mono, Frac>{};
    for (final a in t.entries) {
      for (final b in o.t.entries) {
        final m = a.key.mul(b.key);
        r[m] = (r[m] ?? Frac.zero) + a.value * b.value;
      }
    }
    return Poly(r);
  }

  Poly scale(Frac c) => Poly({for (final e in t.entries) e.key: e.value * c});

  Poly pow(int k) {
    var r = Poly.constant(Frac.one);
    for (var i = 0; i < k; i++) {
      r = r * this;
    }
    return r;
  }

  bool get isZero => t.isEmpty;
  bool get isConstant => t.keys.every((m) => m.e.isEmpty);
  Frac get constantTerm => t[Mono.one] ?? Frac.zero;
  Set<String> get vars => {for (final m in t.keys) ...m.e.keys};
  int get degree => t.isEmpty ? 0 : t.keys.map((m) => m.degree).reduce(max);
  int degreeIn(String v) => t.isEmpty ? 0 : t.keys.map((m) => m.e[v] ?? 0).reduce(max);

  /// معاملات متغير واحد من الأصغر إلى الأكبر، أو null إن وُجد متغير آخر.
  List<Frac>? coeffs(String v) {
    if (t.isEmpty) return [Frac.zero];
    if (vars.any((x) => x != v)) return null;
    final r = List<Frac>.filled(degreeIn(v) + 1, Frac.zero);
    t.forEach((m, c) => r[m.e[v] ?? 0] = c);
    return r;
  }

  static Poly fromCoeffs(List<Frac> c, String v) {
    final r = <Mono, Frac>{};
    for (var i = 0; i < c.length; i++) {
      r[Mono(i == 0 ? <String, int>{} : <String, int>{v: i})] = c[i];
    }
    return Poly(r);
  }
}
