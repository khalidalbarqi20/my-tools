import '../features/calculator/calc_tools.dart';
import '../features/converters/converter_tools.dart';
import '../features/image/image_tools.dart';
import '../features/pdf/pdf_tools.dart';
import '../features/qr/qr_tools.dart';
import '../features/text/text_tools.dart';
import '../features/time/time_tools.dart';
import 'tool.dart';

/// لإضافة مجموعة أدوات جديدة: اعرّفها في ملف الـ feature الخاص بها وأضفها هنا.
final List<Tool> allTools = [
  ...calcTools,
  ...converterTools,
  ...pdfTools,
  ...imageTools,
  ...qrTools,
  ...timeTools,
  ...textTools,
];
