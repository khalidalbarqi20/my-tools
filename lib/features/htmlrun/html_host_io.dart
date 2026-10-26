import 'dart:convert';
import 'dart:io';
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
  final name = f.name;
  final low = name.toLowerCase();
  final zip = low.endsWith('.zip');
  if (!zip && !low.endsWith('.html') && !low.endsWith('.htm')) {
    throw const FormatException('اختر ملف HTML أو مشروع ZIP.');
  }
  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final dir = Directory('${_root().path}/$id');
  await dir.create(recursive: true);
  String entry;
  try {
    if (zip) {
      entry = await extractZip(File(p), dir);
    } else {
      entry = 'index.html';
      await File(p).copy('${dir.path}/index.html');
    }
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
