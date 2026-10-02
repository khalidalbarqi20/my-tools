import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/registry.dart';
import 'package:my_tools/core/search.dart';

void main() {
  test('norm', () {
    expect(norm('حاسبَةُ'), 'حاسبه');
    expect(norm('أإآ'), 'ااا');
  });
  test('بحث مرن', () {
    final t = allTools.first;
    expect(t.matches('خصوم'), true);
    expect(t.matches('discont'), true);
    expect(t.matches('حاسبة خصم'), true);
    expect(t.matches('qrcode'), false);
  });
}
