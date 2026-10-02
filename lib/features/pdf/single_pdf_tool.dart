import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'pdf_common.dart';
import 'pdf_ops.dart';

class Opt {
  final String key, label, initial;
  final String? hint;
  final List<(String, String)>? choices;
  final bool isSwitch;
  const Opt.text(this.key, this.label, {this.hint, this.initial = ''})
      : choices = null,
        isSwitch = false;
  const Opt.choice(this.key, this.label, this.choices, {required this.initial})
      : hint = null,
        isSwitch = false;
  const Opt.toggle(this.key, this.label, {bool on = false})
      : hint = null,
        choices = null,
        isSwitch = true,
        initial = on ? 'true' : 'false';
}

typedef PdfRunner = Future<List<OutFile>> Function(
    Uint8List bytes, String base, int pageCount, Map<String, String> o);

class SinglePdfTool extends StatefulWidget {
  final String title, actionLabel;
  final List<Opt> options;
  final PdfRunner run;
  final String? note;
  const SinglePdfTool({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.run,
    this.options = const [],
    this.note,
  });
  @override
  State<SinglePdfTool> createState() => _SinglePdfToolState();
}

class _SinglePdfToolState extends State<SinglePdfTool> {
  Picked? _file;
  int _pages = 0;
  bool _busy = false;
  String? _err;
  List<OutFile> _out = [];
  late final Map<String, String> _o = {
    for (final o in widget.options) o.key: o.initial
  };
  late final Map<String, TextEditingController> _tc = {
    for (final o in widget.options)
      if (!o.isSwitch && o.choices == null)
        o.key: TextEditingController(text: o.initial)
  };

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _err = null;
      _out = [];
    });
    try {
      final fs = await pickPicked(type: FileType.custom, exts: ['pdf']);
      if (fs.isEmpty) return;
      final n = await countPages(fs.first.bytes, fs.first.name);
      if (!mounted) return;
      setState(() {
        _file = fs.first;
        _pages = n;
      });
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    }
  }

  Future<void> _run() async {
    final f = _file;
    if (f == null) return;
    setState(() {
      _busy = true;
      _err = null;
      _out = [];
    });
    try {
      for (final e in _tc.entries) {
        _o[e.key] = e.value.text;
      }
      final out = await widget.run(f.bytes, baseName(f.name), _pages, _o);
      if (mounted) setState(() => _out = out);
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _opt(Opt o) {
    if (o.isSwitch) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(o.label),
        value: _o[o.key] == 'true',
        onChanged: (v) => setState(() => _o[o.key] = v ? 'true' : 'false'),
      );
    }
    if (o.choices != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.label),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: [
            for (final c in o.choices!) ButtonSegment(value: c.$1, label: Text(c.$2))
          ],
          selected: {_o[o.key]!},
          onSelectionChanged: (s) => setState(() => _o[o.key] = s.first),
        ),
      ]);
    }
    return TextField(
      controller: _tc[o.key],
      decoration: InputDecoration(labelText: o.label, hintText: o.hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.folder_open),
            label: Text(_file == null ? 'اختيار ملف PDF' : 'تغيير الملف'),
          ),
          if (_file != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(_file!.name, overflow: TextOverflow.ellipsis),
              subtitle: Text('$_pages صفحة • ${humanSize(_file!.bytes.length)}'),
            ),
          const SizedBox(height: 8),
          for (final o in widget.options) ...[
            _opt(o),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: (_file == null || _busy) ? null : _run,
            child: Text(widget.actionLabel),
          ),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          ResultList(_out),
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(widget.note!,
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
