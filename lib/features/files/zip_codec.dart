// ضغط/فك deflate الخام: dart:io على أندرويد/آيفون، وCompressionStream في المتصفح.
export 'zip_codec_stub.dart'
    if (dart.library.js_interop) 'zip_codec_web.dart'
    if (dart.library.io) 'zip_codec_io.dart';
