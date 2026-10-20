import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

final _arabic = RegExp(r'[\u0600-\u06FF]');

/// يرسم النص (يدعم العربية) على صورة PNG شفافة بحجم الفيديو بالضبط.
/// نرسمه بمحرك فلاتر لأن تشكيل الحروف العربية فيه سليم، ثم يُلصق بـ FFmpeg فوق الفيديو.
Future<Uint8List> renderTextOverlay({
  required String text,
  required int w,
  required int h,
  required String pos, // top | middle | bottom
  required String size, // small | medium | large
  required String color, // white | yellow | black
  required bool box,
}) async {
  final base = (w < h ? w : h).toDouble();
  final fs = base * (size == 'small' ? 0.05 : (size == 'large' ? 0.11 : 0.075));
  final fg = switch (color) {
    'yellow' => const Color(0xFFFFEB3B),
    'black' => const Color(0xFF000000),
    _ => const Color(0xFFFFFFFF),
  };
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: fs,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.25),
    ),
    textAlign: TextAlign.center,
    textDirection: _arabic.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr,
  )..layout(maxWidth: w * 0.88);

  final x = (w - tp.width) / 2;
  final y = switch (pos) {
    'top' => h * 0.07,
    'middle' => (h - tp.height) / 2,
    _ => h - tp.height - h * 0.09,
  };

  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  if (box) {
    final pad = fs * 0.45;
    final bg = color == 'black' ? const Color(0xA6FFFFFF) : const Color(0x8C000000);
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(x - pad, y - pad * 0.6, tp.width + pad * 2, tp.height + pad * 1.2),
        Radius.circular(pad),
      ),
      ui.Paint()..color = bg,
    );
  }
  tp.paint(c, ui.Offset(x, y));
  final img = await rec.endRecording().toImage(w, h);
  try {
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('encode failed');
    return data.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}
