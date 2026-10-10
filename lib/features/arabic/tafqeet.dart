import '../extras/extras_logic.dart' show toWesternDigits;

const _onesM = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة', 'عشرة'];
const _teensM = [
  '', '', '', '', '', '', '', '', '', '', '', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر',
  'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
];
const _onesF = ['', 'واحدة', 'اثنتان', 'ثلاث', 'أربع', 'خمس', 'ست', 'سبع', 'ثماني', 'تسع', 'عشر'];
const _teensF = [
  '', '', '', '', '', '', '', '', '', '', '', 'إحدى عشرة', 'اثنتا عشرة', 'ثلاث عشرة',
  'أربع عشرة', 'خمس عشرة', 'ست عشرة', 'سبع عشرة', 'ثماني عشرة', 'تسع عشرة',
];
const _tens = ['', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
const _hund = [
  '', 'مئة', 'مئتان', 'ثلاثمئة', 'أربعمئة', 'خمسمئة', 'ستمئة', 'سبعمئة', 'ثمانمئة', 'تسعمئة',
];
// (مفرد، مثنى، جمع، تمييز منصوب)
const _scales = [
  ('ألف', 'ألفان', 'آلاف', 'ألفًا'),
  ('مليون', 'مليونان', 'ملايين', 'مليونًا'),
  ('مليار', 'ملياران', 'مليارات', 'مليارًا'),
  ('تريليون', 'تريليونان', 'تريليونات', 'تريليونًا'),
];

/// عدد من 1 إلى 999.
String _group(int n, {bool fem = false}) {
  final parts = <String>[];
  final h = n ~/ 100, r = n % 100;
  if (h > 0) parts.add(_hund[h]);
  if (r > 0) {
    if (r <= 10) {
      parts.add((fem ? _onesF : _onesM)[r]);
    } else if (r < 20) {
      parts.add((fem ? _teensF : _teensM)[r]);
    } else {
      final u = r % 10, t = r ~/ 10;
      if (u == 0) {
        parts.add(_tens[t]);
      } else {
        final ones = (u == 1 && fem) ? 'إحدى' : (u == 2 && fem ? 'اثنتان' : (fem ? _onesF : _onesM)[u]);
        parts.add('$ones و${_tens[t]}');
      }
    }
  }
  return parts.join(' و');
}

String _scalePhrase(int c, int idx) {
  final s = _scales[idx];
  if (c == 1) return s.$1;
  if (c == 2) return s.$2;
  final r = c % 100;
  if (c >= 100 && (r == 1 || r == 2)) {
    return '${_group(c - r)} و${r == 1 ? s.$1 : s.$2}';
  }
  var g = _group(c);
  if (r >= 3 && r <= 10) return '$g ${s.$3}';
  if (r == 0) {
    if (g.endsWith('مئتان')) g = g.substring(0, g.length - 1); // مئتا ألف
    return '$g ${s.$1}';
  }
  return '$g ${s.$4}';
}

/// العدد بالكلمات (حتى أقل من 10^15). fem: للتمييز المؤنث في آخر مجموعة.
String wordsOf(int n, {bool fem = false}) {
  if (n < 0 || n >= 1000000000000000) {
    throw const FormatException('الرقم كبير جدًا (الحد الأقصى أقل من 10^15)');
  }
  if (n == 0) return 'صفر';
  final gs = <int>[];
  var x = n;
  while (x > 0) {
    gs.add(x % 1000);
    x ~/= 1000;
  }
  final parts = <String>[];
  for (var i = gs.length - 1; i >= 1; i--) {
    if (gs[i] != 0) parts.add(_scalePhrase(gs[i], i - 1));
  }
  if (gs[0] != 0) parts.add(_group(gs[0], fem: fem));
  return parts.join(' و');
}

/// رقم → كلمات. يدعم الأرقام العربية والكسور العشرية (تُقرأ أرقامًا) والسالب.
String numberToWords(String input) {
  final t = toWesternDigits(input).replaceAll(RegExp(r'[\s,،٬]'), '').replaceAll('٫', '.');
  final m = RegExp(r'^(-)?(\d+)(?:\.(\d+))?$').firstMatch(t);
  if (m == null) throw const FormatException('اكتب رقمًا صحيحًا، مثال: 1250 أو 3.14');
  final ip = m[2]!;
  if (ip.length > 15) throw const FormatException('الرقم كبير جدًا (الحد الأقصى 15 خانة)');
  var s = wordsOf(int.parse(ip));
  final f = m[3] ?? '';
  if (f.isNotEmpty) {
    if (f.length > 20) throw const FormatException('عدد الخانات العشرية كبير جدًا');
    s += ' فاصلة ${f.split('').map((d) => d == '0' ? 'صفر' : _onesM[int.parse(d)]).join(' ')}';
  }
  final isZero = int.parse(ip) == 0 && RegExp(r'^0*$').hasMatch(f);
  return m[1] != null && !isZero ? 'سالب $s' : s;
}

// ───────────────────────── المبالغ ─────────────────────────
class _Forms {
  final String sing, dual, plural, acc;
  const _Forms(this.sing, this.dual, this.plural, this.acc);
}

class _Cur {
  final _Forms unit, sub;
  final bool subFem;
  final int div;
  const _Cur(this.unit, this.sub, this.subFem, this.div);
}

const _cur = <String, _Cur>{
  'sar': _Cur(_Forms('ريال', 'ريالان', 'ريالات', 'ريالًا'), _Forms('هللة', 'هللتان', 'هللات', 'هللة'), true, 100),
  'aed': _Cur(_Forms('درهم', 'درهمان', 'دراهم', 'درهمًا'), _Forms('فلس', 'فلسان', 'فلوس', 'فلسًا'), false, 100),
  'qar': _Cur(_Forms('ريال قطري', 'ريالان قطريان', 'ريالات قطرية', 'ريالًا قطريًا'), _Forms('درهم', 'درهمان', 'دراهم', 'درهمًا'), false, 100),
  'kwd': _Cur(_Forms('دينار كويتي', 'ديناران كويتيان', 'دنانير كويتية', 'دينارًا كويتيًا'), _Forms('فلس', 'فلسان', 'فلوس', 'فلسًا'), false, 1000),
  'bhd': _Cur(_Forms('دينار بحريني', 'ديناران بحرينيان', 'دنانير بحرينية', 'دينارًا بحرينيًا'), _Forms('فلس', 'فلسان', 'فلوس', 'فلسًا'), false, 1000),
  'egp': _Cur(_Forms('جنيه مصري', 'جنيهان مصريان', 'جنيهات مصرية', 'جنيهًا مصريًا'), _Forms('قرش', 'قرشان', 'قروش', 'قرشًا'), false, 100),
  'usd': _Cur(_Forms('دولار', 'دولاران', 'دولارات', 'دولارًا'), _Forms('سنت', 'سنتان', 'سنتات', 'سنتًا'), false, 100),
  'eur': _Cur(_Forms('يورو', 'يورو', 'يورو', 'يورو'), _Forms('سنت', 'سنتان', 'سنتات', 'سنتًا'), false, 100),
};

const tafqeetCurrencies = <(String, String)>[
  ('sar', 'ريال سعودي'),
  ('aed', 'درهم إماراتي'),
  ('qar', 'ريال قطري'),
  ('kwd', 'دينار كويتي'),
  ('bhd', 'دينار بحريني'),
  ('egp', 'جنيه مصري'),
  ('usd', 'دولار أمريكي'),
  ('eur', 'يورو'),
];

String _counted(int n, _Forms f, bool fem) {
  if (n == 0) return '';
  final one = fem ? ' واحدة' : ' واحد';
  if (n == 1) return '${f.sing}$one';
  if (n == 2) return f.dual;
  final r = n % 100;
  if (n > 100 && (r == 1 || r == 2)) {
    return '${wordsOf(n - r)} و${r == 1 ? '${f.sing}$one' : f.dual}';
  }
  var num = wordsOf(n, fem: fem);
  if (r >= 3 && r <= 10) return '$num ${f.plural}';
  if (r == 0) {
    for (final w in const ['مئتان', 'ألفان', 'مليونان', 'ملياران', 'تريليونان']) {
      if (num.endsWith(w)) {
        num = num.substring(0, num.length - 1);
        break;
      }
    }
    return '$num ${f.sing}';
  }
  return '$num ${f.acc}';
}

/// مبلغ → كلمات، مثال: 1250.50 → ألف ومئتان وخمسون ريالًا وخمس وسبعون ... (حسب العملة).
String amountToWords(String input, String code, {bool only = false}) {
  final c = _cur[code];
  if (c == null) throw const FormatException('عملة غير مدعومة');
  final t = toWesternDigits(input).replaceAll(RegExp(r'[\s,،٬]'), '').replaceAll('٫', '.');
  if (t.startsWith('-')) throw const FormatException('أدخل مبلغًا موجبًا');
  final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(t);
  if (m == null) throw const FormatException('اكتب مبلغًا صحيحًا، مثال: 1250.50');
  if (m[1]!.length > 12) throw const FormatException('المبلغ كبير جدًا');
  final dec = c.div == 100 ? 2 : 3;
  final frac = (m[2] ?? '').padRight(dec + 1, '0');
  var sub = int.parse(frac.substring(0, dec));
  if (frac.codeUnitAt(dec) >= 53) sub++; // تقريب الخانة التالية (5 فأكثر)
  var whole = int.parse(m[1]!);
  if (sub >= c.div) {
    sub -= c.div;
    whole++;
  }
  final parts = [
    _counted(whole, c.unit, false),
    _counted(sub, c.sub, c.subFem),
  ].where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return only ? 'فقط صفر ${c.unit.sing} لا غير' : 'صفر ${c.unit.sing}';
  final s = parts.join(' و');
  return only ? 'فقط $s لا غير' : s;
}

