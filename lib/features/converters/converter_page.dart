import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/fmt.dart';
import '../../core/num_parse.dart';
import 'converter_logic.dart';

class ConverterPage extends StatefulWidget {
  final String title;
  final List<Unit> units;
  final double minBase;
  final String? note;
  const ConverterPage({
    super.key,
    required this.title,
    required this.units,
    this.minBase = 0,
    this.note,
  });
  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _c = TextEditingController(text: '1');
  int _from = 0, _to = 1;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _drop(String label, int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      // ignore: deprecated_member_use
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var i = 0; i < widget.units.length; i++)
          DropdownMenuItem(value: i, child: Text(widget.units[i].name)),
      ],
      onChanged: (v) => onChanged(v ?? value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final u = widget.units;
    final v = parseNum(_c.text);
    String? err;
    double? res;
    if (_c.text.trim().isNotEmpty) {
      if (v == null) {
        err = 'أدخل رقمًا صحيحًا';
      } else if (u[_from].toBase(v) < widget.minBase - 1e-9) {
        err = 'القيمة خارج النطاق المسموح';
      } else {
        res = convert(v, u[_from], u[_to]);
        if (!res.isFinite) {
          res = null;
          err = 'القيمة كبيرة جدًا';
        }
      }
    }
    final line = res == null
        ? ''
        : '${fmtSig(v!)} ${u[_from].name} = ${fmtSig(res)} ${u[_to].name}';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _c,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.numberWithOptions(
                decimal: true, signed: widget.minBase < 0),
            decoration: const InputDecoration(labelText: 'القيمة'),
          ),
          const SizedBox(height: 12),
          _drop('من', _from, (i) => setState(() => _from = i)),
          Center(
            child: IconButton(
              tooltip: 'تبديل',
              icon: const Icon(Icons.swap_vert),
              onPressed: () => setState(() {
                final x = _from;
                _from = _to;
                _to = x;
              }),
            ),
          ),
          _drop('إلى', _to, (i) => setState(() => _to = i)),
          const SizedBox(height: 20),
          if (err != null)
            Text(err, style: TextStyle(color: t.colorScheme.error)),
          if (res != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                SelectableText(fmtSig(res),
                    textAlign: TextAlign.center,
                    style: t.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(u[_to].name),
              ]),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: line));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('تم النسخ')));
                },
                child: const Text('نسخ النتيجة'),
              ),
            ),
            const SizedBox(height: 16),
            Text('كل التحويلات', style: t.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (var i = 0; i < u.length; i++)
              if (i != _from) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(u[i].name)),
                    Text(fmtSig(convert(v!, u[_from], u[i])),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Divider(height: 1),
              ],
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
