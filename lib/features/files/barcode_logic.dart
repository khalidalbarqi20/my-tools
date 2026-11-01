/// الباركود: Code 128 و EAN-13 و EAN-8 (دوال نقية قابلة للاختبار).
library;

/// أنماط Code 128 (القيم 0..106): أعرض الشرائط والفراغات بالتناوب (شريط أولًا).
const _c128 = <String>[
  '212222', '222122', '222221', '121223', '121322', '131222', '122213', '122312',
  '132212', '221213', '221312', '231212', '112232', '122132', '122231', '113222',
  '123122', '123221', '223211', '221132', '221231', '213212', '223112', '312131',
  '311222', '321122', '321221', '312212', '322112', '322211', '212123', '212321',
  '232121', '111323', '131123', '131321', '112313', '132113', '132311', '211313',
  '231113', '231311', '112133', '112331', '132131', '113123', '113321', '133121',
  '313121', '211331', '231131', '213113', '213311', '213131', '311123', '311321',
  '331121', '312113', '312311', '332111', '314111', '221411', '431111', '111224',
  '111422', '121124', '121421', '141122', '141221', '112214', '112412', '122114',
  '122411', '142112', '142211', '241211', '221114', '413111', '241112', '134111',
  '111242', '121142', '121241', '114212', '124112', '124211', '411212', '421112',
  '421211', '212141', '214121', '412121', '111143', '111341', '131141', '114113',
  '114311', '411113', '411311', '113141', '114131', '311141', '411131', '211412',
  '211214', '211232', '2331112',
];

const _l = ['0001101', '0011001', '0010011', '0111101', '0100011', '0110001', '0101111', '0111011', '0110111', '0001011'];
const _par = ['LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG', 'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL'];

String _flip(String s) => s.split('').map((c) => c == '0' ? '1' : '0').join();
String _rev(String s) => s.split('').reversed.join();
String _r(int d) => _flip(_l[d]);
String _g(int d) => _rev(_r(d));

class BarcodeResult {
  /// سلسلة وحدات: '1' شريط و '0' فراغ.
  final String bits;

  /// النص المقروء أسفل الباركود.
  final String label;
  const BarcodeResult(this.bits, this.label);
}

enum BarcodeKind { code128, ean13, ean8 }

const barcodeKindNames = {
  BarcodeKind.code128: 'Code 128 (نص وأرقام)',
  BarcodeKind.ean13: 'EAN-13 (منتجات)',
  BarcodeKind.ean8: 'EAN-8 (منتجات صغيرة)',
};

/// رقم التحقق لسلسلة أرقام بدون رقم التحقق (12 لـ EAN-13 أو 7 لـ EAN-8).
int eanCheckDigit(String d) {
  var s = 0;
  final rev = d.split('').reversed.toList();
  for (var i = 0; i < rev.length; i++) {
    s += int.parse(rev[i]) * (i % 2 == 0 ? 3 : 1);
  }
  return (10 - s % 10) % 10;
}

/// قيم Code 128: يستخدم المجموعة C للأرقام الزوجية (4 فأكثر) وإلا المجموعة B.
List<int> code128Codes(String s) {
  if (s.isEmpty) throw const FormatException('اكتب نصًا');
  if (s.length > 80) throw const FormatException('الحد الأقصى 80 خانة');
  for (final u in s.codeUnits) {
    if (u < 32 || u > 126) {
      throw const FormatException('يدعم الأحرف الإنجليزية والأرقام والرموز فقط (بدون عربي)');
    }
  }
  final codes = <int>[];
  if (s.length >= 4 && s.length.isEven && RegExp(r'^\d+$').hasMatch(s)) {
    codes.add(105);
    for (var i = 0; i < s.length; i += 2) {
      codes.add(int.parse(s.substring(i, i + 2)));
    }
  } else {
    codes.add(104);
    for (final u in s.codeUnits) {
      codes.add(u - 32);
    }
  }
  var chk = codes[0];
  for (var i = 1; i < codes.length; i++) {
    chk += i * codes[i];
  }
  codes
    ..add(chk % 103)
    ..add(106);
  return codes;
}

String code128Bits(String s) {
  final b = StringBuffer();
  var bar = true;
  for (final v in code128Codes(s)) {
    for (final ch in _c128[v].split('')) {
      b.write((bar ? '1' : '0') * int.parse(ch));
      bar = !bar;
    }
  }
  return b.toString();
}

String _digits(String s, List<int> okLens, String name) {
  final t = s.trim();
  if (!RegExp(r'^\d+$').hasMatch(t) || !okLens.contains(t.length)) {
    throw FormatException('$name: اكتب ${okLens.join(' أو ')} رقمًا');
  }
  return t;
}

String ean13Bits(String d13) {
  final p = _par[int.parse(d13[0])];
  final b = StringBuffer('101');
  for (var i = 0; i < 6; i++) {
    final d = int.parse(d13[1 + i]);
    b.write(p[i] == 'L' ? _l[d] : _g(d));
  }
  b.write('01010');
  for (var i = 7; i < 13; i++) {
    b.write(_r(int.parse(d13[i])));
  }
  b.write('101');
  return b.toString();
}

String ean8Bits(String d8) {
  final b = StringBuffer('101');
  for (var i = 0; i < 4; i++) {
    b.write(_l[int.parse(d8[i])]);
  }
  b.write('01010');
  for (var i = 4; i < 8; i++) {
    b.write(_r(int.parse(d8[i])));
  }
  b.write('101');
  return b.toString();
}

/// يبني الباركود. EAN: إن أُدخلت الخانات بدون رقم التحقق يُحسب تلقائيًا، وإن أُدخل يُتحقق منه.
BarcodeResult buildBarcode(BarcodeKind k, String input) {
  switch (k) {
    case BarcodeKind.code128:
      return BarcodeResult(code128Bits(input), input);
    case BarcodeKind.ean13:
      final t = _digits(input, [12, 13], 'EAN-13');
      final base = t.substring(0, 12);
      final c = eanCheckDigit(base);
      if (t.length == 13 && int.parse(t[12]) != c) {
        throw FormatException('رقم التحقق غير صحيح (الصحيح $c)');
      }
      final full = '$base$c';
      return BarcodeResult(ean13Bits(full), full);
    case BarcodeKind.ean8:
      final t = _digits(input, [7, 8], 'EAN-8');
      final base = t.substring(0, 7);
      final c = eanCheckDigit(base);
      if (t.length == 8 && int.parse(t[7]) != c) {
        throw FormatException('رقم التحقق غير صحيح (الصحيح $c)');
      }
      final full = '$base$c';
      return BarcodeResult(ean8Bits(full), full);
  }
}
