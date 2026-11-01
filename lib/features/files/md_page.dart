import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../pdf/pdf_common.dart' show OutFile, pickPicked, saveOut;
import 'md_logic.dart';

const _sample = '''# عنوان رئيسي

هذا نص **عريض** و*مائل* و`كود` ورابط [موقع](https://example.com).

## قائمة

- عنصر أول
- عنصر ثاني

1. خطوة أولى
2. خطوة ثانية

> اقتباس

```
print("hello")
```
''';

class MarkdownPage extends StatefulWidget {
  const MarkdownPage({super.key});
  @override
  State<MarkdownPage> createState() => _MarkdownPageState();
}

class _MarkdownPageState extends State<MarkdownPage> {
  final _c = TextEditingController(text: _sample);
  bool _preview = true;
  String _name = 'note';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final fs = await pickPicked(type: FileType.custom, exts: ['md', 'markdown', 'txt']);
      if (fs.isEmpty) return;
      setState(() {
        _c.text = utf8.decode(fs.first.bytes, allowMalformed: true);
        _name = fs.first.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الملف')));
    }
  }

  TextSpan _span(MdSpan s, TextStyle base, ThemeData t) {
    var st = base;
    if (s.bold) st = st.copyWith(fontWeight: FontWeight.w800);
    if (s.italic) st = st.copyWith(fontStyle: FontStyle.italic);
    if (s.code) st = st.copyWith(fontFamily: 'monospace', backgroundColor: t.colorScheme.surfaceContainerHighest);
    if (s.link != null) st = st.copyWith(color: t.colorScheme.primary, decoration: TextDecoration.underline);
    return TextSpan(text: s.text, style: st);
  }

  Widget _rich(String text, TextStyle base, ThemeData t) =>
      Text.rich(TextSpan(children: [for (final s in parseInline(text)) _span(s, base, t)]));

  Widget _block(MdBlock b, ThemeData t) {
    final body = t.textTheme.bodyLarge!.copyWith(height: 1.7);
    switch (b.kind) {
      case MdKind.heading:
        final sizes = [0.0, 30.0, 25.0, 21.0, 18.0, 16.0, 15.0];
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: _rich(b.text, body.copyWith(fontSize: sizes[b.level], fontWeight: FontWeight.w800), t),
        );
      case MdKind.paragraph:
        return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _rich(b.text, body, t));
      case MdKind.bullet:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: body),
            Expanded(child: _rich(b.text, body, t)),
          ]),
        );
      case MdKind.numbered:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${b.number}.  ', style: body),
            Expanded(child: _rich(b.text, body, t)),
          ]),
        );
      case MdKind.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsetsDirectional.only(start: 12, top: 4, bottom: 4),
          decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: t.colorScheme.primary, width: 4))),
          child: _rich(b.text, body.copyWith(color: t.colorScheme.onSurfaceVariant), t),
        );
      case MdKind.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(b.text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        );
      case MdKind.rule:
        return const Divider(height: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('قارئ ومحرر Markdown'), actions: [
        IconButton(tooltip: 'فتح ملف', onPressed: _open, icon: const Icon(Icons.folder_open)),
        IconButton(
            tooltip: 'حفظ',
            onPressed: () => saveOut(context,
                OutFile('$_name.md', Uint8List.fromList(utf8.encode(_c.text)), 'text/markdown')),
            icon: const Icon(Icons.save_alt)),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('تحرير'), icon: Icon(Icons.edit_outlined)),
              ButtonSegment(value: true, label: Text('معاينة'), icon: Icon(Icons.visibility_outlined)),
            ],
            selected: {_preview},
            onSelectionChanged: (s) => setState(() => _preview = s.first),
          ),
        ),
        Expanded(
          child: _preview
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [for (final b in parseMarkdown(_c.text)) _block(b, t)],
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _c,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    decoration: const InputDecoration(hintText: 'اكتب Markdown هنا'),
                  ),
                ),
        ),
      ]),
    );
  }
}
