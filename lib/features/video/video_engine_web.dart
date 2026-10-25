import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'video_logic.dart';

/// على الويب: المحرك هو web/mt_media.js (Mediabunny ثم ffmpeg.wasm احتياطيًا).
bool get engineSupported => globalContext.has('mtMedia');

extension type _Media._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> pick(JSString kind);
  external void put(JSString path, JSUint8Array bytes);
  external JSPromise<JSNumber> size(JSString path);
  external JSPromise<JSUint8Array> read(JSString path);
  external void del(JSString path);
  external JSPromise<JSAny?> probe(JSString path);
  external JSPromise<JSAny?> run(JSArray<JSString> args, JSFunction? onProgress);
  external void cancel();
  external JSPromise<JSBoolean> save(JSString path, JSString name, JSString mime);
  external JSPromise<JSBoolean> share(JSString path, JSString name, JSString mime);
  external void preview(JSString path, JSString mime);
}

extension type _Picked._(JSObject _) implements JSObject {
  external JSString get path;
  external JSString get name;
}

extension type _Probe._(JSObject _) implements JSObject {
  external JSNumber get duration;
  external JSBoolean get hasAudio;
  external JSBoolean get hasVideo;
  external JSNumber get width;
  external JSNumber get height;
}

_Media get _m => _Media._(globalContext['mtMedia'] as JSObject);

String _msg(Object e) {
  var s = '$e';
  s = s.replaceFirst(RegExp(r'^(Exception|Error|FormatException): '), '');
  return s.length > 300 ? s.substring(0, 300) : s;
}

int _seq = 0;
String tempPath(String ext) =>
    '/tmp/mt_${DateTime.now().microsecondsSinceEpoch}_${_seq++}.$ext';

Future<void> writeBytesTo(String path, Uint8List bytes) async =>
    _m.put(path.toJS, bytes.toJS);

Future<Uint8List> readBytesFrom(String path) async =>
    (await _m.read(path.toJS).toDart).toDart;

Future<int> fileSize(String path) async =>
    (await _m.size(path.toJS).toDart).toDartInt;

Future<void> deleteQuiet(String path) async {
  try {
    _m.del(path.toJS);
  } catch (_) {}
}

Future<ProbeInfo> probeMedia(String path) async {
  try {
    final r = _Probe._((await _m.probe(path.toJS).toDart)! as JSObject);
    final d = r.duration.toDartDouble;
    final w = r.width.toDartInt, h = r.height.toDartInt;
    return ProbeInfo(
      duration: d > 0 ? d : null,
      hasAudio: r.hasAudio.toDart,
      hasVideo: r.hasVideo.toDart,
      width: w > 0 ? w : null,
      height: h > 0 ? h : null,
    );
  } catch (e) {
    throw FormatException(_msg(e));
  }
}

Future<void> runFfmpeg(List<String> args,
    {double? totalSec, void Function(double)? onProgress}) async {
  try {
    final cb = onProgress == null
        ? null
        : ((JSNumber v) => onProgress(v.toDartDouble)).toJS;
    await _m.run([for (final a in args) a.toJS].toJS, cb).toDart;
  } catch (e) {
    throw FormatException(_msg(e));
  }
}

void cancelFfmpeg() {
  try {
    _m.cancel();
  } catch (_) {}
}

/// اختيار ملف عبر المتصفح مباشرة (بدون نسخ الملف كاملًا إلى الذاكرة).
Future<(String, String)?> webPick(String kind) async {
  final r = await _m.pick(kind.toJS).toDart;
  if (r == null) return null;
  final p = _Picked._(r as JSObject);
  return (p.path.toDart, p.name.toDart);
}

Future<bool> webSave(String path, String name, String mime) async =>
    (await _m.save(path.toJS, name.toJS, mime.toJS).toDart).toDart;

Future<bool> webShare(String path, String name, String mime) async =>
    (await _m.share(path.toJS, name.toJS, mime.toJS).toDart).toDart;

void webPreview(String path, String mime) => _m.preview(path.toJS, mime.toJS);
