import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool get offlineSupported => globalContext.has('mtMedia');

extension type _Media._(JSObject _) implements JSObject {
  external JSPromise<JSNumber> prefetch(JSBoolean withModel);
}

Future<void> prefetchEngines({required bool withModel}) async {
  final m = _Media._(globalContext['mtMedia'] as JSObject);
  await m.prefetch(withModel.toJS).toDart;
}
