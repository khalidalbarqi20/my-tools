import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pdf/pdf_common.dart' show OutFile, saveOut, shareOut;
import 'invoice_logic.dart';
import 'invoice_render.dart';

const _kSeller = 'invoice_seller';
const _kTax = 'invoice_tax';

class _Row {
  final name = TextEditingController();
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }

  InvoiceItem get item =>
      InvoiceItem(name.text.trim(), parseNum(qty.text) ?? 0, parseNum(price.text) ?? 0);
}

String _today() {
  final d = DateTime.now();
  String t(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${t(d.month)}-${t(d.day)}';
}

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _seller = TextEditingController();
  final _buyer = TextEditingController();
  final _number = TextEditingController(text: 'INV-0001');
  final _date = TextEditingController(text: _today());
  final _tax = TextEditingController(text: '15');
  final _notes = TextEditingController();
  final _rows = [_Row()];
  bool _busy = false;
  String? _e;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _seller.text = p.getString(_kSeller) ?? '';
        _tax.text = p.getString(_kTax) ?? '15';
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_seller, _buyer, _number, _date, _tax, _notes]) {
      c.dispose();
    }
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  double get _taxPct => (parseNum(_tax.text) ?? 0).clamp(0.0, 100.0).toDouble();

  InvoiceData _data() => InvoiceData(
        number: _number.text.trim(),
        date: _date.text.trim(),
        seller: _seller.text.trim(),
        buyer: _buyer.text.trim(),
        notes: _notes.text,
        taxPct: _taxPct,
        items: [for (final r in _rows) if (r.name.text.trim().isNotEmpty || (parseNum(r.price.text) ?? 0) > 0) r.item],
      );

  Future<OutFile?> _make() async {
    final d = _data();
    if (d.items.isEmpty) {
      setState(() => _e = 'أضف بندًا واحدًا على الأقل.');
      return null;
    }
    if (d.items.length > 160) {
      setState(() => _e = 'الحد الأقصى ١٦٠ بندًا.');
      return null;
    }
    setState(() {
      _busy = true;
      _e = null;
    });
    try {
      SharedPreferences.getInstance().then((p) {
        p.setString(_kSeller, d.seller);
        p.setString(_kTax, _tax.text.trim());
      }).catchError((_) {});
      final pngs = await renderInvoice(d);
      final pdfBytes = await pngsToA4Pdf(pngs);
      final safe = d.number.replaceAll(RegExp(r'[^\w\-]+'), '_');
      return OutFile('invoice_${safe.isEmpty ? 'new' : safe}.pdf', pdfBytes, 'application/pdf');
    } catch (_) {
      if (mounted) setState(() => _e = 'تعذر إنشاء الفاتورة.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tot = invoiceTotals([for (final r in _rows) r.item], _taxPct);
    return Scaffold(
      appBar: AppBar(title: const Text('مولد فاتورة PDF')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _seller, decoration: const InputDecoration(labelText: 'اسم البائع / المنشأة')),
        const SizedBox(height: 12),
        TextField(controller: _buyer, decoration: const InputDecoration(labelText: 'اسم العميل')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _number, decoration: const InputDecoration(labelText: 'رقم الفاتورة'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _date, decoration: const InputDecoration(labelText: 'التاريخ'))),
        ]),
        const SizedBox(height: 20),
        Text('البنود', style: t.textTheme.titleMedium),
        for (var i = 0; i < _rows.length; i++)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: _rows[i].name,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: 'الصنف ${i + 1}')),
                  ),
                  if (_rows.length > 1)
                    IconButton(
                        onPressed: () => setState(() => _rows.removeAt(i).dispose()),
                        icon: const Icon(Icons.delete_outline)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                        controller: _rows[i].qty,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'الكمية')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                        controller: _rows[i].price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'السعر')),
                  ),
                  const SizedBox(width: 12),
                  Text(money(_rows[i].item.total), style: t.textTheme.titleSmall),
                ]),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () => setState(() => _rows.add(_Row())),
            icon: const Icon(Icons.add),
            label: const Text('إضافة بند')),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            width: 140,
            child: TextField(
                controller: _tax,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'الضريبة %')),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
        const SizedBox(height: 16),
        Card(
          color: t.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _line('المجموع قبل الضريبة', money(tot.subtotal)),
              _line('الضريبة', money(tot.tax)),
              _line('الإجمالي', money(tot.total), bold: true),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final f = await _make();
                  if (f != null && context.mounted) await saveOut(context, f);
                },
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('إنشاء وحفظ PDF'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final f = await _make();
                  if (f != null && context.mounted) await shareOut(context, [f]);
                },
          icon: const Icon(Icons.share),
          label: const Text('إنشاء ومشاركة'),
        ),
        if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (_e != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_e!, style: TextStyle(color: t.colorScheme.error))),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
              'الفاتورة تُحفظ كصور داخل ملف PDF (النص غير قابل للنسخ). نسبة الضريبة الافتراضية ١٥٪ (ضريبة القيمة المضافة في السعودية)، وغيّرها أو اجعلها ٠. هذه فاتورة بسيطة وليست فاتورة إلكترونية معتمدة من هيئة الزكاة والضريبة (ZATCA).',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ),
      ]),
    );
  }

  Widget _line(String a, String b, {bool bold = false}) {
    final s = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 18 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(a, style: s), Text(b, style: s)]),
    );
  }
}
