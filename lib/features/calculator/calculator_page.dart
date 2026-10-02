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
  static const _rows = [
    ['C', '(', ')', '⌫'],
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['0', '.', '%', '+'],
  ];

  String get _preview {
    if (_e.isEmpty) return '';
    final v = evalExpr(_e);
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
          final v = evalExpr(_e);
          if (v == null) {
            _msg = 'عملية غير صحيحة';
          } else {
            _e = fmt(v, 10);
          }
        } else {
          _e += k;
        }
      });

  Widget _key(String k) {
    final style = FilledButton.styleFrom(
        minimumSize: Size.zero, padding: EdgeInsets.zero);
    final label = Text(k, style: const TextStyle(fontSize: 24));
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
      appBar: AppBar(title: const Text('حاسبة عادية')),
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
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  for (final row in _rows)
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
