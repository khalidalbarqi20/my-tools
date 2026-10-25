// أندرويد: FFmpegKit. ويب: Mediabunny + ffmpeg.wasm (web/mt_media.js).
export 'video_engine_stub.dart'
    if (dart.library.js_interop) 'video_engine_web.dart'
    if (dart.library.io) 'video_engine_io.dart';
