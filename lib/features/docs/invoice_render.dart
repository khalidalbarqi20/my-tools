import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'invoice_logic.dart';

const _w = 1240.0, _h = 1754.0, _m = 80.0; // A4 تقريبًا بدقة 150 dpi
const _ink = Color(0xFF111111), _grey = Color(0xFF666666), _line = Color(0xFFBBBBBB);

/// يرسم كل صفحات الفاتورة كصور (نرسم النص بمحرك فلتر ليظهر العربي بشكل صحيح).
Future<List<Uint8List>> renderInvoice(InvoiceData d) async {
  final chunks = chunkItems(d.items);
  final out = <Uint8List>[];
  for (var i = 0; i < chunks.length; i++) {
    out.add(await _page(d, chunks[i], i, chunks.length, i == chunks.length - 1));
  }
  return out;
}

Future<Uint8List> _page(InvoiceData d, List<InvoiceItem> rows, int pageIdx, int pages, bool last) async {
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec, const ui.Rect.fromLTWH(0, 0, _w, _h));
  c.drawRect(const ui.Rect.fromLTWH(0, 0, _w, _h), ui.Paint()..color = const Color(0xFFFFFFFF));

  TextPainter tp(String t, double size,
      {Color color = _ink, FontWeight w = FontWeight.w400, double? maxW}) {
    return TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: size, color: color, fontWeight: w, height: 1.3)),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: maxW ?? double.infinity);
  }

  // نص حافته اليمنى عند x
  double right(String t, double x, double y, double size,
      {Color color = _ink, FontWeight w = FontWeight.w400, double? maxW}) {
    final p = tp(t, size, color: color, w: w, maxW: maxW);
    p.paint(c, ui.Offset(x - p.width, y));
    return p.height;
  }

  // نص حافته اليسرى عند x
  void left(String t, double x, double y, double size,
      {Color color = _ink, FontWeight w = FontWeight.w400}) {
    tp(t, size, color: color, w: w).paint(c, ui.Offset(x, y));
  }

  void center(String t, double cx, double y, double size,
      {Color color = _ink, FontWeight w = FontWeight.w400}) {
    final p = tp(t, size, color: color, w: w);
    p.paint(c, ui.Offset(cx - p.width / 2, y + (0)));
  }

  final linePaint = ui.Paint()
    ..color = _line
    ..strokeWidth = 2;
  const r = _w - _m;
  var y = _m;

  right(pageIdx == 0 ? 'فاتورة' : 'فاتورة (تابع)', r, y, 76, w: FontWeight.w700);
  left('رقم: ${d.number}', _m, y + 6, 30);
  left('التاريخ: ${d.date}', _m, y + 46, 30);
  y += 120;
  c.drawLine(ui.Offset(_m, y), ui.Offset(r, y), linePaint);
  y += 30;

  if (pageIdx == 0) {
    right('البائع', r, y, 26, color: _grey);
    right(d.seller.isEmpty ? '—' : d.seller, r, y + 34, 36, w: FontWeight.w700, maxW: 520);
    left('العميل', _m + 400, y, 26, color: _grey);
    final p = tp(d.buyer.isEmpty ? '—' : d.buyer, 36, w: FontWeight.w700, maxW: 400);
    p.paint(c, ui.Offset(_m + 400, y + 34));
    y += 130;
  }

  // أعمدة الجدول من اليمين
  const wIdx = 70.0, wQty = 130.0, wPrice = 190.0, wTot = 210.0;
  const wName = (_w - 2 * _m) - wIdx - wQty - wPrice - wTot;
  final xIdxR = r, xIdxL = r - wIdx;
  final xNameR = xIdxL, xNameL = xNameR - wName;
  final xQtyR = xNameL, xQtyL = xQtyR - wQty;
  final xPriceR = xQtyL, xPriceL = xPriceR - wPrice;
  final xTotR = xPriceL, xTotL = xTotR - wTot;

  const rowH = 70.0;
  c.drawRect(ui.Rect.fromLTRB(_m, y, r, y + rowH), ui.Paint()..color = const Color(0xFFEFEFEF));
  center('م', (xIdxL + xIdxR) / 2, y + 16, 30, w: FontWeight.w700);
  right('الصنف', xNameR - 14, y + 16, 30, w: FontWeight.w700);
  center('الكمية', (xQtyL + xQtyR) / 2, y + 16, 30, w: FontWeight.w700);
  center('السعر', (xPriceL + xPriceR) / 2, y + 16, 30, w: FontWeight.w700);
  center('الإجمالي', (xTotL + xTotR) / 2, y + 16, 30, w: FontWeight.w700);
  y += rowH;
  final base = pageIdx * 16;
  for (var i = 0; i < rows.length; i++) {
    final it = rows[i];
    center('${base + i + 1}', (xIdxL + xIdxR) / 2, y + 16, 30);
    final nameP = tp(it.name.isEmpty ? '—' : it.name, 30, maxW: wName - 28);
    nameP.paint(c, ui.Offset(xNameR - 14 - nameP.width, y + (rowH - nameP.height) / 2));
    center(qtyText(it.qty), (xQtyL + xQtyR) / 2, y + 16, 30);
    center(money(it.price), (xPriceL + xPriceR) / 2, y + 16, 30);
    center(money(it.total), (xTotL + xTotR) / 2, y + 16, 30);
    y += rowH;
    c.drawLine(ui.Offset(_m, y), ui.Offset(r, y), linePaint);
  }

  if (last) {
    final t = invoiceTotals(d.items, d.taxPct);
    y += 40;
    const bw = 560.0;
    void trow(String label, String value, {bool bold = false, bool fill = false}) {
      if (fill) {
        c.drawRect(ui.Rect.fromLTRB(_m, y, _m + bw, y + 66), ui.Paint()..color = const Color(0xFFEFEFEF));
      }
      final fw = bold ? FontWeight.w700 : FontWeight.w400;
      right(label, _m + bw - 16, y + 14, bold ? 36 : 32, w: fw);
      left(value, _m + 16, y + 14, bold ? 36 : 32, w: fw);
      y += 70;
    }

    final startY = y;
    trow('المجموع قبل الضريبة', money(t.subtotal));
    trow('الضريبة (${qtyText(d.taxPct)}%)', money(t.tax));
    trow('الإجمالي', money(t.total), bold: true, fill: true);
    if (d.notes.trim().isNotEmpty) {
      right('ملاحظات', r, startY, 26, color: _grey);
      right(d.notes.trim(), r, startY + 34, 30, maxW: 560);
    }
  }
  center('صفحة ${pageIdx + 1} / $pages', _w / 2, _h - 70, 24, color: _grey);

  final img = await rec.endRecording().toImage(_w.toInt(), _h.toInt());
  try {
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('encode failed');
    return data.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}

Future<Uint8List> _buildPdf(List<Uint8List> pngs) async {
  final doc = pw.Document();
  for (final b in pngs) {
    final img = pw.MemoryImage(b);
    doc.addPage(pw.Page(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(img, fit: pw.BoxFit.fill),
    ));
  }
  return doc.save();
}

Future<Uint8List> pngsToA4Pdf(List<Uint8List> pngs) => compute(_buildPdf, pngs);
