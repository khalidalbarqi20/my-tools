/// يحول النص لرقم، يدعم الأرقام العربية والفاصلة العشرية العربية.
double? parseNum(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var t = s.trim();
  if (t.isEmpty) return null;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  t = t.replaceAll('٫', '.').replaceAll('،', '.').replaceAll(',', '.');
  final v = double.tryParse(t);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}
