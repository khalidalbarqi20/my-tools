import 'dart:typed_data';
import 'bg_logic.dart';

const bgSupported = false;

Future<BgMask> segmentForeground(Uint8List png, int w, int h) async =>
    throw const FormatException('إزالة الخلفية تعمل في تطبيق الأندرويد فقط.');
