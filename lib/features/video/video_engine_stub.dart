import 'dart:typed_data';
import 'video_logic.dart';

const engineSupported = false;

Never _no() => throw const FormatException('أدوات الفيديو والصوت تعمل في تطبيق الأندرويد فقط.');

Future<ProbeInfo> probeMedia(String path) async => _no();
Future<void> runFfmpeg(List<String> args,
        {double? totalSec, void Function(double)? onProgress}) async =>
    _no();
void cancelFfmpeg() {}
String tempPath(String ext) => _no();
Future<void> writeBytesTo(String path, Uint8List bytes) async => _no();
Future<Uint8List> readBytesFrom(String path) async => _no();
Future<int> fileSize(String path) async => _no();
Future<void> deleteQuiet(String path) async {}

// دوال خاصة بالويب (غير مستخدمة خارجه).
Future<(String, String)?> webPick(String kind) async => null;
Future<bool> webSave(String path, String name, String mime) async => false;
Future<bool> webShare(String path, String name, String mime) async => false;
void webPreview(String path, String mime) {}

// حفظ دائم لنتائج العمليات (سجل «عملياتي السابقة»).
Future<String> persistOutput(String path, String id) async => path;
Future<bool> restoreOutput(String path, String id) async => true;
Future<void> deletePersisted(String path, String id) async {}
