import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fmt.dart';

class CalcField {
  final String label;
  final String? initial;
  final bool text;
  const CalcField(this.label, {this.initial, this.text = false});
}

class CalcPage extends StatefulWidget {
  final String title;
  final List<CalcField> fields;
  final Rows? Function(List<String>) compute;
  final String? note;
  const CalcPage({
    super.key,
    required this.title,
    required this.fields,
    required this.compute,
    this.note,
  });
  @override
  State<CalcPage> createState() => _CalcPageState();
}

class _CalcPageState extends State<CalcPage> {
  late final List<TextEditingController> _c = [
    for (final f in widget.fields) TextEditingController(text: f.initial ?? '')
  ];
  Rows? _rows;
  String? _err;

  void _calc() {
    Rows? r;
    try {
      r = widget.compute([for (final c in _c) c.text]);
    } catch (_) {
      r = null;
    }
    if (r != null &&
        r.any((e) => e.$2.contains('Infinity') || e.$2.contains('NaN'))) {
      r = null;
    }
    setState(() {
      _rows = r;
      _err = r == null ? 'تأكد من إدخال قيم صحيحة في كل الحقول' : null;
    });
  }

  void _clear() {
    for (var i = 0; i < _c.length; i++) {
      _c[i].text = widget.fields[i].initial ?? '';
    }
    setState(() {
      _rows = null;
      _err = null;
    });
  }

  String get _text => [
        for (final r in _rows ?? <(String, String)>[]) '${r.$1}: ${r.$2}'
      ].join('\n');

  void _copy() {
    Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم النسخ')));
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < widget.fields.length; i++) ...[
            TextField(
              controller: _c[i],
              keyboardType: widget.fields[i].text
                  ? TextInputType.multiline
                  : const TextInputType.numberWithOptions(decimal: true),
              minLines: widget.fields[i].text ? 3 : 1,
              maxLines: widget.fields[i].text ? 6 : 1,
              decoration: InputDecoration(labelText: widget.fields[i].label),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(onPressed: _calc, child: const Text('احسب')),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_err!, style: TextStyle(color: cs.error)),
            ),
          if (_rows != null) ...[
            const SizedBox(height: 20),
            for (final r in _rows!) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(child: Text(r.$1)),
                  Text(r.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 12),
            Row(children: [
              OutlinedButton(onPressed: _copy, child: const Text('نسخ النتيجة')),
              const SizedBox(width: 8),
              TextButton(onPressed: _clear, child: const Text('مسح')),
            ]),
          ],
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(widget.note!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
