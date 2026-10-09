/// كسر دقيق (بسط ومقام BigInt) لحساب رمزي بدون أخطاء التقريب.
class Frac implements Comparable<Frac> {
  final BigInt n, d; // d > 0 والكسر مختصر
  Frac._(this.n, this.d);

  factory Frac(BigInt n, [BigInt? d]) {
    var dd = d ?? BigInt.one;
    if (dd == BigInt.zero) throw const FormatException('القسمة على صفر');
    var nn = n;
    if (dd.isNegative) {
      nn = -nn;
      dd = -dd;
    }
    final g = nn.gcd(dd);
    if (g > BigInt.one) {
      nn = nn ~/ g;
      dd = dd ~/ g;
    }
    return Frac._(nn, dd);
  }

  factory Frac.fromInt(int v) => Frac(BigInt.from(v));

  static final zero = Frac._(BigInt.zero, BigInt.one);
  static final one = Frac._(BigInt.one, BigInt.one);

  /// يقبل أعدادًا عشرية موجبة مثل 2.5 ويحوّلها إلى كسر دقيق.
  static Frac? tryParse(String s) {
    final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(s);
    if (m == null) return null;
    final f = m[2] ?? '';
    return Frac(BigInt.parse('${m[1]}$f'), BigInt.from(10).pow(f.length));
  }

  Frac operator +(Frac o) => Frac(n * o.d + o.n * d, d * o.d);
  Frac operator -(Frac o) => Frac(n * o.d - o.n * d, d * o.d);
  Frac operator *(Frac o) => Frac(n * o.n, d * o.d);
  Frac operator /(Frac o) => Frac(n * o.d, d * o.n);
  Frac operator -() => Frac._(-n, d);

  bool get isZero => n == BigInt.zero;
  bool get isInt => d == BigInt.one;
  bool get isNegative => n.isNegative;
  int get sign => n.sign;
  Frac abs() => n.isNegative ? -this : this;
  double toDouble() => n.toDouble() / d.toDouble();

  Frac pow(int e) {
    var r = Frac.one;
    for (var i = 0; i < e; i++) {
      r = r * this;
    }
    return r;
  }

  @override
  bool operator ==(Object other) => other is Frac && n == other.n && d == other.d;
  @override
  int get hashCode => Object.hash(n, d);
  @override
  int compareTo(Frac o) => (n * o.d).compareTo(o.n * d);
  bool operator <(Frac o) => compareTo(o) < 0;
  bool operator >(Frac o) => compareTo(o) > 0;
  bool operator <=(Frac o) => compareTo(o) <= 0;
  bool operator >=(Frac o) => compareTo(o) >= 0;

  @override
  String toString() => d == BigInt.one ? '$n' : '$n/$d';
}
