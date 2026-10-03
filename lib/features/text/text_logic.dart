import 'dart:math' as math;

final _hasAlnum = RegExp(r'[\p{L}\p{N}]', unicode: true);

String latinDigits(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var t = s;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  return t;
}

class TextStats {
  final int words, chars, charsNoSpaces, lines, sentences, paragraphs;
  final double readMinutes;
  const TextStats(this.words, this.chars, this.charsNoSpaces, this.lines,
      this.sentences, this.paragraphs, this.readMinutes);
}

TextStats textStats(String s) {
  if (s.isEmpty) return const TextStats(0, 0, 0, 0, 0, 0, 0);
  final words =
      RegExp(r'\S+').allMatches(s).where((m) => _hasAlnum.hasMatch(m[0]!)).length;
  final lines = s.split(RegExp(r'\r\n|\r|\n')).length;
  final paragraphs =
      s.split(RegExp(r'(?:\r?\n){2,}')).where((p) => p.trim().isNotEmpty).length;
  final sentences = RegExp(r'[^.!?؟…\n]+[.!?؟…]*')
      .allMatches(s)
      .where((m) => _hasAlnum.hasMatch(m[0]!))
      .length;
  return TextStats(words, s.runes.length,
      s.replaceAll(RegExp(r'\s'), '').runes.length, lines, sentences, paragraphs,
      words / 200);
}

String cleanText(String s,
    {bool trimLines = true, bool collapseSpaces = true, bool removeEmpty = true}) {
  final out = <String>[];
  for (var l in s.split(RegExp(r'\r\n|\r|\n'))) {
    if (collapseSpaces) l = l.replaceAll(RegExp(r'[ \t\u00A0]+'), ' ');
    if (trimLines) l = l.trim();
    if (removeEmpty && l.trim().isEmpty) continue;
    out.add(l);
  }
  return out.join('\n');
}

String convertCase(String s, String mode) {
  switch (mode) {
    case 'lower':
      return s.toLowerCase();
    case 'title':
      return s.replaceAllMapped(
          RegExp(r'(\S)(\S*)'), (m) => m[1]!.toUpperCase() + m[2]!.toLowerCase());
    case 'sentence':
      return s.toLowerCase().replaceAllMapped(
          RegExp(r'(^|[.!?]\s+)(\p{L})', unicode: true),
          (m) => '${m[1]}${m[2]!.toUpperCase()}');
    default:
      return s.toUpperCase();
  }
}

String reverseText(String s, String mode) {
  switch (mode) {
    case 'words':
      return s
          .split(RegExp(r'\r\n|\r|\n'))
          .map((l) => l.split(RegExp(r'\s+')).reversed.join(' '))
          .join('\n');
    case 'lines':
      return s.split(RegExp(r'\r\n|\r|\n')).reversed.join('\n');
    default:
      return String.fromCharCodes(s.runes.toList().reversed);
  }
}

List<String> extractNumbers(String s) => RegExp(r'\d+(?:[.,]\d+)?')
    .allMatches(latinDigits(s))
    .map((m) => m[0]!)
    .toList();

String _trimUrl(String u) =>
    u.replaceFirst(RegExp(r'[.,;:!?)\]}»"،؛؟]+$'), '');

List<String> extractLinks(String s) =>
    RegExp(r'(?:https?://|www\.)[^\s<>"\u00A0]+', caseSensitive: false)
        .allMatches(s)
        .map((m) => _trimUrl(m[0]!))
        .toList();

List<String> extractEmails(String s) =>
    RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+')
        .allMatches(s)
        .map((m) => m[0]!)
        .toList();

String processLines(String s,
    {bool sort = false,
    bool unique = false,
    bool desc = false,
    bool ignoreCase = true}) {
  var lines = s
      .split(RegExp(r'\r\n|\r|\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  String key(String l) => ignoreCase ? l.toLowerCase() : l;
  if (unique) {
    final seen = <String>{};
    lines = lines.where((l) => seen.add(key(l))).toList();
  }
  if (sort) {
    lines.sort((a, b) => key(a).compareTo(key(b)));
    if (desc) lines = lines.reversed.toList();
  }
  return lines.join('\n');
}

List<String> _pwSets({
  required bool upper,
  required bool lower,
  required bool digits,
  required bool symbols,
  required bool avoidSimilar,
}) {
  String f(String s) =>
      avoidSimilar ? s.split('').where((c) => !'O0oIl1'.contains(c)).join() : s;
  return [
    if (upper) f('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
    if (lower) f('abcdefghijklmnopqrstuvwxyz'),
    if (digits) f('0123456789'),
    if (symbols) '!@#\$%^&*()-_=+[]{};:,.?',
  ];
}

int passwordPoolSize({
  bool upper = true,
  bool lower = true,
  bool digits = true,
  bool symbols = true,
  bool avoidSimilar = false,
}) =>
    _pwSets(
            upper: upper,
            lower: lower,
            digits: digits,
            symbols: symbols,
            avoidSimilar: avoidSimilar)
        .join()
        .length;

String generatePassword({
  required int length,
  bool upper = true,
  bool lower = true,
  bool digits = true,
  bool symbols = true,
  bool avoidSimilar = false,
  math.Random? rng,
}) {
  final r = rng ?? math.Random.secure();
  final sets = _pwSets(
      upper: upper,
      lower: lower,
      digits: digits,
      symbols: symbols,
      avoidSimilar: avoidSimilar);
  if (sets.isEmpty) throw const FormatException('اختر نوعًا واحدًا من الأحرف على الأقل');
  if (length < sets.length || length > 128) {
    throw const FormatException('الطول يجب أن يكون بين 4 و 128');
  }
  final pool = sets.join();
  final chars = <String>[for (final s in sets) s[r.nextInt(s.length)]];
  while (chars.length < length) {
    chars.add(pool[r.nextInt(pool.length)]);
  }
  for (var i = chars.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final t = chars[i];
    chars[i] = chars[j];
    chars[j] = t;
  }
  return chars.join();
}

double entropyBits(int length, int pool) =>
    pool <= 1 ? 0 : length * (math.log(pool) / math.ln2);

String strengthLabel(double bits) => bits < 40
    ? 'ضعيفة'
    : bits < 60
        ? 'متوسطة'
        : bits < 80
            ? 'قوية'
            : 'ممتازة';
