// ويب: iframe + IndexedDB (mtHtml في mt_media.js). أندرويد/آيفون: WebView + ملفات على الجهاز.
export 'html_host_stub.dart'
    if (dart.library.js_interop) 'html_host_web.dart'
    if (dart.library.io) 'html_host_io.dart';
