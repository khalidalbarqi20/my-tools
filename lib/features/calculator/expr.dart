import 'dart:math' as m;

/// يحسب تعبيرًا حسابيًا. يرجع null إذا كان التعبير غير صحيح.
/// يدعم: + - × ÷ ( ) % والأرقام العربية. مثال: 100-20% = 80
/// وللحاسبة العلمية: ^ ! √ π e ودوال sin cos tan asin acos atan sinh cosh tanh
/// log (أساس 10) ln log2 sqrt cbrt abs exp floor ceil round، ومتغيرات (مثل x للرسم).
double? evalExpr(String input) => evalExprWith(input);

double? evalExprWith(String input,
    {Map<String, double> vars = const {}, bool degrees = false}) {
  var s = input
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('٪', '%')
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll(' ', '');
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(ar[i], '$i');
  }
  s = s.replaceAll('٫', '.').toLowerCase();
  if (s.length > 400) return null;
  final p = _Parser(s, vars, degrees);
  try {
    final v = p.expr();
    if (p.i != s.length || v.isNaN || v.isInfinite) return null;
    return v;
  } catch (_) {
    return null;
  }
}

const _funcs = [
  'asin', 'acos', 'atan', 'sinh', 'cosh', 'tanh', 'sqrt', 'cbrt', 'log2',
  'floor', 'ceil', 'round', 'sin', 'cos', 'tan', 'log', 'ln', 'exp', 'abs',
];

class _Parser {
  final String s;
  final Map<String, double> vars;
  final bool degrees;
  int i = 0;
  _Parser(this.s, this.vars, this.degrees);

  bool _at(String c) => i < s.length && s[i] == c;

  bool get _implicitAhead {
    if (i >= s.length) return false;
    final c = s[i];
    return c == '(' || c == 'π' || c == '√' || (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122);
  }

  double expr() {
    var v = term();
    while (_at('+') || _at('-')) {
      final o = s[i++];
      final r0 = term();
      final r = s[i - 1] == '%' ? v * r0 : r0;
      v = o == '+' ? v + r : v - r;
    }
    return v;
  }

  double term() {
    var v = unary();
    while (true) {
      if (_at('*') || _at('/')) {
        final o = s[i++];
        final r = unary();
        if (o == '/' && r == 0) throw const FormatException('div0');
        v = o == '*' ? v * r : v / r;
      } else if (_implicitAhead) {
        v *= unary(); // ضرب ضمني: 2π ، 3(4+5) ، 2sin(30)
      } else {
        break;
      }
    }
    return v;
  }

  double unary() {
    if (_at('-')) {
      i++;
      return -unary();
    }
    if (_at('+')) {
      i++;
      return unary();
    }
    return post();
  }

  double post() {
    var v = atom();
    while (_at('%') || _at('!')) {
      if (s[i++] == '%') {
        v /= 100;
      } else {
        v = _fact(v);
      }
    }
    if (_at('^')) {
      i++;
      v = m.pow(v, unary()).toDouble(); // أُسّ يمين-تجميعي: 2^3^2 = 2^9
    }
    return v;
  }

  double _fact(double v) {
    if (v < 0 || v != v.truncateToDouble() || v > 170) {
      throw const FormatException('fact');
    }
    var r = 1.0;
    for (var k = 2; k <= v.toInt(); k++) {
      r *= k;
    }
    return r;
  }

  double atom() {
    if (_at('(')) {
      i++;
      final v = expr();
      if (!_at(')')) throw const FormatException('paren');
      i++;
      return v;
    }
    if (_at('π')) {
      i++;
      return m.pi;
    }
    if (_at('√')) {
      i++;
      return m.sqrt(atom());
    }
    final st = i;
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
      i++;
    }
    if (st != i) return double.parse(s.substring(st, i));
    return _ident();
  }

  double _ident() {
    for (final f in _funcs) {
      if (s.startsWith(f, i)) {
        final j = i + f.length;
        if (j < s.length && s[j] == '(') {
          i = j + 1;
          final a = expr();
          if (!_at(')')) throw const FormatException('paren');
          i++;
          return _call(f, a);
        }
      }
    }
    if (s.startsWith('pi', i)) {
      i += 2;
      return m.pi;
    }
    for (final k in vars.keys) {
      if (k.isNotEmpty && s.startsWith(k, i)) {
        i += k.length;
        return vars[k]!;
      }
    }
    if (_at('e')) {
      i++;
      return m.e;
    }
    throw const FormatException('id');
  }

  double _call(String f, double a) {
    double rad(double x) => degrees ? x * m.pi / 180 : x;
    double deg(double x) => degrees ? x * 180 / m.pi : x;
    switch (f) {
      case 'sin':
        return m.sin(rad(a));
      case 'cos':
        return m.cos(rad(a));
      case 'tan':
        final r = rad(a);
        if (m.cos(r).abs() < 1e-12) throw const FormatException('tan');
        return m.tan(r);
      case 'asin':
        return deg(m.asin(a));
      case 'acos':
        return deg(m.acos(a));
      case 'atan':
        return deg(m.atan(a));
      case 'sinh':
        return (m.exp(a) - m.exp(-a)) / 2;
      case 'cosh':
        return (m.exp(a) + m.exp(-a)) / 2;
      case 'tanh':
        if (a.abs() > 20) return a.sign;
        return (m.exp(a) - m.exp(-a)) / (m.exp(a) + m.exp(-a));
      case 'log':
        return m.log(a) / m.ln10;
      case 'ln':
        return m.log(a);
      case 'log2':
        return m.log(a) / m.ln2;
      case 'sqrt':
        return m.sqrt(a);
      case 'cbrt':
        return a < 0 ? -m.pow(-a, 1 / 3).toDouble() : m.pow(a, 1 / 3).toDouble();
      case 'abs':
        return a.abs();
      case 'exp':
        return m.exp(a);
      case 'floor':
        return a.floorToDouble();
      case 'ceil':
        return a.ceilToDouble();
      case 'round':
        return a.roundToDouble();
    }
    throw const FormatException('fn');
  }
}
