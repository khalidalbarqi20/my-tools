import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../pdf/pdf_common.dart' show OutFile, Picked, baseName;
import 'bg_engine.dart';
import 'bg_logic.dart';
import 'image_common.dart';

Future<ui.Image> _fromRgba(Uint8List px, int w, int h) {
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, w, h, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}

/// إزالة خلفية صورة واحدة. الناتج PNG (شفاف أو بلون خلفية مختار).
Future<OutFile> removeBgOne(Picked p, Map<String, String> o) async {
  if (!bgSupported) {
    throw const FormatException('إزالة الخلفية تعمل في تطبيق الأندرويد فقط.');
  }
  final soft = o['edge'] != 'hard';
  final int? bg = switch (o['bg']) {
    'white' => 0xFFFFFF,
    'black' => 0x000000,
    _ => null,
  };
  final src = await decodeCapped(p.bytes, maxPixels: 12000000);
  try {
    // نمرّر للنموذج نسخة PNG من نفس البكسلات المفكوكة لضمان تطابق الأبعاد والاتجاه.
    final png = await encodeUi(src, OutFmt.png, 100);
    final mask = await segmentForeground(png, src.width, src.height);
    final bd = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) throw const FormatException('تعذر قراءة الصورة.');
    final rgba = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    final out = applyForegroundMask(rgba, src.width, src.height, mask,
        soft: soft, bg: bg);
    final img = await _fromRgba(out, src.width, src.height);
    try {
      final data = await encodeUi(img, OutFmt.png, 100);
      return OutFile('${baseName(p.name)}_nobg.png', data, 'image/png');
    } finally {
      img.dispose();
    }
  } finally {
    src.dispose();
  }
}
