import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/core/platform_rules.dart';

void main() {
  test('الكشاف ومعلومات الجهاز للتطبيق فقط', () {
    for (final id in ['dev_flashlight', 'dev_info']) {
      expect(supportedOn(id, Plat.app), true);
      expect(supportedOn(id, Plat.web), false);
      expect(supportedOn(id, Plat.iosWeb), false);
      expect(whyNot(id), isNotEmpty);
    }
  });

  test('المستشعرات والاهتزاز مخفية على آيفون فقط', () {
    for (final id in ['dev_compass', 'dev_level', 'dev_sensors', 'dev_vibration']) {
      expect(supportedOn(id, Plat.app), true);
      expect(supportedOn(id, Plat.web), true);
      expect(supportedOn(id, Plat.iosWeb), false);
    }
  });

  test('أداة بلا قاعدة تعمل في كل مكان، والتنبيه لآيفون فقط', () {
    for (final p in Plat.values) {
      expect(supportedOn('calculator', p), true);
    }
    expect(cautionOn('img_removebg', Plat.iosWeb), isNotNull);
    expect(cautionOn('img_removebg', Plat.web), isNull);
    expect(cautionOn('img_removebg', Plat.app), isNull);
  });
}
