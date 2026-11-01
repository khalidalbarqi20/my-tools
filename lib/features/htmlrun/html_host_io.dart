import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../storage/app_dir.dart';
import 'html_model.dart';
import 'html_zip.dart';

bool get hostSupported => true;

Directory _root() => Directory('${appDataDir()}/mt_html');
File _index() => File('${_root().path}/index.json');

Future<List<HtmlApp>> _readAll() async {
  try {
    final f = _index();
    if (!await f.exists()) return [];
    final l = jsonDecode(await f.readAsString()) as List<dynamic>;
    return [for (final m in l) HtmlApp.fromJson(m as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

Future<void> _writeAll(List<HtmlApp> l) async {
  await _root().create(recursive: true);
  await _index().writeAsString(jsonEncode([for (final a in l) a.toJson()]));
}

Future<List<HtmlApp>> hostList() async {
  final l = await _readAll();
  l.sort((a, b) => b.ts - a.ts);
  return l;
}

Future<HtmlApp?> hostAdd() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  if (files.isEmpty) return null;
  final f = files.first;
  final p = f.path;
  if (p == null) throw const FormatException('تعذر الوصول إلى الملف');
  final low = f.name.toLowerCase();
  final zip = low.endsWith('.zip');
  if (!zip && !low.endsWith('.html') && !low.endsWith('.htm')) {
    throw const FormatException('اختر ملف HTML أو مشروع ZIP.');
  }
  return _install(f.name, p, zip);
}

Future<HtmlApp?> hostAddBytes(String name, Uint8List bytes, {required bool zip}) async {
  final tmp = File('${Directory.systemTemp.path}/mt_in_${DateTime.now().microsecondsSinceEpoch}.${zip ? 'zip' : 'html'}');
  await tmp.writeAsBytes(bytes);
  try {
    return await _install(name, tmp.path, zip);
  } finally {
    try {
      await tmp.delete();
    } catch (_) {}
  }
}

Future<Uint8List?> hostReadBytes(String id) async {
  try {
    final src = File('${_root().path}/$id.src');
    if (await src.exists()) return await src.readAsBytes();
    final all = await _readAll();
    for (final a in all) {
      if (a.id == id && !a.zip) {
        return await File('${_root().path}/$id/${a.entry}').readAsBytes();
      }
    }
  } catch (_) {}
  return null;
}

Future<HtmlApp> _install(String name, String path, bool zip) async {
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final dir = Directory('${_root().path}/$id');
  await dir.create(recursive: true);
  String entry;
  try {
    if (zip) {
      entry = await extractZip(File(path), dir);
    } else {
      entry = 'index.html';
      await File(path).copy('${dir.path}/index.html');
    }
    await File(path).copy('${_root().path}/$id.src');
  } catch (_) {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
    rethrow;
  }
  final app = HtmlApp(
    id: id,
    name: name.replaceFirst(RegExp(r'\.(html?|zip)$', caseSensitive: false), ''),
    zip: zip,
    ts: DateTime.now().millisecondsSinceEpoch,
    entry: entry,
  );
  final all = await _readAll();
  await _writeAll([...all, app]);
  return app;
}

Future<void> hostDelete(String id) async {
  try {
    await Directory('${_root().path}/$id').delete(recursive: true);
  } catch (_) {}
  try {
    await File('${_root().path}/$id.src').delete();
  } catch (_) {}
  final all = await _readAll();
  await _writeAll([for (final a in all) if (a.id != id) a]);
}

Widget hostView(HtmlApp app) => _IoView(key: ValueKey(app.id), app: app);

class _IoView extends StatefulWidget {
  final HtmlApp app;
  const _IoView({super.key, required this.app});
  @override
  State<_IoView> createState() => _IoViewState();
}

class _IoViewState extends State<_IoView> {
  late final WebViewController _c = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  void initState() {
    super.initState();
    _c.loadFile('${_root().path}/${widget.app.id}/${widget.app.entry}');
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}
