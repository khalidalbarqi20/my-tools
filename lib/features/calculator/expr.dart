/// يحسب تعبيرًا حسابيًا. يرجع null إذا كان التعبير غير صحيح.
/// يدعم: + - × ÷ ( ) % والأرقام العربية. مثال: 100-20% = 80
double? evalExpr(String input) {
  var s = input
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('٪', '%')
      .replaceAll(' ', '');
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(ar[i], '$i');
  }
  s = s.replaceAll('٫', '.');
  final p = _Parser(s);
  try {
    final v = p.expr();
    if (p.i != s.length || v.isNaN || v.isInfinite) return null;
    return v;
  } catch (_) {
    return null;
  }
}

class _Parser {
  final String s;
  int i = 0;
  _Parser(this.s);

  bool _at(String c) => i < s.length && s[i] == c;

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
    while (_at('*') || _at('/')) {
      final o = s[i++];
      final r = unary();
      if (o == '/' && r == 0) throw const FormatException('div0');
      v = o == '*' ? v * r : v / r;
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
    while (_at('%')) {
      i++;
      v /= 100;
    }
    return v;
  }

  double atom() {
    if (_at('(')) {
      i++;
      final v = expr();
      if (!_at(')')) throw const FormatException('paren');
      i++;
      return v;
    }
    final st = i;
    while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
      i++;
    }
    if (st == i) throw const FormatException('num');
    return double.parse(s.substring(st, i));
  }
}
