import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'device_pages.dart';
import 'sensor_pages.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'device',
      keywords: ['جهاز', 'هاتف', 'جوال', 'device', 'phone', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> deviceTools = [
  _t('dev_info', 'معلومات الجهاز', 'Device Info',
      ['موديل', 'شركة', 'أندرويد', 'بطارية', 'شاشة', 'دقة', 'مواصفات', 'android', 'battery', 'model', 'specs'],
      Icons.smartphone, (_) => const DeviceInfoPage()),
  _t('dev_flashlight', 'الكشاف', 'Flashlight',
      ['كشاف', 'فلاش', 'مصباح', 'ضوء', 'إضاءة', 'torch', 'flashlight', 'flash', 'light'],
      Icons.flashlight_on, (_) => const FlashlightPage()),
  _t('dev_compass', 'البوصلة', 'Compass',
      ['بوصلة', 'اتجاه', 'شمال', 'قبلة', 'compass', 'north', 'direction'],
      Icons.explore_outlined, (_) => const CompassPage()),
  _t('dev_level', 'الميزان', 'Level',
      ['ميزان', 'مستوى', 'ميزان مائي', 'فقاعة', 'استواء', 'level', 'spirit level', 'bubble', 'tilt'],
      Icons.straighten, (_) => const LevelPage()),
  _t('dev_screen', 'اختبار الشاشة', 'Screen Test',
      ['شاشة', 'ألوان', 'بكسل', 'بقع', 'dead pixel', 'display', 'colors'],
      Icons.tv_outlined, (_) => const ScreenTestPage()),
  _t('dev_touch', 'اختبار اللمس', 'Touch Test',
      ['لمس', 'لمسة', 'أصابع', 'touch', 'multitouch', 'screen'],
      Icons.touch_app_outlined, (_) => const TouchTestPage()),
  _t('dev_vibration', 'اختبار الاهتزاز', 'Vibration Test',
      ['اهتزاز', 'هزاز', 'vibration', 'vibrate', 'haptic'],
      Icons.vibration, (_) => const VibrationTestPage()),
];
