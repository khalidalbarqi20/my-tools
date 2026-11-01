/// منطق أدوات المطوّر والأمان (دوال نقية قابلة للاختبار).
library;

import 'dart:convert';
import 'dart:math' as math;

// ───────────── قوة كلمة المرور ─────────────
class PwReport {
  final int bits;

  /// 0 ضعيفة جدًا … 4 قوية جدًا
  final int level;
  final List<String> tips;
  const PwReport(this.bits, this.level, this.tips);
}

const _common = {
  'password', '123456', '12345678', '123456789', '1234567890', 'qwerty', 'qwerty123',
  '111111', '000000', 'abc123', 'admin', 'letmein', 'iloveyou', 'welcome', 'monkey',
  '1q2w3e4r', 'password1', 'passw0rd', '123123', '654321', 'dragon', 'login',
  'محمد', 'احمد', 'السعودية', 'مرحبا',
};

bool _hasSequence(String p) {
  final s = p.toLowerCase();
  var run = 1;
  for (var i = 1; i < s.length; i++) {
    final d = s.codeUnitAt(i) - s.codeUnitAt(i - 1);
    if (d == 1 || d == -1) {
      run++;
      if (run >= 4) return true;
    } else {
      run = 1;
    }
  }
  return false;
}

PwReport passwordReport(String p) {
  if (p.isEmpty) return const PwReport(0, 0, []);
  var pool = 0;
  if (RegExp(r'[a-z]').hasMatch(p)) pool += 26;
  if (RegExp(r'[A-Z]').hasMatch(p)) pool += 26;
  if (RegExp(r'[0-9]').hasMatch(p)) pool += 10;
  if (RegExp(r'[!-/:-@\[-`{-~]').hasMatch(p)) pool += 33;
  if (RegExp(r'[^\x00-\x7F]').hasMatch(p)) pool += 50;
  if (pool == 0) pool = 10;
  var bits = (p.runes.length * (math.log(pool) / math.ln2)).floor();
  final tips = <String>[];
  final distinct = p.runes.toSet().length;
  if (distinct <= p.runes.length ~/ 2) {
    bits = (bits * 0.6).floor();
    tips.add('فيها تكرار كثير للأحرف');
  }
  if (_hasSequence(p)) {
    bits = (bits * 0.7).floor();
    tips.add('فيها تسلسل سهل مثل 1234 أو abcd');
  }
  if (_common.contains(p.toLowerCase())) {
    bits = math.min(bits, 10);
    tips.add('كلمة مرور شائعة جدًا وتُخمَّن فورًا');
  }
  if (p.runes.length < 12) tips.add('اجعلها 12 حرفًا فأكثر');
  if (!RegExp(r'[0-9]').hasMatch(p)) tips.add('أضف أرقامًا');
  if (!RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) {
    tips.add('أضف أحرفًا كبيرة');
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) tips.add('أضف رموزًا مثل ! أو #');
  final level = bits < 28 ? 0 : bits < 36 ? 1 : bits < 60 ? 2 : bits < 80 ? 3 : 4;
  return PwReport(bits, level, tips);
}

const pwLevelAr = ['ضعيفة جدًا', 'ضعيفة', 'متوسطة', 'قوية', 'قوية جدًا'];

/// يبحث عن لاحقة SHA-1 داخل رد HIBP (أسطر SUFFIX:COUNT). يرجع العدد أو 0.
int hibpCount(String body, String suffixUpper) {
  for (final line in const LineSplitter().convert(body)) {
    final i = line.indexOf(':');
    if (i <= 0) continue;
    if (line.substring(0, i).trim().toUpperCase() == suffixUpper) {
      return int.tryParse(line.substring(i + 1).trim()) ?? 0;
    }
  }
  return 0;
}

// ───────────── JWT ─────────────
class JwtParts {
  final Map<String, dynamic> header, payload;
  final DateTime? exp, iat;
  const JwtParts(this.header, this.payload, this.exp, this.iat);
}

List<int> b64urlDecode(String s) {
  var t = s.replaceAll('-', '+').replaceAll('_', '/');
  while (t.length % 4 != 0) {
    t += '=';
  }
  return base64.decode(t);
}

JwtParts decodeJwt(String token) {
  final parts = token.trim().split('.');
  if (parts.length != 3) throw const FormatException('الرمز لازم يكون 3 أجزاء مفصولة بنقطة');
  Map<String, dynamic> j(String s) {
    final v = jsonDecode(utf8.decode(b64urlDecode(s)));
    if (v is! Map<String, dynamic>) throw const FormatException('جزء غير صالح');
    return v;
  }

  try {
    final h = j(parts[0]), p = j(parts[1]);
    DateTime? t(String k) {
      final v = p[k];
      return v is num
          ? DateTime.fromMillisecondsSinceEpoch(v.toInt() * 1000, isUtc: true)
          : null;
    }

    return JwtParts(h, p, t('exp'), t('iat'));
  } on FormatException {
    throw const FormatException('تعذر قراءة الرمز، تأكد أنه JWT صحيح');
  }
}

// ───────────── الطابع الزمني ─────────────
/// أرقام بطول 13 فأكثر تُعدّ ملي ثانية، غير ذلك ثواني.
DateTime? parseTimestamp(String s) {
  final t = s.trim();
  if (!RegExp(r'^-?\d{1,16}$').hasMatch(t)) return null;
  final n = int.parse(t);
  final ms = t.replaceFirst('-', '').length >= 13 ? n : n * 1000;
  if (ms.abs() > 8640000000000000) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

String _two(int n) => n < 10 ? '0$n' : '$n';
String fmtDate(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

// ───────────── مقارنة نصين ─────────────
enum DiffOp { same, add, del }

class DiffLine {
  final DiffOp op;
  final String text;
  const DiffLine(this.op, this.text);
}

/// فرق الأسطر بخوارزمية أطول سلسلة مشتركة (LCS).
List<DiffLine> diffLines(List<String> a, List<String> b) {
  if (a.length > 1500 || b.length > 1500) {
    throw const FormatException('النص طويل جدًا (الحد 1500 سطر لكل جهة)');
  }
  final n = a.length, m = b.length;
  final t = List<List<int>>.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      t[i][j] = a[i] == b[j] ? t[i + 1][j + 1] + 1 : math.max(t[i + 1][j], t[i][j + 1]);
    }
  }
  final out = <DiffLine>[];
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      out.add(DiffLine(DiffOp.same, a[i]));
      i++;
      j++;
    } else if (t[i + 1][j] >= t[i][j + 1]) {
      out.add(DiffLine(DiffOp.del, a[i++]));
    } else {
      out.add(DiffLine(DiffOp.add, b[j++]));
    }
  }
  while (i < n) {
    out.add(DiffLine(DiffOp.del, a[i++]));
  }
  while (j < m) {
    out.add(DiffLine(DiffOp.add, b[j++]));
  }
  return out;
}
