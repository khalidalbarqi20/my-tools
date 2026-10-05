import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/ads/ad_ids.dart';
import 'package:my_tools/ads/ad_policy.dart';

void main() {
  test('معرّفات الإعلانات: تجريبية إذا لم تُحدَّد حقيقية', () {
    expect(pickUnitId('', testBannerId), testBannerId);
    expect(pickUnitId('   ', testBannerId), testBannerId);
    expect(pickUnitId(' ca-app-pub-1/2 ', testBannerId), 'ca-app-pub-1/2');
    // في بيئة الاختبار لا نمرّر define، فيجب أن تكون تجريبية.
    expect(bannerUnitId(), testBannerId);
    expect(interstitialUnitId(), testInterstitialId);
    expect(testBannerId.startsWith('ca-app-pub-3940256099942544/'), true);
  });

  group('سياسة الإعلان البيني', () {
    final t0 = DateTime(2026, 10, 5, 10);
    InterstitialPolicy make() => InterstitialPolicy(start: t0);

    test('لا يظهر قبل عدد كافٍ من الأدوات', () {
      final p = make();
      final now = t0.add(const Duration(minutes: 10));
      for (var i = 0; i < 4; i++) {
        p.registerFinish();
        expect(p.due(now), false);
      }
      p.registerFinish();
      expect(p.due(now), true);
    });

    test('لا يظهر في فترة التهدئة من بداية التطبيق', () {
      final p = make();
      for (var i = 0; i < 10; i++) {
        p.registerFinish();
      }
      expect(p.due(t0.add(const Duration(seconds: 30))), false);
      expect(p.due(t0.add(const Duration(seconds: 91))), true);
    });

    test('فاصل زمني أدنى وإعادة العدّ بعد العرض', () {
      final p = make();
      final first = t0.add(const Duration(minutes: 5));
      for (var i = 0; i < 5; i++) {
        p.registerFinish();
      }
      expect(p.due(first), true);
      p.markShown(first);
      expect(p.due(first), false); // العدّاد صُفّر
      for (var i = 0; i < 5; i++) {
        p.registerFinish();
      }
      expect(p.due(first.add(const Duration(minutes: 1))), false); // قبل الفاصل
      expect(p.due(first.add(const Duration(minutes: 3))), true);
    });

    test('الأدوات المستثناة', () {
      expect(noAdTools.contains('qr_scan'), true);
      expect(noAdTools.contains('dev_screen'), true);
      expect(noAdTools.contains('calc_discount'), false);
    });
  });
}
