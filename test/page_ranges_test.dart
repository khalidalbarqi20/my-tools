import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/pdf/page_ranges.dart';

void main() {
  test('نطاقات صحيحة', () {
    expect(parsePages('1-3,5', 10), [0, 1, 2, 4]);
    expect(parsePages('8-', 10), [7, 8, 9]);
    expect(parsePages('3-1', 10), [2, 1, 0]);
    expect(parsePages('3,1,2', 10), [2, 0, 1]);
    expect(parsePages(' 2 , 4 ', 10), [1, 3]);
  });
  test('أرقام وفواصل عربية', () {
    expect(parsePages('١-٣،٥', 10), [0, 1, 2, 4]);
    expect(parsePages('٨-', 10), [7, 8, 9]);
  });
  test('مجموعات التقسيم', () {
    expect(parseGroups('1-3,4-6', 10), [[0, 1, 2], [3, 4, 5]]);
    expect(parseGroups('2', 5), [[1]]);
  });
  test('تكرار', () {
    expect(() => parsePages('1,1', 5), throwsFormatException);
    expect(parsePages('1,1', 5, unique: false), [0, 0]);
    expect(parsePages('1-3,2', 5, unique: false).toSet(), {0, 1, 2});
  });
  test('إدخال غير صحيح', () {
    for (final bad in ['', '   ', '0', '11', '1-11', 'abc', '1-a', '-3', '1..3']) {
      expect(() => parsePages(bad, 10), throwsFormatException, reason: bad);
    }
    expect(() => parsePages('99999999999999999999', 10), throwsFormatException);
  });
}
