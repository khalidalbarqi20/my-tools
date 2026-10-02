typedef Rows = List<(String, String)>;

String fmt(double v, [int d = 2]) {
  var s = v.toStringAsFixed(d);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}
