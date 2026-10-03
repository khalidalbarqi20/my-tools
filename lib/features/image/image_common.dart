import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../pdf/pdf_common.dart' show Picked, pickPicked;

enum OutFmt { jpg, png, webp }

OutFmt fmtFromKey(String? k) =>
    k == 'png' ? OutFmt.png : (k == 'webp' ? OutFmt.webp : OutFmt.jpg);
String extOf(OutFmt f) =>
    f == OutFmt.png ? 'png' : (f == OutFmt.webp ? 'webp' : 'jpg');
String mimeOf(OutFmt f) => f == OutFmt.png
    ? 'image/png'
    : (f == OutFmt.webp ? 'image/webp' : 'image/jpeg');
CompressFormat _cf(OutFmt f) => f == OutFmt.png
    ? CompressFormat.png
    : (f == OutFmt.webp ? CompressFormat.webp : CompressFormat.jpeg);

class ImgDims {
  final int w, h;
  const ImgDims(this.w, this.h);
}

class LoadedImage {
  final Picked file;
  final ImgDims dims;
  const LoadedImage(this.file, this.dims);
}

String imgError(Object e) {
  if (e is FormatException) return e.message;
  if (e is UnsupportedError) {
    return 'هذه الصيغة غير مدعومة على جهازك. جرّب JPG.';
  }
  return 'تعذر معالجة الصورة. تأكد أنها بصيغة JPG أو PNG أو WebP ثم حاول مرة أخرى.';
}

Future<ImgDims> imageSize(Uint8List b) async {
  final buf = await ui.ImmutableBuffer.fromUint8List(b);
  try {
    final d = await ui.ImageDescriptor.encoded(buf);
    final r = ImgDims(d.width, d.height);
    d.dispose();
    return r;
  } finally {
    buf.dispose();
  }
}

Future<ui.Image> decodeUi(Uint8List b, {int? targetW, int? targetH}) async {
  final codec = await ui.instantiateImageCodec(b,
      targetWidth: targetW, targetHeight: targetH);
  try {
    final f = await codec.getNextFrame();
    return f.image;
  } finally {
    codec.dispose();
  }
}

/// يفك الصورة بدقة مخفضة إذا كانت أكبر من 40 ميجابكسل لتجنب انهيار الذاكرة.
Future<ui.Image> decodeCapped(Uint8List b, {int maxPixels = 40000000}) async {
  final s = await imageSize(b);
  final px = s.w * s.h;
  if (px <= maxPixels) return decodeUi(b);
  final k = math.sqrt(maxPixels / px);
  return decodeUi(b,
      targetW: math.max(1, (s.w * k).floor()),
      targetH: math.max(1, (s.h * k).floor()));
}

/// ضغط/تحويل أصلي. maxSide: 0 = بدون تصغير، أو 1280 / 2048.
Future<Uint8List> compressBytes(Uint8List b, OutFmt f, int quality,
    {int maxSide = 0}) {
  final cf = _cf(f);
  if (maxSide == 1280) {
    return FlutterImageCompress.compressWithList(b,
        minWidth: 1280, minHeight: 1280, quality: quality, format: cf);
  }
  if (maxSide == 2048) {
    return FlutterImageCompress.compressWithList(b,
        minWidth: 2048, minHeight: 2048, quality: quality, format: cf);
  }
  return FlutterImageCompress.compressWithList(b,
      minWidth: 100000, minHeight: 100000, quality: quality, format: cf);
}

Future<Uint8List> encodeUi(ui.Image img, OutFmt f, int quality) async {
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  if (bd == null) throw Exception('encode failed');
  final png = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
  if (f == OutFmt.png) return png;
  return compressBytes(png, f, quality);
}

Future<LoadedImage?> pickOneImage() async {
  final fs = await pickPicked(type: FileType.image);
  if (fs.isEmpty) return null;
  final d = await imageSize(fs.first.bytes);
  return LoadedImage(fs.first, d);
}
