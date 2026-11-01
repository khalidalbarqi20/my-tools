import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, humanSize, pickPicked, saveOut, shareOut;
import 'zip_core.dart';

const _maxTotal = 300 * 1024 * 1024;
const _maxEntry = 200 * 1024 * 1024;

class ZipPage extends StatefulWidget {
  const ZipPage({super.key});
  @override
  State<ZipPage> createState() => _ZipPageState();
}

class _ZipPageState extends State<ZipPage> {
  bool _compress = true, _busy = false;
  String? _e;
  final List<ZipIn> _files = [];
  final _name = TextEditingController(text: 'archive');
  // فك الضغط
  Uint8List? _zip;
  String _zipName = '';
  List<ZipEntry> _entries = [];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _total => _files.fold(0, (s, f) => s + f.bytes.length);

  Future<void> _addFiles() async {
    setState(() => _e = null);
    try {
      final fs = await pickPicked(type: FileType.any);
      for (final f in fs) {
        if (_total + f.bytes.length > _maxTotal) {
          throw const FormatException('الحجم الكلي كبير (الحد 300 ميجابايت).');
        }
        _files.add(ZipIn(f.name, Uint8List.fromList(f.bytes)));
      }
    } catch (e) {
      _e = e is FormatException ? e.message : 'تعذر قراءة الملفات';
    }
    if (mounted) setState(() {});
  }

  Future<OutFile?> _build() async {
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      final b = await buildZip(_files);
      final n = _name.text.trim().isEmpty ? 'archive' : _name.text.trim();
      return OutFile('$n.zip', b, 'application/zip');
    } catch (e) {
      if (mounted) setState(() => _e = e is FormatException ? e.message : 'تعذر إنشاء الملف');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickZip() async {
    setState(() {
      _e = null;
      _busy = true;
    });
    try {
      final fs = await pickPicked(type: FileType.custom, exts: ['zip']);
      if (fs.isEmpty) return;
      final b = Uint8List.fromList(fs.first.bytes);
      final es = readZipEntries(b).where((e) => !e.isDir).toList();
      setState(() {
        _zip = b;
        _zipName = fs.first.name;
        _entries = es;
      });
    } catch (e) {
      if (mounted) setState(() => _e = e is FormatException ? e.message : 'تعذر قراءة ZIP');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<OutFile> _extract(ZipEntry e) async {
    if (e.usize > _maxEntry) throw const FormatException('الملف كبير جدًا (الحد 200 ميجابايت)');
    final data = await readZipEntry(_zip!, e);
    return OutFile(safeFileName(e.name), data, 'application/octet-stream');
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      await f();
    } catch (e) {
      if (mounted) setState(() => _e = e is FormatException ? e.message : (e is UnsupportedError ? '${e.message}' : 'تعذر فك الملف'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ضغط وفك ZIP')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('ضغط')),
            ButtonSegment(value: false, label: Text('فك')),
          ],
          selected: {_compress},
          onSelectionChanged: (s) => setState(() {
            _compress = s.first;
            _e = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_compress) ...[
          OutlinedButton.icon(
              onPressed: _busy ? null : _addFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('إضافة ملفات')),
          for (var i = 0; i < _files.length; i++)
            ListTile(
              dense: true,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(_files[i].name, overflow: TextOverflow.ellipsis),
              subtitle: Text(humanSize(_files[i].bytes.length)),
              trailing: IconButton(
                  onPressed: () => setState(() => _files.removeAt(i)),
                  icon: const Icon(Icons.close)),
            ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${_files.length} ملف • ${humanSize(_total)}'),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الملف المضغوط')),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final f = await _build();
                        if (f != null && context.mounted) await saveOut(context, f);
                      },
                icon: const Icon(Icons.folder_zip_outlined),
                label: const Text('ضغط وحفظ')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final f = await _build();
                        if (f != null && context.mounted) await shareOut(context, [f]);
                      },
                icon: const Icon(Icons.share),
                label: const Text('ضغط ومشاركة')),
          ],
        ] else ...[
          OutlinedButton.icon(
              onPressed: _busy ? null : _pickZip,
              icon: const Icon(Icons.folder_zip_outlined),
              label: const Text('اختر ملف ZIP')),
          if (_zip != null) ...[
            const SizedBox(height: 12),
            Text('$_zipName • ${_entries.length} ملف', style: t.textTheme.titleSmall),
            for (final e in _entries)
              ListTile(
                dense: true,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(e.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(humanSize(e.usize)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      tooltip: 'حفظ',
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final f = await _extract(e);
                                if (context.mounted) await saveOut(context, f);
                              }),
                      icon: const Icon(Icons.save_alt)),
                  IconButton(
                      tooltip: 'مشاركة',
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final f = await _extract(e);
                                if (context.mounted) await shareOut(context, [f]);
                              }),
                      icon: const Icon(Icons.share)),
                ]),
              ),
            if (_entries.length > 1 && _entries.length <= 50)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                              final out = <OutFile>[];
                              var total = 0;
                              for (final e in _entries) {
                                total += e.usize;
                                if (total > _maxTotal) throw const FormatException('الحجم الكلي كبير (الحد 300 ميجابايت).');
                                out.add(await _extract(e));
                              }
                              if (context.mounted) await shareOut(context, out);
                            }),
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة كل الملفات')),
              ),
          ],
        ],
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_e != null)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(_e!, style: TextStyle(color: t.colorScheme.error))),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'المعالجة داخل جهازك. تُدعم أسماء الملفات العربية. لا يدعم ZIP المشفّر بكلمة سر ولا الأرشيفات فوق ٤ جيجابايت، والمعالجة في الذاكرة فاحرص أن يكون الحجم الكلي أقل من ٣٠٠ ميجابايت.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
