import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/random/random_logic.dart';

void main() {
  test('parseWhole', () {
    expect(parseWhole('12'), 12);
    expect(parseWhole(' ١٢ '), 12);
    expect(parseWhole('-5'), -5);
    expect(parseWhole('3.5'), isNull);
    expect(parseWhole(''), isNull);
    expect(parseWhole('abc'), isNull);
    expect(parseWhole('99999999999'), isNull);
  });
  test('randomNumbers ضمن النطاق', () {
    final r = Random(1);
    for (var i = 0; i < 200; i++) {
      final v = randomNumbers(-3, 3, 5, rng: r);
      expect(v.length, 5);
      expect(v.every((e) => e >= -3 && e <= 3), true);
    }
    expect(randomNumbers(7, 7, 3), [7, 7, 7]);
    expect(randomNumbers(0, 2000000000, 1).first, inInclusiveRange(0, 2000000000));
  });
  test('randomNumbers بدون تكرار', () {
    final r = Random(2);
    for (var i = 0; i < 100; i++) {
      final a = randomNumbers(1, 10, 10, unique: true, rng: r);
      expect(a.toSet().length, 10);
      final b = randomNumbers(1, 1000000, 100, unique: true, rng: r);
      expect(b.toSet().length, 100);
    }
  });
  test('randomNumbers أخطاء', () {
    expect(() => randomNumbers(5, 1, 1), throwsFormatException);
    expect(() => randomNumbers(1, 5, 0), throwsFormatException);
    expect(() => randomNumbers(1, 5, 101), throwsFormatException);
    expect(() => randomNumbers(1, 5, 6, unique: true), throwsFormatException);
  });
  test('rollDice', () {
    final r = Random(3);
    for (var i = 0; i < 200; i++) {
      final v = rollDice(6, 4, rng: r);
      expect(v.length, 4);
      expect(v.every((e) => e >= 1 && e <= 6), true);
    }
    expect(() => rollDice(1, 1), throwsFormatException);
    expect(() => rollDice(6, 0), throwsFormatException);
    expect(() => rollDice(6, 11), throwsFormatException);
  });
  test('coinFlip يعطي الاحتمالين', () {
    final r = Random(4);
    final v = {for (var i = 0; i < 100; i++) coinFlip(rng: r)};
    expect(v, {true, false});
  });
  test('parseItems والاختيار', () {
    expect(parseItems('أ\nب, ج،د;  \n\n هـ '), ['أ', 'ب', 'ج', 'د', 'هـ']);
    expect(parseItems('  \n , '), isEmpty);
    final items = ['a', 'b', 'c'];
    final r = Random(5);
    expect({for (var i = 0; i < 100; i++) pickRandom(items, rng: r)}, items.toSet());
    expect(() => pickRandom([]), throwsFormatException);
    final s = shuffled(items, rng: r);
    expect(s.toSet(), items.toSet());
    expect(items, ['a', 'b', 'c']);
  });
}
