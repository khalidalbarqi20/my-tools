import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

extension type _Media._(JSObject _) implements JSObject {
  external JSPromise<JSUint8Array> deflateRaw(JSUint8Array b);
  external JSPromise<JSUint8Array> inflateRaw(JSUint8Array b);
}

_Media get _m => _Media._(globalContext['mtMedia'] as JSObject);

Future<Uint8List> deflateRaw(Uint8List b) async {
  if (!globalContext.has('mtMedia')) return b;
  return (await _m.deflateRaw(b.toJS).toDart).toDart;
}

Future<Uint8List> inflateRaw(Uint8List b) async =>
    (await _m.inflateRaw(b.toJS).toDart).toDart;
