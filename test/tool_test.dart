import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/registry.dart';

void main() {
  test('البحث بالعربي والإنجليزي والمرادفات', () {
    final t = allTools.first;
    expect(t.matches('خصم'), true);
    expect(t.matches('تخفيض'), true);
    expect(t.matches('DISCOUNT'), true);
    expect(t.matches(''), true);
    expect(t.matches('xyz'), false);
  });
}
