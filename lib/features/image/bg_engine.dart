// ML Kit على الأندرويد (تطبيق)، ونموذج يعمل داخل المتصفح على الويب (انظر web/mt_bg.js).
export 'bg_engine_stub.dart'
    if (dart.library.js_interop) 'bg_engine_web.dart'
    if (dart.library.io) 'bg_engine_io.dart';
