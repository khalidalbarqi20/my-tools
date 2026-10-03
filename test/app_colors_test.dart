import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/theme/app_colors.dart';

void main() {
  test('parseHex', () {
    expect(parseHex('FF8800'), const Color(0xFFFF8800));
    expect(parseHex('#1e6f5c'), const Color(0xFF1E6F5C));
    expect(parseHex(' 000000 '), const Color(0xFF000000));
    expect(parseHex('FFF'), isNull);
    expect(parseHex('GGGGGG'), isNull);
    expect(parseHex(''), isNull);
  });
  test('hexOf', () {
    expect(hexOf(const Color(0xFF1E6F5C)), '1E6F5C');
    expect(hexOf(const Color(0xFF000000)), '000000');
    expect(parseHex(hexOf(const Color(0xFFABCDEF))), const Color(0xFFABCDEF));
  });
  test('AppColors', () {
    const d = AppColors();
    expect(d.isDefault, true);
    final c = d.withAccent(Colors.red).withBg(Colors.black);
    expect(c.isDefault, false);
    expect(c.icon, isNull);
    expect(c.withAccent(null).withBg(null).isDefault, true);
  });
}
