// على الويب لا يوجد FFmpeg، فنستخدم نسخة بديلة تعطي رسالة واضحة.
export 'video_engine_stub.dart' if (dart.library.io) 'video_engine_io.dart';
