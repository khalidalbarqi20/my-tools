import 'dart:math';
import '../../core/num_parse.dart';

const _lim = 1000000000;

/// يحول النص لعدد صحيح (يدعم الأرقام العربية). يرجع null لو غير صالح.
int? parseWhole(String s) {
  final v = parseNum(s);
  if (v == null || v != v.truncateToDouble() || v.abs() > _lim) return null;
  return v.toInt();
}

List<int> randomNumbers(int min, int max, int count,
    {bool unique = false, Random? rng}) {
  final r = rng ?? Random();
  if (min > max) {
    throw const FormatException('الحد الأدنى يجب ألا يزيد عن الحد الأعلى');
  }
  if (count < 1 || count > 100) {
    throw const FormatException('العدد يجب أن يكون بين 1 و 100');
  }
  final range = max - min + 1;
  if (unique && count > range) {
    throw const FormatException('النطاق أصغر من عدد الأرقام المطلوبة بدون تكرار');
  }
  if (!unique) {
    return [for (var i = 0; i < count; i++) min + r.nextInt(range)];
  }
  if (range <= 2 * count) {
    final all = [for (var i = min; i <= max; i++) i]..shuffle(r);
    return all.sublist(0, count);
  }
  final seen = <int>{};
  final out = <int>[];
  while (out.length < count) {
    final n = min + r.nextInt(range);
    if (seen.add(n)) out.add(n);
  }
  return out;
}

List<int> rollDice(int sides, int count, {Random? rng}) {
  final r = rng ?? Random();
  if (sides < 2 || sides > 1000) {
    throw const FormatException('عدد أوجه النرد غير صالح');
  }
  if (count < 1 || count > 10) {
    throw const FormatException('عدد النرد يجب أن يكون بين 1 و 10');
  }
  return [for (var i = 0; i < count; i++) 1 + r.nextInt(sides)];
}

bool coinFlip({Random? rng}) => (rng ?? Random()).nextBool();

/// يقسم النص إلى خيارات: سطر لكل خيار، أو يفصل بينها فاصلة.
List<String> parseItems(String s) => s
    .split(RegExp(r'[\n\r,،;؛]+'))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

String pickRandom(List<String> items, {Random? rng}) {
  if (items.isEmpty) throw const FormatException('أضف خيارًا واحدًا على الأقل');
  return items[(rng ?? Random()).nextInt(items.length)];
}

List<String> shuffled(List<String> items, {Random? rng}) =>
    [...items]..shuffle(rng ?? Random());
