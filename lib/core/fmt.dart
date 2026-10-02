typedef Rows = List<(String, String)>;

String fmt(double v, [int d = 2]) {
  var s = v.toStringAsFixed(d);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

/// تنسيق بعدد أرقام معنوية: يتعامل مع القيم الصغيرة جدًا والكبيرة جدًا.
String fmtSig(double v) {
  if (v == 0) return '0';
  final a = v.abs();
  String strip(String s) => s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
  if (a >= 1e15 || a < 1e-6) return v.toStringAsExponential(5);
  if (a >= 1e10) return strip(v.toStringAsFixed(2));
  return strip(v.toStringAsPrecision(10));
}
