import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/display_card.dart';
import 'text_logic.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  double _len = 16;
  bool _up = true, _low = true, _dig = true, _sym = true, _sim = false;
  String _pw = '';
  String? _err;

  @override
  void initState() {
    super.initState();
    _gen();
  }

  void _gen() {
    try {
      _pw = generatePassword(
          length: _len.round(),
          upper: _up,
          lower: _low,
          digits: _dig,
          symbols: _sym,
          avoidSimilar: _sim);
      _err = null;
    } on FormatException catch (e) {
      _pw = '';
      _err = e.message;
    }
  }

  void _change(VoidCallback f) => setState(() {
        f();
        _gen();
      });

  Widget _sw(String label, bool v, ValueChanged<bool> on) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: v,
        onChanged: (x) => _change(() => on(x)),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final pool = passwordPoolSize(
        upper: _up, lower: _low, digits: _dig, symbols: _sym, avoidSimilar: _sim);
    final bits = entropyBits(_len.round(), pool);
    final label = strengthLabel(bits);
    final color = bits < 40
        ? cs.error
        : bits < 60
            ? Colors.orange
            : cs.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('مولد كلمات المرور')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DisplayCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  _pw.isEmpty ? '—' : _pw,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              if (_pw.isNotEmpty) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (bits / 100).clamp(0.0, 1.0).toDouble(),
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 6),
                Text('القوة: $label (${bits.round()} بت)',
                    style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ]),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_err!, style: TextStyle(color: cs.error)),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pw.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: _pw));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم النسخ')));
                      },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => setState(_gen),
                icon: const Icon(Icons.refresh),
                label: const Text('توليد جديد'),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Text('الطول'),
            const Spacer(),
            Text('${_len.round()}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          Slider(
            value: _len,
            min: 4,
            max: 64,
            divisions: 60,
            onChanged: (v) => _change(() => _len = v),
          ),
          _sw('أحرف كبيرة (A-Z)', _up, (x) => _up = x),
          _sw('أحرف صغيرة (a-z)', _low, (x) => _low = x),
          _sw('أرقام (0-9)', _dig, (x) => _dig = x),
          _sw('رموز (!@#...)', _sym, (x) => _sym = x),
          _sw('تجنب الأحرف المتشابهة (O 0 l 1 I)', _sim, (x) => _sim = x),
          const SizedBox(height: 8),
          Text('تُولَّد على جهازك بمولد عشوائي آمن، ولا تُخزَّن ولا تُرسل لأي مكان.',
              style: t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
