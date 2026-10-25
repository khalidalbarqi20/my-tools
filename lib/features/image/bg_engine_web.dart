import 'dart:js_interop';
import 'dart:typed_data';
import 'bg_logic.dart';

/// على الويب (أندرويد/آيفون/ويندوز): النموذج يعمل داخل المتصفح عبر web/mt_bg.js
const bgSupported = true;

@JS('mtRemoveBg')
external JSPromise<JSAny?> _mtRemoveBg(JSUint8Array png);

extension type _BgRes._(JSObject _) implements JSObject {
  external JSNumber get w;
  external JSNumber get h;
  external JSUint8Array get a;
}

const _failMsg =
    'تعذر تحليل الصورة. في أول استخدام يحتاج الجهاز اتصالًا بالإنترنت لتنزيل نموذج إزالة الخلفية (مرة واحدة فقط)، وقد تأخذ المعالجة بضع ثوانٍ.';

/// يحلّل الصورة (PNG) داخل المتصفح ويرجع قناع العنصر الرئيسي (بدقة أقصاها 1024).
Future<BgMask> segmentForeground(Uint8List png, int w, int h) async {
  try {
    final raw = await _mtRemoveBg(png.toJS).toDart;
    if (raw == null) {
      throw const FormatException('لم يتم العثور على عنصر رئيسي واضح في الصورة.');
    }
    final res = _BgRes._(raw as JSObject);
    final mw = res.w.toDartInt, mh = res.h.toDartInt;
    final a = res.a.toDart;
    if (mw <= 0 || mh <= 0 || a.length != mw * mh) {
      throw const FormatException('نتيجة تحليل الصورة غير صالحة.');
    }
    final conf = List<double>.generate(a.length, (i) => a[i] / 255.0);
    return BgMask(mw, mh, conf);
  } on FormatException {
    rethrow;
  } catch (e) {
    var d = '$e';
    if (d.length > 200) d = d.substring(0, 200);
    throw FormatException('$_failMsg\n[$d]');
  }
}
