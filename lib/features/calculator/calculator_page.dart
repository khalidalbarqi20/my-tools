import 'package:flutter/material.dart';
import '../../core/fmt.dart';
import 'expr.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _e = '';
  String _msg = '';
  bool _sci = false;
  bool _deg = true;
  final List<(String, String)> _hist = []; // (العملية، النتيجة)
  static const _sciRows = [
    ['sin', 'cos', 'tan', 'π'],
    ['ln', 'log', '√', '^'],
    ['x²', 'x!', 'e', 'DEG'],
  ];
  static const _rows = [
    ['C', '(', ')', '⌫'],
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['0', '.', '%', '+'],
  ];

  String get _preview {
    if (_e.isEmpty) return '';
    final v = evalExprWith(_e, degrees: _deg);
    if (v == null) return '';
    final s = fmt(v, 10);
    return s == _e ? '' : s;
  }

  void _tap(String k) => setState(() {
        _msg = '';
        if (k == 'C') {
          _e = '';
        } else if (k == '⌫') {
          if (_e.isNotEmpty) _e = _e.substring(0, _e.length - 1);
        } else if (k == '=') {
          if (_e.isEmpty) return;
          final v = evalExprWith(_e, degrees: _deg);
          if (v == null) {
            _msg = 'عملية غير صحيحة';
          } else {
            final r = fmt(v, 10);
            _hist.add((_e, r));
            if (_hist.length > 30) _hist.removeAt(0);
            _e = r;
          }
        } else if (k == 'DEG') {
          _deg = !_deg;
        } else {
          _e += _ins(k);
        }
      });

  String _ins(String k) {
    switch (k) {
      case 'sin':
      case 'cos':
      case 'tan':
      case 'ln':
      case 'log':
      case '√':
        return '$k(';
      case 'x²':
        return '^2';
      case 'x!':
        return '!';
      default:
        return k;
    }
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _hist.isEmpty
          ? const SizedBox(
              height: 160, child: Center(child: Text('لا توجد عمليات بعد')))
          : ListView(children: [
              for (final h in _hist.reversed)
                ListTile(
                  title: Directionality(
                      textDirection: TextDirection.ltr, child: Text(h.$1)),
                  subtitle: Directionality(
                      textDirection: TextDirection.ltr, child: Text('= ${h.$2}')),
                  onTap: () {
                    setState(() => _e = h.$2);
                    Navigator.pop(ctx);
                  },
                ),
            ]),
    );
  }

  Widget _key(String k) {
    final style = FilledButton.styleFrom(
        minimumSize: Size.zero, padding: EdgeInsets.zero);
    final label = Text(k == 'DEG' ? (_deg ? 'DEG' : 'RAD') : k,
        style: TextStyle(fontSize: k.length > 1 ? 17 : 24));
    return '÷×−+'.contains(k)
        ? FilledButton(onPressed: () => _tap(k), style: style, child: label)
        : FilledButton.tonal(
            onPressed: () => _tap(k), style: style, child: label);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final hasMsg = _msg.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(_sci ? 'حاسبة علمية' : 'حاسبة عادية'),
        actions: [
          IconButton(
              tooltip: 'سجل العمليات',
              icon: const Icon(Icons.history),
              onPressed: _showHistory),
          IconButton(
              tooltip: _sci ? 'حاسبة عادية' : 'حاسبة علمية',
              icon: Icon(_sci ? Icons.dialpad : Icons.functions),
              onPressed: () => setState(() => _sci = !_sci)),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: Column(children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_e.isEmpty ? '0' : _e,
                          style: t.textTheme.displayMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(hasMsg ? _msg : _preview,
                        style: t.textTheme.titleLarge?.copyWith(
                            color: hasMsg
                                ? t.colorScheme.error
                                : t.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: _sci ? 8 : 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final row in [if (_sci) ..._sciRows, ..._rows])
                    Expanded(
                      child: Row(children: [
                        for (final k in row)
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _key(k))),
                      ]),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FilledButton(
                        onPressed: () => _tap('='),
                        style: FilledButton.styleFrom(minimumSize: Size.zero),
                        child: const Text('=', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
