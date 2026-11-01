import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, pickPicked, saveOut, shareOut;
import 'html_editor_page.dart';
import 'html_host.dart';
import 'html_model.dart';

String _two(int n) => n < 10 ? '0$n' : '$n';
String _when(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}/${_two(d.month)}/${_two(d.day)}  ${_two(d.hour)}:${_two(d.minute)}';
}

/// تشغيل صفحة HTML أو مشروع كامل (ZIP). الملفات تُحفظ على تخزين الجهاز، وبيانات الصفحة نفسها تُحفظ في تخزين المتصفح المدمج.
class HtmlRunnerPage extends StatefulWidget {
  const HtmlRunnerPage({super.key});
  @override
  State<HtmlRunnerPage> createState() => _HtmlRunnerPageState();
}

class _HtmlRunnerPageState extends State<HtmlRunnerPage> {
  List<HtmlApp> _apps = [];
  bool _loading = true, _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final l = await hostList();
    if (mounted) {
      setState(() {
        _apps = l;
        _loading = false;
      });
    }
  }

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final a = await hostAdd();
      if (a != null) {
        await _reload();
        if (mounted) _open(a);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _err = e is FormatException ? e.message : 'تعذر فتح الملف.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(HtmlApp a) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HtmlViewerPage(app: a)));
  }

  Future<void> _edit(HtmlApp a) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => HtmlEditorPage(app: a)));
    await _reload();
  }

  Future<void> _delete(HtmlApp a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('حذف «${a.name}»؟'),
        content: const Text('يُحذف الملف المحفوظ على الجهاز.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      await hostDelete(a.id);
      await _reload();
    }
  }

  Future<OutFile?> _fileOf(HtmlApp a) async {
    final b = await hostReadBytes(a.id);
    if (b == null) return null;
    return OutFile(
        '${a.name}.${a.zip ? 'zip' : 'html'}', b, a.zip ? 'application/zip' : 'text/html');
  }

  Future<void> _export(HtmlApp a, {required bool share}) async {
    final f = await _fileOf(a);
    if (f == null) {
      _snack('ما لقيت الملف الأصلي لهذا العنصر (أُضيف قبل ميزة النسخ).');
      return;
    }
    if (!mounted) return;
    if (share) {
      await shareOut(context, [f]);
    } else {
      await saveOut(context, f);
    }
  }

  Future<void> _backup() async {
    final items = <Map<String, dynamic>>[];
    var skipped = 0;
    for (final a in _apps) {
      final b = await hostReadBytes(a.id);
      if (b == null) {
        skipped++;
        continue;
      }
      items.add({'name': a.name, 'zip': a.zip, 'data': base64.encode(b)});
    }
    if (items.isEmpty) {
      _snack('ما فيه شيء يُنسخ احتياطيًا.');
      return;
    }
    final json = utf8.encode(jsonEncode({'v': 1, 'apps': items}));
    if (!mounted) return;
    await saveOut(context,
        OutFile('my_tools_pages_backup.json', Uint8List.fromList(json), 'application/json'));
    if (skipped > 0) _snack('تخطّيت $skipped عنصرًا أُضيف قبل ميزة النسخ.');
  }

  Future<void> _restore() async {
    try {
      final fs = await pickPicked(type: FileType.any);
      if (fs.isEmpty) return;
      final m = jsonDecode(utf8.decode(fs.first.bytes)) as Map<String, dynamic>;
      final list = m['apps'] as List<dynamic>;
      var n = 0;
      for (final x in list) {
        final e = x as Map<String, dynamic>;
        final a = await hostAddBytes('${e['name']}', Uint8List.fromList(base64.decode('${e['data']}')),
            zip: e['zip'] == true);
        if (a != null) n++;
      }
      await _reload();
      _snack('تم استرجاع $n عنصر');
    } catch (_) {
      _snack('ملف النسخة الاحتياطية غير صالح.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشغيل صفحة HTML'),
        actions: [
          if (hostSupported)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'backup') _backup();
                if (v == 'restore') _restore();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'backup', child: Text('حفظ نسخة احتياطية')),
                PopupMenuItem(value: 'restore', child: Text('استرجاع من نسخة')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!hostSupported)
            Text('هذه الأداة غير مدعومة على هذا الجهاز.',
                style: TextStyle(color: t.colorScheme.error))
          else ...[
            FilledButton.icon(
              onPressed: _busy ? null : _add,
              icon: const Icon(Icons.upload_file),
              label: const Text('إضافة ملف HTML أو مشروع ZIP'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const HtmlEditorPage()));
                await _reload();
              },
              icon: const Icon(Icons.code),
              label: const Text('كتابة صفحة بالمحرر'),
            ),
            if (_busy)
              const Padding(
                  padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
              ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_apps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('ما أضفت صفحات بعد.',
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              )
            else
              for (final a in _apps)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(a.zip ? Icons.folder_zip_outlined : Icons.html),
                    title: Text(a.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${a.zip ? 'مشروع ZIP' : 'صفحة HTML'} • ${_when(a.ts)}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _edit(a);
                        if (v == 'share') _export(a, share: true);
                        if (v == 'save') _export(a, share: false);
                        if (v == 'del') _delete(a);
                      },
                      itemBuilder: (_) => [
                        if (!a.zip) const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        const PopupMenuItem(value: 'share', child: Text('مشاركة كملف')),
                        const PopupMenuItem(value: 'save', child: Text('حفظ كملف')),
                        const PopupMenuItem(value: 'del', child: Text('حذف')),
                      ],
                    ),
                    onTap: () => _open(a),
                  ),
                ),
            const SizedBox(height: 12),
            Text(
                'الملف أو المشروع يُحفظ على تخزين جهازك، وما تضيفه داخل الصفحة نفسها يبقى محفوظًا في جهازك أيضًا. للمشاريع ZIP يلزم ملف index.html (أو أي ملف HTML واحد على الأقل). ربط الصفحات بقاعدة بيانات نضيفه لاحقًا.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class HtmlViewerPage extends StatelessWidget {
  final HtmlApp app;
  const HtmlViewerPage({super.key, required this.app});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(app.name, overflow: TextOverflow.ellipsis)),
        body: SafeArea(top: false, child: hostView(app)),
      );
}
