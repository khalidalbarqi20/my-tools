const _ar = '٠١٢٣٤٥٦٧٨٩';

String _latin(String s) {
  var t = s;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(_ar[i], '$i');
  }
  return t
      .replaceAll('،', ',')
      .replaceAll('؛', ',')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('−', '-');
}

void _check(int n, int total) {
  if (n < 1 || n > total) {
    throw FormatException('الصفحة $n غير موجودة (الملف فيه $total صفحة)');
  }
}

/// كل نطاق مفصول بفاصلة يصير مجموعة. أرقام الصفحات تبدأ من 0 في الناتج.
/// أمثلة: "1-3,5"  "8-" (من 8 للنهاية)  "3-1" (تنازلي)
List<List<int>> parseGroups(String input, int total) {
  final s = _latin(input).trim();
  final out = <List<int>>[];
  for (final tok in s.split(RegExp(r'[,;\s]+'))) {
    if (tok.isEmpty) continue;
    final m = RegExp(r'^(\d+)(-(\d*))?$').firstMatch(tok);
    if (m == null) throw FormatException('صيغة غير صحيحة: $tok');
    final a = int.tryParse(m.group(1)!);
    if (a == null) throw FormatException('رقم غير صحيح: $tok');
    var b = a;
    if (m.group(2) != null) {
      final bs = m.group(3) ?? '';
      b = bs.isEmpty ? total : (int.tryParse(bs) ?? -1);
    }
    _check(a, total);
    _check(b, total);
    out.add(a <= b
        ? [for (var i = a; i <= b; i++) i - 1]
        : [for (var i = a; i >= b; i--) i - 1]);
  }
  if (out.isEmpty) {
    throw const FormatException('اكتب أرقام الصفحات، مثال: 1-3,5');
  }
  return out;
}

List<int> parsePages(String input, int total, {bool unique = true}) {
  final all = [for (final g in parseGroups(input, total)) ...g];
  if (unique) {
    final seen = <int>{};
    for (final i in all) {
      if (!seen.add(i)) throw FormatException('الصفحة ${i + 1} مكررة');
    }
  }
  return all;
}
