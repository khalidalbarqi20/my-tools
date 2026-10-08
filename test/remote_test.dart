import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/app_info.dart';
import 'package:my_tools/core/categories.dart';
import 'package:my_tools/core/tool.dart';
import 'package:my_tools/remote/remote_apply.dart';
import 'package:my_tools/remote/remote_model.dart';

Tool t(String id, String cat, {String ar = 'اسم', List<String> kw = const ['k']}) => Tool(
      id: id,
      nameAr: '$ar $id',
      nameEn: 'En $id',
      category: cat,
      keywords: kw,
      icon: Icons.add,
      builder: (_) => const SizedBox(),
    );

void main() {
  test('رقم البناء يطابق pubspec', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final build = int.parse(line.split('+').last.trim());
    expect(kAppBuild, build);
  });

  group('تحليل الإعدادات', () {
    test('بيانات غير صالحة ترجع null', () {
      expect(parseRemoteConfig(null), isNull);
      expect(parseRemoteConfig('x'), isNull);
      expect(parseRemoteConfig([]), isNull);
      expect(parseRemoteConfig({}), isNull);
      expect(parseRemoteConfig({'version': 0}), isNull);
      expect(parseRemoteConfig({'version': 'a'}), isNull);
    });

    test('أقل إعدادات صالحة تأخذ القيم الافتراضية', () {
      final c = parseRemoteConfig({'version': 3})!;
      expect(c.version, 3);
      expect(c.tools, isEmpty);
      expect(c.ads.banner, true);
      expect(c.ads.everyN, 5);
      expect(c.maintenance.enabled, false);
      expect(c.update.minBuild, 0);
      expect(c.announcement.enabled, false);
    });

    test('تقبل المصفوفة والخريطة ذات المفاتيح الرقمية', () {
      final a = parseRemoteConfig({
        'version': 1,
        'tools': [
          {'id': 'a'},
          {'id': 'b'}
        ]
      })!;
      final b = parseRemoteConfig({
        'version': 1,
        'tools': {
          '1': {'id': 'b'},
          '0': {'id': 'a'},
          '10': {'id': 'c'},
        }
      })!;
      expect(a.tools.map((e) => e.id), ['a', 'b']);
      expect(b.tools.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('تجاهل العناصر التالفة وقصّ النصوص وحصر الأرقام', () {
      final c = parseRemoteConfig({
        'version': 2,
        'tools': [
          5,
          {'id': ''},
          {'id': 'x', 'nameAr': 'ا' * 200, 'minBuild': -5, 'visible': 'no', 'keywords': ['a', 7, ' ', 'b']},
        ],
        'categories': [
          {'id': 'c1'},
          {'id': 'c2', 'nameAr': 'قسم'},
        ],
        'ads': {'everyN': 999, 'minGapMin': -1, 'warmupSec': 99999, 'banner': false},
      })!;
      expect(c.tools.length, 1);
      expect(c.tools.first.nameAr!.length, 60);
      expect(c.tools.first.minBuild, 0);
      expect(c.tools.first.visible, true); // قيمة غير منطقية: الافتراضي
      expect(c.tools.first.keywords, ['a', 'b']);
      expect(c.categories.length, 1);
      expect(c.categories.first.nameEn, 'قسم');
      expect(c.ads.everyN, 50);
      expect(c.ads.minGapMin, 0);
      expect(c.ads.warmupSec, 600);
      expect(c.ads.banner, false);
    });

    test('معرّف الإشعار الافتراضي ومجموعة الأدوات بلا إعلانات', () {
      final c = parseRemoteConfig({
        'version': 7,
        'announcement': {'enabled': true, 'title': 'مرحبا'},
        'tools': [
          {'id': 'a', 'ads': false},
          {'id': 'b'}
        ],
      })!;
      expect(c.announcement.id, 'v7');
      expect(c.announcement.enabled, true);
      expect(c.noAdTools, {'a'});
    });
  });

  group('تطبيق الإعدادات على الأدوات', () {
    final base = [t('a', 'calc'), t('b', 'calc'), t('c', 'pdf')];

    test('بدون إعدادات تبقى الأدوات كما هي', () {
      expect(applyToolConfig(base, null, 1), base);
    });

    test('إخفاء وترتيب وإضافة غير المذكور في الآخر', () {
      final cfg = parseRemoteConfig({
        'version': 1,
        'tools': [
          {'id': 'b'},
          {'id': 'a', 'visible': false},
        ]
      })!;
      final r = applyToolConfig(base, cfg, 1);
      expect(r.map((e) => e.id), ['b', 'c']);
    });

    test('تغيير الاسم والقسم وإضافة كلمات', () {
      final cfg = parseRemoteConfig({
        'version': 1,
        'tools': [
          {'id': 'a', 'nameAr': 'جديد', 'category': 'pdf', 'keywords': ['زائد']},
        ]
      })!;
      final a = applyToolConfig(base, cfg, 1).firstWhere((e) => e.id == 'a');
      expect(a.nameAr, 'جديد');
      expect(a.nameEn, 'En a');
      expect(a.category, 'pdf');
      expect(a.keywords, ['k', 'زائد']);
      expect(a.matches('زائد'), true);
    });

    test('أدوات تحتاج نسخة أحدث تُخفى', () {
      final cfg = parseRemoteConfig({
        'version': 1,
        'tools': [
          {'id': 'a', 'minBuild': 5},
        ]
      })!;
      expect(applyToolConfig(base, cfg, 4).any((e) => e.id == 'a'), false);
      expect(applyToolConfig(base, cfg, 5).any((e) => e.id == 'a'), true);
    });

    test('إعدادات لأدوات غير موجودة أو مكررة تُهمل', () {
      final cfg = parseRemoteConfig({
        'version': 1,
        'tools': [
          {'id': 'zzz'},
          {'id': 'a'},
          {'id': 'a', 'visible': false},
        ]
      })!;
      final r = applyToolConfig(base, cfg, 1);
      expect(r.map((e) => e.id), ['a', 'b', 'c']);
    });
  });

  group('تطبيق الإعدادات على الأقسام', () {
    test('ترتيب وإخفاء وإعادة تسمية وقسم جديد', () {
      final cfg = parseRemoteConfig({
        'version': 1,
        'categories': [
          {'id': 'pdf', 'nameAr': 'ملفات', 'nameEn': 'Files', 'icon': 'book'},
          {'id': 'calc', 'nameAr': 'x', 'visible': false},
          {'id': 'new1', 'nameAr': 'جديد', 'icon': 'nope'},
        ]
      })!;
      final r = applyCategoryConfig(categories, cfg);
      expect(r.first.id, 'pdf');
      expect(r.first.nameAr, 'ملفات');
      expect(r.first.icon, Icons.menu_book_outlined);
      expect(r.any((c) => c.id == 'calc'), false);
      expect(r[1].id, 'new1');
      expect(r[1].icon, Icons.apps);
      expect(r.any((c) => c.id == 'convert'), true); // غير المذكور يبقى
    });
    test('بدون إعدادات الأقسام كما هي', () {
      expect(applyCategoryConfig(categories, null), categories);
      expect(applyCategoryConfig(categories, parseRemoteConfig({'version': 1})), categories);
    });
  });
}
