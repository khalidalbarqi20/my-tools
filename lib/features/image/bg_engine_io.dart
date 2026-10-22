import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_commons/google_mlkit_commons.dart' show InputImage;
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'bg_logic.dart';

const bgSupported = true;

const _modelMsg =
    'تعذر تحليل الصورة. في أول استخدام يحتاج الجهاز اتصالًا بالإنترنت لتنزيل نموذج إزالة الخلفية (مرة واحدة فقط)، ويتطلب خدمات Google Play.';

dynamic _field(dynamic Function() f) {
  try {
    return f();
  } catch (_) {
    return null;
  }
}

/// يحلّل الصورة (PNG) على الجهاز ويرجع قناع العنصر الرئيسي بنفس أبعادها.
Future<BgMask> segmentForeground(Uint8List png, int w, int h) async {
  final path =
      '${Directory.systemTemp.path}/mt_bg_${DateTime.now().microsecondsSinceEpoch}.png';
  final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
          enableForegroundBitmap: false,
          enableForegroundConfidenceMask: true,
          enableMultipleSubjects: SubjectResultOptions(
              enableConfidenceMask: false, enableSubjectBitmap: false)));
  try {
    await File(path).writeAsBytes(png, flush: true);
    final dynamic r =
        await segmenter.processImage(InputImage.fromFilePath(path));
    final raw = _field(() => r.foregroundConfidenceMask) ??
        _field(() => r.confidences) ??
        _field(() => r.confidenceMask);
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('لم يتم العثور على عنصر رئيسي واضح في الصورة.');
    }
    final List<double> conf =
        raw is List<double> ? raw : [for (final v in raw) (v as num).toDouble()];
    final rw = _field(() => r.width), rh = _field(() => r.height);
    if (rw is int && rh is int && rw * rh == conf.length) {
      return BgMask(rw, rh, conf);
    }
    return BgMask(w, h, conf);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException(_modelMsg);
  } finally {
    try {
      await segmenter.close();
    } catch (_) {}
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
