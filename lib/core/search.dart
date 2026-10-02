/// توحيد النص العربي: بدون تشكيل، وتوحيد الهمزات والتاء المربوطة والألف المقصورة.
String norm(String s) {
  var t = s.toLowerCase().trim();
  t = t.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  t = t
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
  return t;
}

int _lev(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final c = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + c]
          .reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// كل كلمة في البحث لازم تطابق (احتواء، أو غلطة حرف واحد للكلمات الطويلة).
bool fuzzyMatch(String query, List<String> terms) {
  final q = norm(query);
  if (q.isEmpty) return true;
  final words = <String>[];
  for (final t in terms) {
    words.addAll(norm(t).split(RegExp(r'\s+')));
  }
  final joined = words.join(' ');
  for (final tok in q.split(RegExp(r'\s+'))) {
    if (joined.contains(tok)) continue;
    if (tok.length >= 4 &&
        words.any((w) => (w.length - tok.length).abs() <= 1 && _lev(w, tok) <= 1)) {
      continue;
    }
    return false;
  }
  return true;
}
