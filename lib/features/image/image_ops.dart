import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../core/num_parse.dart';
import '../pdf/pdf_common.dart' show OutFile, Picked, baseName;
import 'image_common.dart';
import 'image_logic.dart';

Future<OutFile> compressOne(Picked p, Map<String, String> o) async {
  final q = int.tryParse(o['q'] ?? '') ?? 70;
  final side = int.tryParse(o['side'] ?? '') ?? 0;
  final f = fmtFromKey(o['fmt']);
  final out = await compressBytes(p.bytes, f, q, maxSide: side);
  return OutFile('${baseName(p.name)}_compressed.${extOf(f)}', out, mimeOf(f));
}

Future<OutFile> convertOne(Picked p, Map<String, String> o) async {
  final f = fmtFromKey(o['fmt']);
  final out = await compressBytes(p.bytes, f, 90);
  return OutFile('${baseName(p.name)}.${extOf(f)}', out, mimeOf(f));
}

Future<OutFile> resizeOne(Picked p, Map<String, String> o) async {
  final tw = parseNum(o['w'] ?? '')?.round();
  final th = parseNum(o['h'] ?? '')?.round();
  final s = await imageSize(p.bytes);
  final (nw, nh) = resizeDims(s.w, s.h, tw, th, keep: o['keep'] != 'false');
  final f = fmtFromKey(o['fmt']);
  final img = await decodeUi(p.bytes, targetW: nw, targetH: nh);
  try {
    final data = await encodeUi(img, f, 90);
    return OutFile('${baseName(p.name)}_${nw}x$nh.${extOf(f)}', data, mimeOf(f));
  } finally {
    img.dispose();
  }
}

Future<Uint8List> cropEncode(Uint8List bytes, double l, double t, double r,
    double b, OutFmt f, int q) async {
  final src = await decodeCapped(bytes);
  try {
    final (x, y, cw, ch) = cropRect(src.width, src.height, l, t, r, b);
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.drawImageRect(
      src,
      ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), cw.toDouble(), ch.toDouble()),
      ui.Rect.fromLTWH(0, 0, cw.toDouble(), ch.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final pic = rec.endRecording();
    final out = await pic.toImage(cw, ch);
    pic.dispose();
    try {
      return await encodeUi(out, f, q);
    } finally {
      out.dispose();
    }
  } finally {
    src.dispose();
  }
}

/// القلب يُطبق أولًا ثم التدوير باتجاه عقارب الساعة (turns × 90°).
Future<Uint8List> transformEncode(Uint8List bytes, int turns, bool flipH,
    bool flipV, OutFmt f, int q) async {
  final src = await decodeCapped(bytes);
  try {
    final t = turns % 4;
    final sw = src.width.toDouble(), sh = src.height.toDouble();
    final swap = t.isOdd;
    final ow = swap ? src.height : src.width;
    final oh = swap ? src.width : src.height;
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    canvas.translate(ow / 2, oh / 2);
    canvas.rotate(t * math.pi / 2);
    canvas.scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0);
    canvas.translate(-sw / 2, -sh / 2);
    canvas.drawImage(src, ui.Offset.zero,
        ui.Paint()..filterQuality = ui.FilterQuality.high);
    final pic = rec.endRecording();
    final out = await pic.toImage(ow, oh);
    pic.dispose();
    try {
      return await encodeUi(out, f, q);
    } finally {
      out.dispose();
    }
  } finally {
    src.dispose();
  }
}

Future<List<PaletteColor>> paletteOf(Uint8List bytes, {int count = 6}) async {
  final s = await imageSize(bytes);
  final k = 64 / math.max(s.w, s.h);
  final img = await decodeUi(bytes,
      targetW: math.max(1, (s.w * k).round()),
      targetH: math.max(1, (s.h * k).round()));
  try {
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return [];
    return extractPalette(
        bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes),
        count: count);
  } finally {
    img.dispose();
  }
}
