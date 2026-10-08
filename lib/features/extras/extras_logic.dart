import '../../core/fmt.dart';
import '../../core/num_parse.dart';

// ───────────── الأرقام العربية والغربية ─────────────
String toWesternDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(r - 0x0660 + 48);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(r - 0x06F0 + 48);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

String toArabicIndicDigits(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    b.writeCharCode(r >= 48 && r <= 57 ? r - 48 + 0x0660 : r);
  }
  return b.toString();
}

// ───────────── التشكيل ─────────────
String stripArabicMarks(String s, {bool tatweel = true}) {
  var t = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
  if (tatweel) t = t.replaceAll('\u0640', '');
  return t;
}

// ───────────── تحويل الأنظمة العددية ─────────────
Map<int, String>? convertBase(String input, int from) {
  if (from < 2 || from > 36) return null;
  var t = toWesternDigits(input).replaceAll(RegExp(r'[\s_,]'), '');
  if (t.isEmpty) return null;
  var neg = false;
  if (t.startsWith('-')) {
    neg = true;
    t = t.substring(1);
  } else if (t.startsWith('+')) {
    t = t.substring(1);
  }
  if (t.startsWith('-') || t.startsWith('+')) return null;
  final l = t.toLowerCase();
  if (from == 16 && l.startsWith('0x')) {
    t = t.substring(2);
  } else if (from == 2 && l.startsWith('0b')) {
    t = t.substring(2);
  } else if (from == 8 && l.startsWith('0o')) {
    t = t.substring(2);
  }
  if (t.isEmpty || t.length > 200) return null;
  final n = BigInt.tryParse(t, radix: from);
  if (n == null) return null;
  final v = neg ? -n : n;
  return {for (final r in const [2, 8, 10, 16]) r: v.toRadixString(r).toUpperCase()};
}

// ───────────── الأرقام الرومانية ─────────────
const _romans = <(int, String)>[
  (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'), (100, 'C'), (90, 'XC'),
  (50, 'L'), (40, 'XL'), (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
];

String? toRoman(int n) {
  if (n < 1 || n > 3999) return null;
  var x = n;
  final b = StringBuffer();
  for (final (v, s) in _romans) {
    while (x >= v) {
      b.write(s);
      x -= v;
    }
  }
  return b.toString();
}

int? fromRoman(String s) {
  final t = s.trim().toUpperCase();
  if (t.isEmpty || !RegExp(r'^[IVXLCDM]+$').hasMatch(t)) return null;
  const val = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000};
  var total = 0;
  for (var i = 0; i < t.length; i++) {
    final v = val[t[i]]!;
    final next = i + 1 < t.length ? val[t[i + 1]]! : 0;
    total += v < next ? -v : v;
  }
  // نقبل الصيغة القياسية فقط (مثل IV وليس IIII).
  return toRoman(total) == t ? total : null;
}

/// يقبل رقمًا (1–3999) أو رقمًا رومانيًا ويحوّله للآخر.
String romanConvert(String input) {
  final t = toWesternDigits(input).trim();
  const err = 'أدخل رقمًا من 1 إلى 3999 أو رقمًا رومانيًا صحيحًا (مثل XIV)';
  if (RegExp(r'^\d+$').hasMatch(t)) {
    final n = int.tryParse(t);
    final r = n == null ? null : toRoman(n);
    if (r == null) throw const FormatException(err);
    return r;
  }
  final v = fromRoman(t);
  if (v == null) throw const FormatException(err);
  return '$v';
}

// ───────────── تكلفة الوقود ─────────────
class FuelResult {
  final double liters, cost;
  const FuelResult(this.liters, this.cost);
}

FuelResult? fuelCost(double distanceKm, double lPer100, double pricePerLiter) {
  if (!(distanceKm >= 0) || !(lPer100 > 0) || !(pricePerLiter >= 0)) return null;
  final liters = distanceKm * lPer100 / 100;
  final cost = liters * pricePerLiter;
  if (!liters.isFinite || !cost.isFinite) return null;
  return FuelResult(liters, cost);
}

Rows? fuelRows(List<String> v) {
  final d = parseNum(v[0]), c = parseNum(v[1]), p = parseNum(v[2]);
  if (d == null || c == null || p == null) return null;
  final r = fuelCost(d, c, p);
  if (r == null) return null;
  return [
    ('كمية الوقود', '${fmt(r.liters)} لتر'),
    ('تكلفة الرحلة', fmt(r.cost)),
    if (d > 0) ('تكلفة الكيلومتر الواحد', fmt(r.cost / d, 3)),
  ];
}

// ───────────── الزكاة (مال) ─────────────
class ZakatResult {
  final double nisab, amount;
  final bool due;
  const ZakatResult(this.nisab, this.due, this.amount);
}

/// نصاب الذهب 85 جرامًا، والزكاة 2.5% إذا بلغ المال النصاب ومرّ عليه حول كامل.
ZakatResult? zakat(double wealth, double goldGramPrice, {double nisabGrams = 85}) {
  if (!(wealth >= 0) || !(goldGramPrice > 0)) return null;
  final nisab = nisabGrams * goldGramPrice;
  final due = wealth >= nisab;
  final amount = due ? wealth * 0.025 : 0.0;
  if (!nisab.isFinite || !amount.isFinite) return null;
  return ZakatResult(nisab, due, amount);
}

Rows? zakatRows(List<String> v) {
  final w = parseNum(v[0]), g = parseNum(v[1]);
  if (w == null || g == null) return null;
  final r = zakat(w, g);
  if (r == null) return null;
  return [
    ('النصاب (85 جرام ذهب)', fmt(r.nisab)),
    ('بلغ المال النصاب؟', r.due ? 'نعم' : 'لا'),
    ('مقدار الزكاة (2.5%)', fmt(r.amount)),
  ];
}
