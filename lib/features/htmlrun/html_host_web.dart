import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'html_model.dart';

bool get hostSupported => globalContext.has('mtHtml');

extension type _Html._(JSObject _) implements JSObject {
  external JSPromise<JSString> listJson();
  external JSPromise<JSString?> add();
  external JSPromise<JSString> addBytes(JSString name, JSUint8Array bytes, JSBoolean zip);
  external JSPromise<JSUint8Array?> readBytes(JSString id);
  external JSPromise<JSAny?> del(JSString id);
  external JSObject view(JSString id);
  external void release(JSObject el);
}

_Html get _h => _Html._(globalContext['mtHtml'] as JSObject);

String _msg(Object e) {
  var s = '$e';
  s = s.replaceFirst(RegExp(r'^(Exception|Error|FormatException): '), '');
  return s.length > 300 ? s.substring(0, 300) : s;
}

Future<List<HtmlApp>> hostList() async {
  try {
    final s = (await _h.listJson().toDart).toDart;
    final l = jsonDecode(s) as List<dynamic>;
    return [for (final m in l) HtmlApp.fromJson(m as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

Future<HtmlApp?> hostAdd() async {
  try {
    final r = await _h.add().toDart;
    if (r == null) return null;
    return HtmlApp.fromJson(jsonDecode(r.toDart) as Map<String, dynamic>);
  } catch (e) {
    throw FormatException(_msg(e));
  }
}

Future<HtmlApp?> hostAddBytes(String name, Uint8List bytes, {required bool zip}) async {
  try {
    final r = await _h.addBytes(name.toJS, bytes.toJS, zip.toJS).toDart;
    return HtmlApp.fromJson(jsonDecode(r.toDart) as Map<String, dynamic>);
  } catch (e) {
    throw FormatException(_msg(e));
  }
}

Future<Uint8List?> hostReadBytes(String id) async {
  try {
    final r = await _h.readBytes(id.toJS).toDart;
    return r?.toDart;
  } catch (_) {
    return null;
  }
}

Future<void> hostDelete(String id) async {
  await _h.del(id.toJS).toDart;
}

Widget hostView(HtmlApp app) => _WebFrame(key: ValueKey(app.id), app: app);

int _n = 0;

class _WebFrame extends StatefulWidget {
  final HtmlApp app;
  const _WebFrame({super.key, required this.app});
  @override
  State<_WebFrame> createState() => _WebFrameState();
}

class _WebFrameState extends State<_WebFrame> {
  late final String _type = 'mt-html-${_n++}';
  late final JSObject _el = _h.view(widget.app.id.toJS);

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_type, (int viewId) => _el);
  }

  @override
  void dispose() {
    try {
      _h.release(_el);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _type);
}
