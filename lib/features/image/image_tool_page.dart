import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart';
import '../pdf/single_pdf_tool.dart' show Opt;
import 'image_common.dart';

typedef ImgRunner = Future<OutFile> Function(Picked img, Map<String, String> o);

class ImageToolPage extends StatefulWidget {
  final String title, actionLabel;
  final List<Opt> options;
  final ImgRunner run;
  final String? note;
  final bool summary;
  const ImageToolPage({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.run,
    this.options = const [],
    this.note,
    this.summary = false,
  });
  @override
  State<ImageToolPage> createState() => _ImageToolPageState();
}

class _ImageToolPageState extends State<ImageToolPage> {
  List<Picked> _imgs = [];
  bool _busy = false;
  String _prog = '';
  String? _err, _info;
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
    try {
      var f = await pickPicked(type: FileType.image);
      if (f.isEmpty || !mounted) return;
      String? note;
      if (f.length > 20) {
        f = f.sublist(0, 20);
        note = 'تم اختيار أول 20 صورة فقط';
      }
      setState(() {
        _imgs = f;
        _out = [];
        _err = null;
        _info = note;
      });
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
    }
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _err = null;
      _info = null;
      _out = [];
      _prog = '';
    });
    try {
      for (final e in _tc.entries) {
        _o[e.key] = e.value.text;
      }
      final out = <OutFile>[];
      var before = 0, after = 0;
      for (var i = 0; i < _imgs.length; i++) {
        if (mounted) setState(() => _prog = '${i + 1} / ${_imgs.length}');
        final img = _imgs[i];
        try {
          final r = await widget.run(img, _o);
          out.add(r);
          before += img.bytes.length;
          after += r.bytes.length;
        } catch (e) {
          throw FormatException('${imgError(e)}\n(${img.name})');
        }
      }
      String? sum;
      if (widget.summary && before > 0) {
        final pct = (1 - after / before) * 100;
        sum =
            'الحجم: ${humanSize(before)} ← ${humanSize(after)} (${pct >= 0 ? '−' : '+'}${pct.abs().toStringAsFixed(0)}%)';
      }
      if (mounted) {
        setState(() {
          _out = out;
          _info = sum;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _err = imgError(e));
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
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: o.label, hintText: o.hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final total = _imgs.fold<int>(0, (a, b) => a + b.bytes.length);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_imgs.isEmpty ? 'اختيار صور' : 'تغيير الصور'),
          ),
          if (_imgs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in _imgs.take(8))
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(p.bytes,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      cacheWidth: 112,
                      errorBuilder: (c, e, s) => const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.image_not_supported_outlined))),
                ),
            ]),
            const SizedBox(height: 8),
            Text('${_imgs.length} صورة • ${humanSize(total)}'),
          ],
          const SizedBox(height: 12),
          for (final o in widget.options) ...[
            _opt(o),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: (_imgs.isEmpty || _busy) ? null : _run,
            child: Text(widget.actionLabel),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(children: [const LinearProgressIndicator(), const SizedBox(height: 4), Text(_prog)]),
            ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: t.colorScheme.error)),
            ),
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_info!, style: t.textTheme.titleSmall),
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
