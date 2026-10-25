import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/statistics.dart';
import 'video_logic.dart';

const engineSupported = true;

String tempPath(String ext) =>
    '${Directory.systemTemp.path}/mt_${DateTime.now().microsecondsSinceEpoch}.$ext';
Future<void> writeBytesTo(String path, Uint8List bytes) =>
    File(path).writeAsBytes(bytes, flush: true);
Future<Uint8List> readBytesFrom(String path) => File(path).readAsBytes();
Future<int> fileSize(String path) => File(path).length();
Future<void> deleteQuiet(String path) async {
  try {
    await File(path).delete();
  } catch (_) {}
}

Future<ProbeInfo> probeMedia(String path) async {
  final session = await FFprobeKit.getMediaInformation(path);
  final info = session.getMediaInformation();
  if (info == null) {
    throw const FormatException('تعذر قراءة الملف. قد يكون تالفًا أو بصيغة غير مدعومة.');
  }
  var hasA = false, hasV = false;
  int? w, h;
  for (final st in info.getStreams()) {
    final type = st.getType();
    if (type == 'audio') hasA = true;
    if (type == 'video' && !hasV) {
      final props = st.getAllProperties();
      final disp = props?['disposition'];
      // صورة الغلاف المرفقة بملفات الصوت ليست فيديو.
      if (disp is Map && '${disp['attached_pic']}' == '1') continue;
      hasV = true;
      w = st.getWidth();
      h = st.getHeight();
      if (w != null && h != null && swapsDims(rotationOf(props))) {
        final t = w;
        w = h;
        h = t;
      }
    }
  }
  return ProbeInfo(
    duration: double.tryParse(info.getDuration() ?? ''),
    hasAudio: hasA,
    hasVideo: hasV,
    width: w,
    height: h,
  );
}

Future<void> runFfmpeg(List<String> args,
    {double? totalSec, void Function(double)? onProgress}) {
  final done = Completer<void>();
  FFmpegKit.executeWithArgumentsAsync(
    args,
    (session) async {
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        done.complete();
      } else if (ReturnCode.isCancel(rc)) {
        done.completeError(const FormatException('تم الإلغاء'));
      } else {
        final logs = (await session.getAllLogsAsString() ?? '').trim().split('\n');
        final tail = logs.length > 3 ? logs.sublist(logs.length - 3) : logs;
        done.completeError(FormatException('فشلت المعالجة.\n${tail.join('\n')}'));
      }
    },
    null,
    (Statistics st) {
      final t = totalSec;
      if (onProgress != null && t != null && t > 0) {
        onProgress((st.getTime().toDouble() / 1000 / t).clamp(0.0, 1.0));
      }
    },
  );
  return done.future;
}

void cancelFfmpeg() {
  FFmpegKit.cancel();
}

// دوال خاصة بالويب (غير مستخدمة خارجه).
Future<(String, String)?> webPick(String kind) async => null;
Future<bool> webSave(String path, String name, String mime) async => false;
Future<bool> webShare(String path, String name, String mime) async => false;
void webPreview(String path, String mime) {}
