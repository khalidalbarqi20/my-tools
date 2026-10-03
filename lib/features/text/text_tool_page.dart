import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import '../pdf/single_pdf_tool.dart' show Opt;

class TextToolPage extends StatefulWidget {
  final String title, hint;
  final List<Opt> options;
  final String Function(String input, Map<String, String> o) run;
  final String Function(String output)? summary;
  final String? note;
  const TextToolPage({
    super.key,
    required this.title,
    required this.hint,
    required this.run,
    this.options = const [],
    this.summary,
    this.note,
  });
  @override
  State<TextToolPage> createState() => _TextToolPageState();
}

class _TextToolPageState extends State<TextToolPage> {
  final _c = TextEditingController();
  late final Map<String, String> _o = {
    for (final o in widget.options) o.key: o.initial
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text;
    if (t != null && mounted) setState(() => _c.text = t);
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _opt(Opt o) {
    if (o.isSwitch) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(o.label),
        value: _o[o.key] == 'true',
        onChanged: (v) => setState(() => _o[o.key] = v ? 'true' : 'false'),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(o.label),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            for (final c in o.choices ?? <(String, String)>[])
              ButtonSegment(value: c.$1, label: Text(c.$2))
          ],
          selected: {_o[o.key]!},
          onSelectionChanged: (s) => setState(() => _o[o.key] = s.first),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    String out = '';
    String? err;
    try {
      out = _c.text.isEmpty ? '' : widget.run(_c.text, _o);
    } on FormatException catch (e) {
      err = e.message;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _c,
            minLines: 5,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: widget.hint),
          ),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('لصق')),
            TextButton.icon(
                onPressed: _c.text.isEmpty ? null : () => setState(_c.clear),
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('مسح')),
          ]),
          for (final o in widget.options) ...[
            _opt(o),
            const SizedBox(height: 10),
          ],
          if (err != null)
            Text(err, style: TextStyle(color: t.colorScheme.error)),
          if (_c.text.isNotEmpty && out.isEmpty && err == null)
            Text('لا توجد نتائج',
                style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
          if (out.isNotEmpty) ...[
            const SizedBox(height: 8),
            DisplayCard(child: SelectableText(out, style: const TextStyle(fontSize: 16))),
            if (widget.summary != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(widget.summary!(out),
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: out));
                    _toast('تم النسخ');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('نسخ النتيجة'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _c.text = out),
                  icon: const Icon(Icons.north_east, size: 18),
                  label: const Text('استخدمها كمدخل'),
                ),
              ),
            ]),
          ],
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
