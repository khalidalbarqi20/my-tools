import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/text/text_logic.dart';

void main() {
  test('textStats', () {
    final e = textStats('');
    expect([e.words, e.chars, e.lines], [0, 0, 0]);
    final a = textStats('مرحبا بالعالم');
    expect([a.words, a.chars, a.charsNoSpaces, a.lines, a.sentences], [2, 13, 12, 1, 1]);
    final b = textStats('Hello  world.\n\nSecond para!');
    expect([b.words, b.lines, b.paragraphs, b.sentences], [4, 3, 2, 2]);
    expect(textStats('... !!!').words, 0);
    expect(textStats('a' * 400 == '' ? 'x' : List.filled(400, 'w').join(' ')).readMinutes, 2.0);
  });
  test('cleanText', () {
    expect(cleanText('  hello   world  \n\n\n  second\t line \n'), 'hello world\nsecond line');
    expect(cleanText('a\n\nb', removeEmpty: false), 'a\n\nb');
    expect(cleanText('  a  b ', trimLines: false, collapseSpaces: true), ' a b ');
    expect(cleanText('   \n  '), '');
  });
  test('convertCase', () {
    expect(convertCase('Hello', 'upper'), 'HELLO');
    expect(convertCase('Hello', 'lower'), 'hello');
    expect(convertCase('hELLO wORLD', 'title'), 'Hello World');
    expect(convertCase('hello. world! ok', 'sentence'), 'Hello. World! Ok');
    expect(convertCase('مرحبا', 'upper'), 'مرحبا');
  });
  test('reverseText', () {
    expect(reverseText('abc', 'chars'), 'cba');
    expect(reverseText('a😀b', 'chars'), 'b😀a');
    expect(reverseText('one two three', 'words'), 'three two one');
    expect(reverseText('a\nb\nc', 'lines'), 'c\nb\na');
  });
  test('extract', () {
    expect(extractNumbers('عندي ١٢ تفاحة و 3.5 كيلو و 1,200'), ['12', '3.5', '1,200']);
    expect(extractNumbers('بدون أرقام'), isEmpty);
    expect(extractLinks('زر https://a.com/x?y=1، و www.test.org. ثم'),
        ['https://a.com/x?y=1', 'www.test.org']);
    expect(extractEmails('a.b@x.com, c@d.org.'), ['a.b@x.com', 'c@d.org']);
    expect(extractEmails('no email here'), isEmpty);
  });
  test('processLines', () {
    expect(processLines('b\na\nB\n\na', unique: true, sort: true), 'a\nb');
    expect(processLines('b\na\nB\n\na', unique: true, sort: true, desc: true), 'b\na');
    expect(processLines(' b \n\n a '), 'b\na');
    expect(processLines('b\nB', unique: true, ignoreCase: false), 'b\nB');
  });
  test('كلمات المرور', () {
    final r = math.Random(42);
    final p = generatePassword(length: 20, rng: r);
    expect(p.length, 20);
    expect(RegExp(r'[A-Z]').hasMatch(p), true);
    expect(RegExp(r'[a-z]').hasMatch(p), true);
    expect(RegExp(r'\d').hasMatch(p), true);
    expect(RegExp(r'[^A-Za-z0-9]').hasMatch(p), true);
    final d = generatePassword(length: 12, upper: false, lower: false, symbols: false, rng: r);
    expect(RegExp(r'^\d{12}$').hasMatch(d), true);
    for (var i = 0; i < 50; i++) {
      final s = generatePassword(length: 30, avoidSimilar: true, rng: math.Random(i));
      expect(RegExp(r'[O0oIl1]').hasMatch(s), false);
    }
    expect(() => generatePassword(length: 10, upper: false, lower: false, digits: false, symbols: false), throwsFormatException);
    expect(() => generatePassword(length: 3), throwsFormatException);
    expect(() => generatePassword(length: 200), throwsFormatException);
    expect(generatePassword(length: 16), isNot(generatePassword(length: 16)));
  });
  test('القوة', () {
    expect(passwordPoolSize(), 26 + 26 + 10 + 23);
    expect(passwordPoolSize(upper: false, lower: false, symbols: false), 10);
    expect(entropyBits(10, 10) > 33 && entropyBits(10, 10) < 34, true);
    expect(strengthLabel(30), 'ضعيفة');
    expect(strengthLabel(50), 'متوسطة');
    expect(strengthLabel(70), 'قوية');
    expect(strengthLabel(100), 'ممتازة');
    expect(entropyBits(10, 0), 0);
  });
}
