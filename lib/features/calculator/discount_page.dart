import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'discount_logic.dart';

class DiscountPage extends StatefulWidget {
  const DiscountPage({super.key});
  @override
  State<DiscountPage> createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final _price = TextEditingController();
  final _pct = TextEditingController();
  DiscountResult? _r;
  String? _err;

  String _f(double v) => v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  void _calc() {
    final r = calcDiscount(_price.text, _pct.text);
    setState(() {
      _r = r;
      _err = r == null ? 'أدخل سعرًا صحيحًا ونسبة بين 0 و 100' : null;
    });
  }

  void _clear() {
    _price.clear();
    _pct.clear();
    setState(() {
      _r = null;
      _err = null;
    });
  }

  String get _text => _r == null
      ? ''
      : 'السعر قبل الخصم: ${_f(_r!.original)}\n'
          'قيمة الخصم: ${_f(_r!.discount)}\n'
          'السعر النهائي: ${_f(_r!.finalPrice)}';

  @override
  Widget build(BuildContext context) {
    const kb = TextInputType.numberWithOptions(decimal: true);
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الخصم')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _price,
              keyboardType: kb,
              decoration: const InputDecoration(
                  labelText: 'السعر الأصلي', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _pct,
              keyboardType: kb,
              decoration: const InputDecoration(
                  labelText: 'نسبة الخصم %', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton(onPressed: _calc, child: const Text('احسب')),
          if (_err != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_r != null) ...[
            const SizedBox(height: 20),
            Text(_text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              OutlinedButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: _text)),
                  child: const Text('نسخ')),
              const SizedBox(width: 8),
              TextButton(onPressed: _clear, child: const Text('مسح')),
            ]),
          ],
        ],
      ),
    );
  }
}
