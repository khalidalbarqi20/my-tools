import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
import 'pdf_common.dart';

const _maxPages = 80;
final _arabic = RegExp(r'[\u0600-\u06FF]');

/// يرسم الصفحة كصورة ثم يضيف فوقها رقم الصفحة و/أو العلامة المائية (يدعم العربية).
Future<Uint8List> _stampPage(PdfPage page, int index, int total,
    {required String wm, required String pos, required bool ofTotal}) async {
  var w = page.width * 1.8, h = page.height * 1.8;
  final big = w > h ? w : h;
  if (big > 2400) {
    w *= 2400 / big;
    h *= 2400 / big;
  }
  final wi = w.round().clamp(1, 2400).toInt();
  final hi = h.round().clamp(1, 2400).toInt();
  final r = await page.render(
      width: wi,
      height: hi,
      fullWidth: wi.toDouble(),
      fullHeight: hi.toDouble());
  if (r == null) throw Exception('render failed');
  final ui.Image img;
  try {
    img = await r.createImage();
  } finally {
    r.dispose();
  }
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawImage(img, ui.Offset.zero, ui.Paint());
  img.dispose();
  final k = wi / page.width; // بكسل لكل نقطة PDF

  TextPainter paint(String t, double size, Color color, FontWeight fw) {
    return TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              fontFamily: 'Tajawal', fontSize: size, color: color, fontWeight: fw)),
      textDirection: _arabic.hasMatch(t) ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
  }

  if (wm.isNotEmpty) {
    var tp = paint(wm, 100, const Color(0x40808080), FontWeight.w700);
    final target = (wi < hi ? wi : hi) * 0.8;
    final size = (100 * target / tp.width).clamp(8.0, 160.0 * k);
    tp = paint(wm, size, const Color(0x40808080), FontWeight.w700);
    c.save();
    c.translate(wi / 2, hi / 2);
    c.rotate(-0.7854);
    tp.paint(c, ui.Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
  }
  if (pos != 'none') {
    final t = ofTotal ? '${index + 1} / $total' : '${index + 1}';
    final tp = paint(t, 11 * k, const Color(0xFF333333), FontWeight.w500);
    final margin = 28 * k;
    final x = pos == 'left'
        ? margin
        : pos == 'right'
            ? wi - margin - tp.width
            : (wi - tp.width) / 2;
    tp.paint(c, ui.Offset(x, hi - 18 * k - tp.height));
  }
  final out = await rec.endRecording().toImage(wi, hi);
  try {
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw Exception('encode failed');
    return data.buffer.asUint8List();
  } finally {
    out.dispose();
  }
}

Future<Uint8List> _assemble(Map<String, Object> a) async {
  final imgs = (a['imgs'] as List).cast<Uint8List>();
  final sizes = (a['sizes'] as List).cast<double>();
  final doc = pw.Document();
  for (var i = 0; i < imgs.length; i++) {
    final pw0 = sizes[2 * i], ph0 = sizes[2 * i + 1];
    final im = pw.MemoryImage(imgs[i]);
    doc.addPage(pw.Page(
      pageFormat: pdf.PdfPageFormat(pw0, ph0),
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(im, width: pw0, height: ph0, fit: pw.BoxFit.fill),
    ));
  }
  return doc.save();
}

Future<List<OutFile>> _stamp(Uint8List b, String base, int n, String suffix,
    {String wm = '', String pos = 'none', bool ofTotal = false}) async {
  if (n > _maxPages) {
    throw const FormatException(
        'الحد الأقصى $_maxPages صفحة لهذه الأداة. قسّم الملف أولًا ثم أعد المحاولة.');
  }
  ensurePdfInit();
  final src = await PdfDocument.openData(b, sourceName: '$base.pdf');
  try {
    final imgs = <Uint8List>[];
    final sizes = <double>[];
    for (var i = 0; i < src.pages.length; i++) {
      final p = src.pages[i];
      imgs.add(await _stampPage(p, i, src.pages.length,
          wm: wm, pos: pos, ofTotal: ofTotal));
      sizes
        ..add(p.width)
        ..add(p.height);
    }
    final data = await compute(_assemble, <String, Object>{'imgs': imgs, 'sizes': sizes});
    final name = '${base}_$suffix.pdf';
    return [OutFile(name, data, 'application/pdf')];
  } finally {
    await src.dispose();
  }
}

Future<List<OutFile>> addPageNumbers(
        Uint8List b, String base, int n, Map<String, String> o) =>
    _stamp(b, base, n, 'numbered',
        pos: o['pos'] ?? 'center', ofTotal: o['total'] == 'true');

Future<List<OutFile>> addWatermark(
    Uint8List b, String base, int n, Map<String, String> o) {
  final t = (o['text'] ?? '').trim();
  if (t.isEmpty) throw const FormatException('اكتب نص العلامة المائية');
  if (t.length > 40) throw const FormatException('النص طويل. الحد الأقصى 40 حرفًا');
  return _stamp(b, base, n, 'watermarked', wm: t);
}
