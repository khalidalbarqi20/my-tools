import '../features/calculator/calc_tools.dart';
import '../features/converters/converter_tools.dart';
import '../features/currency/currency_tools.dart';
import '../features/device/device_tools.dart';
import '../features/extras/extras_tools.dart';
import '../features/more/more_tools.dart';
import '../features/image/image_tools.dart';
import '../features/pdf/pdf_tools.dart';
import '../features/qr/qr_tools.dart';
import '../features/random/random_tools.dart';
import '../features/text/text_tools.dart';
import '../features/time/time_tools.dart';
import '../remote/remote_apply.dart';
import '../remote/remote_store.dart';
import 'app_info.dart';
import 'tool.dart';

/// لإضافة مجموعة أدوات جديدة: اعرّفها في ملف الـ feature الخاص بها وأضفها هنا.
final List<Tool> _baseTools = [
  ...calcTools,
  ...converterTools,
  ...currencyTools,
  ...pdfTools,
  ...imageTools,
  ...qrTools,
  ...timeTools,
  ...textTools,
  ...deviceTools,
  ...extrasTools,
  ...moreTools,
  ...randomTools,
];

List<Tool>? _cachedTools;
Object? _cachedFor;

/// الأدوات بعد تطبيق إعدادات لوحة الإدارة (أو الأصلية إن لم توجد).
List<Tool> get allTools {
  final cfg = RemoteStore.config.value;
  if (_cachedTools == null || !identical(_cachedFor, cfg)) {
    _cachedTools = applyToolConfig(_baseTools, cfg, kAppBuild);
    _cachedFor = cfg;
  }
  return _cachedTools!;
}
