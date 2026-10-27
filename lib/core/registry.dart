import '../features/baloot/baloot_tools.dart';
import '../features/calculator/calc_tools.dart';
import '../features/converters/converter_tools.dart';
import '../features/arabic/arabic_tools.dart';
import '../features/currency/currency_tools.dart';
import '../features/device/device_tools.dart';
import '../features/extras/extras_tools.dart';
import '../features/math/math_tools.dart';
import '../features/more/more_tools.dart';
import '../features/devtools/dev_tools.dart';
import '../features/life/life_tools.dart';
import '../features/network/network_tools.dart';
import '../features/image/image_tools.dart';
import '../features/pdf/pdf_tools.dart';
import '../features/qr/qr_tools.dart';
import '../features/random/random_tools.dart';
import '../features/text/text_tools.dart';
import '../features/video/video_tools.dart';
import '../features/time/time_tools.dart';
import '../remote/remote_apply.dart';
import '../remote/remote_store.dart';
import 'app_info.dart';
import 'platform_now.dart';
import 'platform_rules.dart' show whyNot;
import 'tool.dart';

/// لإضافة مجموعة أدوات جديدة: اعرّفها في ملف الـ feature الخاص بها وأضفها هنا.
final List<Tool> _baseTools = [
  ...balootTools,
  ...calcTools,
  ...converterTools,
  ...currencyTools,
  ...pdfTools,
  ...imageTools,
  ...videoTools,
  ...qrTools,
  ...timeTools,
  ...textTools,
  ...deviceTools,
  ...extrasTools,
  ...moreTools,
  ...mathTools,
  ...arabicTools,
  ...randomTools,
  ...networkTools,
  ...devTools,
  ...lifeTools,
];

List<Tool>? _cachedAll;
List<Tool>? _cachedTools;
Object? _cachedFor;

void _refreshCache() {
  final cfg = RemoteStore.config.value;
  if (_cachedAll == null || !identical(_cachedFor, cfg)) {
    final all = applyToolConfig(_baseTools, cfg, kAppBuild);
    _cachedAll = all;
    _cachedTools = [for (final t in all) if (isToolSupported(t.id)) t];
    _cachedFor = cfg;
  }
}

/// الأدوات بعد تطبيق إعدادات لوحة الإدارة، مع إخفاء ما لا يعمل على هذا الجهاز (انظر platform_rules.dart).
List<Tool> get allTools {
  _refreshCache();
  return _cachedTools!;
}

/// الأدوات المخفية على هذا الجهاز مع سبب كل واحدة.
List<(Tool, String)> get unsupportedTools {
  _refreshCache();
  return [
    for (final t in _cachedAll!)
      if (!isToolSupported(t.id)) (t, whyNot(t.id) ?? 'لا تعمل على هذا الجهاز')
  ];
}
