import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/registry.dart';
import 'package:flutter/material.dart';
import 'package:my_tools/core/search.dart';
import 'package:my_tools/core/tool.dart';

void main() {
  test('norm', () {
    expect(norm('حاسبَةُ'), 'حاسبه');
    expect(norm('أإآ'), 'ااا');
  });
  test('بحث مرن', () {
    final t = allTools.firstWhere((x) => x.id == 'discount');
    expect(t.matches('خصوم'), true);
    expect(t.matches('discont'), true);
    expect(t.matches('حاسبة خصم'), true);
    expect(t.matches('qrcode'), false);
  });
  test('البحث يطابق اسم القسم', () {
    Tool t(String cat, String ar) => Tool(
        id: 'x', nameAr: ar, nameEn: 'X', category: cat, keywords: const [],
        icon: Icons.add, builder: (_) => const SizedBox());
    expect(t('car', 'مدة الرحلة').matches('سيارة'), isTrue);
    expect(t('geo', 'الدائرة').matches('سيارة'), isFalse);
    expect(t('home', 'مساحة وحجم الغرفة').matches('مساحة'), isTrue);
    expect(t('geo', 'مساحة ومحيط المربع').matches('مساحه'), isTrue);
  });
}
