import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../image/image_common.dart';
import '../image/image_logic.dart';

Future<ui.Image> _rotate(ui.Image src, int turns) async {
  final t = turns % 4;
  if (t == 0) return src;
  final swap = t.isOdd;
  final ow = swap ? src.height : src.width;
  final oh = swap ? src.width : src.height;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  canvas.translate(ow / 2, oh / 2);
  canvas.rotate(t * math.pi / 2);
  canvas.translate(-src.width / 2, -src.height / 2);
  canvas.drawImage(src, ui.Offset.zero, ui.Paint());
  final pic = rec.endRecording();
  final out = await pic.toImage(ow, oh);
  pic.dispose();
  return out;
}

/// يجهز الصورة لقراءة الرمز: تدوير، قص، عكس ألوان اختياري، تكبير القصاصات
/// الصغيرة، وهامش أبيض حول الرمز (المنطقة الهادئة التي تحتاجها القارئات).
Future<Uint8List> prepareForDecode(
  Uint8List bytes, {
  required double l,
  required double t,
  required double r,
  required double b,
  int turns = 0,
  bool invert = false,
}) async {
  final src = await decodeCapped(bytes, maxPixels: 16000000);
  ui.Image? rot;
  try {
    rot = await _rotate(src, turns);
    final (x, y, cw, ch) = cropRect(rot.width, rot.height, l, t, r, b);
    final longest = math.max(cw, ch);
    final k = longest >= 800 ? 1 : (800 / longest).ceil().clamp(1, 6).toInt();
    final pad = (longest * k * 0.12).round();
    final ow = cw * k + pad * 2;
    final oh = ch * k + pad * 2;
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, ow.toDouble(), oh.toDouble()),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    final paint = ui.Paint()
      ..filterQuality = k > 1 ? ui.FilterQuality.none : ui.FilterQuality.high;
    if (invert) {
      paint.colorFilter = ui.ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0,
      ]);
    }
    canvas.drawImageRect(
      rot,
      ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), cw.toDouble(), ch.toDouble()),
      ui.Rect.fromLTWH(
          pad.toDouble(), pad.toDouble(), (cw * k).toDouble(), (ch * k).toDouble()),
      paint,
    );
    final pic = rec.endRecording();
    final out = await pic.toImage(ow, oh);
    pic.dispose();
    try {
      return await encodeUi(out, OutFmt.png, 90);
    } finally {
      out.dispose();
    }
  } finally {
    if (rot != null && !identical(rot, src)) rot.dispose();
    src.dispose();
  }
}
