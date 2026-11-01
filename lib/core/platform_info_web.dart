import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool _detect() {
  try {
    final nav = globalContext['navigator'] as JSObject;
    final ua = (nav['userAgent'] as JSString).toDart;
    if (RegExp(r'iPhone|iPad|iPod').hasMatch(ua)) return true;
    // آيباد حديث يعرّف نفسه كـ Mac لكنه يدعم اللمس المتعدد.
    final tp = (nav['maxTouchPoints'] as JSNumber?)?.toDartInt ?? 0;
    return ua.contains('Macintosh') && tp > 1;
  } catch (_) {
    return false;
  }
}

final bool _ios = _detect();
bool get isIosWeb => _ios;

bool _standaloneNow() {
  try {
    final nav = globalContext['navigator'] as JSObject;
    if ((nav['standalone'] as JSBoolean?)?.toDart == true) return true;
    final mm = globalContext.callMethod(
        'matchMedia'.toJS, '(display-mode: standalone)'.toJS) as JSObject;
    return (mm['matches'] as JSBoolean?)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// هل الصفحة مفتوحة كتطبيق مثبّت (من الشاشة الرئيسية) وليست داخل المتصفح؟
bool get isStandalone => _standaloneNow();
