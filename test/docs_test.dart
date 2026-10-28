import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_tools/features/docs/invoice_logic.dart';
import 'package:my_tools/features/docs/scan_logic.dart';

Uint8List _page(int w, int h) {
  final b = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = (x >= 18 && x < 22 && y >= 18 && y < 22) ? 30 : 200;
      final i = 4 * (y * w + x);
      b[i] = v;
      b[i + 1] = v;
      b[i + 2] = v;
      b[i + 3] = 255;
    }
  }
  return b;
}

void main() {
  test('تحسين المستند: الورق أبيض والكتابة داكنة', () {
    const w = 40, h = 40;
    final src = _page(w, h);
    for (final m in [ScanMode.bw, ScanMode.doc]) {
      final o = enhanceDocument(src, w, h, m);
      expect(o[0], 255, reason: '$m ورق');
      expect(o[4 * (20 * w + 20)], lessThan(40), reason: '$m كتابة');
      expect(o[3], 255, reason: 'الشفافية كما هي');
    }
    final c = enhanceDocument(src, w, h, ScanMode.color);
    expect(c[0], greaterThan(200));
    expect(identical(enhanceDocument(src, w, h, ScanMode.original), src), true);
  });

  test('التدوير مع عقارب الساعة', () {
    // 2x2: [A B / C D] → [C A / D B]
    final px = Uint8List.fromList([
      1, 0, 0, 255, 2, 0, 0, 255,
      3, 0, 0, 255, 4, 0, 0, 255,
    ]);
    final r = rotateRgbaCw(px, 2, 2);
    expect([r.$1[0], r.$1[4], r.$1[8], r.$1[12]], [3, 1, 4, 2]);
    expect((r.$2, r.$3), (2, 2));
    final wide = rotateRgbaCw(Uint8List(3 * 1 * 4), 3, 1);
    expect((wide.$2, wide.$3), (1, 3));
  });

  test('إجماليات الفاتورة', () {
    final t = invoiceTotals([InvoiceItem('أ', 1, 100), InvoiceItem('ب', 2, 50.5)], 15);
    expect(t.subtotal, 201.0);
    expect(t.tax, 30.15);
    expect(t.total, 231.15);
    expect(invoiceTotals([], 15).total, 0);
    expect(invoiceTotals([InvoiceItem('أ', 3, 10)], 0).total, 30);
  });

  test('تنسيق وقراءة الأرقام', () {
    expect(money(5), '5.00');
    expect(qtyText(2), '2');
    expect(qtyText(1.5), '1.5');
    expect(qtyText(0.125), '0.125');
    expect(parseNum('١٢٫٥'), 12.5);
    expect(parseNum('1,5'), 1.5);
    expect(parseNum(''), isNull);
    expect(parseNum('abc'), isNull);
  });

  test('تقسيم البنود على الصفحات', () {
    expect(chunkItems([]).length, 1);
    final items = [for (var i = 0; i < 17; i++) InvoiceItem('$i', 1, 1)];
    final c = chunkItems(items);
    expect(c.map((e) => e.length).toList(), [16, 1]);
  });
}
