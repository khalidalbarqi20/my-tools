/// منطق الفاتورة (دوال نقية قابلة للاختبار).
library;

class InvoiceItem {
  String name;
  double qty, price;
  InvoiceItem(this.name, this.qty, this.price);
  double get total => _r2(qty * price);
}

double _r2(double v) => (v * 100).roundToDouble() / 100;

class InvoiceTotals {
  final double subtotal, tax, total;
  const InvoiceTotals(this.subtotal, this.tax, this.total);
}

InvoiceTotals invoiceTotals(List<InvoiceItem> items, double taxPct) {
  var sub = 0.0;
  for (final i in items) {
    sub += i.total;
  }
  sub = _r2(sub);
  final tax = _r2(sub * taxPct / 100);
  return InvoiceTotals(sub, tax, _r2(sub + tax));
}

String money(double v) => v.toStringAsFixed(2);

String qtyText(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// يقبل الأرقام العربية والفاصلة العشرية العربية.
double? parseNum(String s) {
  var t = s.trim();
  if (t.isEmpty) return null;
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  t = t.replaceAll('٫', '.').replaceAll('،', '.').replaceAll(',', '.');
  final v = double.tryParse(t);
  return (v == null || v.isNaN || v.isInfinite) ? null : v;
}

/// يقسم البنود على صفحات (صفحة واحدة على الأقل).
List<List<InvoiceItem>> chunkItems(List<InvoiceItem> items, {int perPage = 16}) {
  if (items.isEmpty) return [[]];
  return [
    for (var i = 0; i < items.length; i += perPage)
      items.sublist(i, i + perPage > items.length ? items.length : i + perPage)
  ];
}

class InvoiceData {
  final String number, date, seller, buyer, notes;
  final double taxPct;
  final List<InvoiceItem> items;
  const InvoiceData({
    required this.number,
    required this.date,
    required this.seller,
    required this.buyer,
    required this.notes,
    required this.taxPct,
    required this.items,
  });
}
