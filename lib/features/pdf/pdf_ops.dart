import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';
import 'page_ranges.dart';
import 'pdf_common.dart';

const _pdf = 'application/pdf';

Future<PdfDocument> _open(Uint8List b, String name) {
  ensurePdfInit();
  return PdfDocument.openData(b, sourceName: name);
}

Future<Uint8List> _build(List<PdfPage> pages, String name) async {
  final d = await PdfDocument.createNew(sourceName: name);
  try {
    d.pages = pages;
    await d.assemble();
    return await d.encodePdf();
  } finally {
    await d.dispose();
  }
}

Future<int> countPages(Uint8List b, String name) async {
  final d = await _open(b, name);
  try {
    return d.pages.length;
  } finally {
    await d.dispose();
  }
}

Future<Uint8List?> renderPng(PdfPage page,
    {required double scale, int maxSide = 3000}) async {
  var w = page.width * scale;
  var h = page.height * scale;
  final big = w > h ? w : h;
  if (big > maxSide) {
    final k = maxSide / big;
    w *= k;
    h *= k;
  }
  final wi = w.round().clamp(1, maxSide).toInt();
  final hi = h.round().clamp(1, maxSide).toInt();
  final img = await page.render(
      width: wi,
      height: hi,
      fullWidth: wi.toDouble(),
      fullHeight: hi.toDouble());
  if (img == null) return null;
  try {
    final u = await img.createImage();
    final data = await u.toByteData(format: ui.ImageByteFormat.png);
    u.dispose();
    return data?.buffer.asUint8List();
  } finally {
    img.dispose();
  }
}

Future<OutFile> mergePdfs(List<Picked> files) async {
  ensurePdfInit();
  final docs = <PdfDocument>[];
  try {
    for (final f in files) {
      try {
        docs.add(await PdfDocument.openData(f.bytes, sourceName: f.name));
      } catch (_) {
        throw FormatException(
            'تعذر فتح "${f.name}". تأكد أنه PDF صالح وغير محمي بكلمة مرور.');
      }
    }
    final data = await _build([for (final d in docs) ...d.pages], 'merged.pdf');
    return OutFile('merged.pdf', data, _pdf);
  } finally {
    for (final d in docs) {
      await d.dispose();
    }
  }
}

Future<List<OutFile>> extractPages(
    Uint8List b, String base, int n, Map<String, String> o) async {
  final idx = parsePages(o['pages'] ?? '', n);
  final src = await _open(b, '$base.pdf');
  try {
    final pages = src.pages;
    final name = '${base}_extract.pdf';
    final data = await _build([for (final i in idx) pages[i]], name);
    return [OutFile(name, data, _pdf)];
  } finally {
    await src.dispose();
  }
}

Future<List<OutFile>> deletePages(
    Uint8List b, String base, int n, Map<String, String> o) async {
  final del = parsePages(o['pages'] ?? '', n, unique: false).toSet();
  if (del.length >= n) {
    throw const FormatException('لا يمكن حذف كل الصفحات');
  }
  final src = await _open(b, '$base.pdf');
  try {
    final pages = src.pages;
    final name = '${base}_edited.pdf';
    final data = await _build(
        [for (var i = 0; i < n; i++) if (!del.contains(i)) pages[i]], name);
    return [OutFile(name, data, _pdf)];
  } finally {
    await src.dispose();
  }
}

Future<List<OutFile>> rotatePages(
    Uint8List b, String base, int n, Map<String, String> o) async {
  final txt = (o['pages'] ?? '').trim();
  final sel = txt.isEmpty
      ? {for (var i = 0; i < n; i++) i}
      : parsePages(txt, n, unique: false).toSet();
  final angle = o['angle'] ?? '90';
  PdfPage turn(PdfPage p) => angle == '180'
      ? p.rotated180()
      : angle == '270'
          ? p.rotatedCCW90()
          : p.rotatedCW90();
  final src = await _open(b, '$base.pdf');
  try {
    final pages = src.pages;
    final name = '${base}_rotated.pdf';
    final data = await _build(
        [for (var i = 0; i < n; i++) sel.contains(i) ? turn(pages[i]) : pages[i]],
        name);
    return [OutFile(name, data, _pdf)];
  } finally {
    await src.dispose();
  }
}

Future<List<OutFile>> splitPdf(
    Uint8List b, String base, int n, Map<String, String> o) async {
  final every = o['every'] == 'true';
  if (every && n > 200) {
    throw const FormatException('التقسيم الكامل مدعوم حتى 200 صفحة');
  }
  final groups = every
      ? [for (var i = 0; i < n; i++) [i]]
      : parseGroups(o['ranges'] ?? '', n);
  if (groups.length > 200) {
    throw const FormatException('الحد الأقصى 200 ملف في كل مرة');
  }
  final src = await _open(b, '$base.pdf');
  try {
    final pages = src.pages;
    final out = <OutFile>[];
    for (final g in groups) {
      final name = g.length == 1
          ? '${base}_p${g.first + 1}.pdf'
          : '${base}_p${g.first + 1}-${g.last + 1}.pdf';
      out.add(OutFile(name, await _build([for (final i in g) pages[i]], name), _pdf));
    }
    return out;
  } finally {
    await src.dispose();
  }
}

Future<List<OutFile>> pdfToImages(
    Uint8List b, String base, int n, Map<String, String> o) async {
  final txt = (o['pages'] ?? '').trim();
  final idx = txt.isEmpty ? [for (var i = 0; i < n; i++) i] : parsePages(txt, n);
  if (idx.length > 30) {
    throw const FormatException(
        'الحد الأقصى 30 صفحة في كل مرة. اختر نطاقًا أصغر.');
  }
  final dpi = double.tryParse(o['dpi'] ?? '') ?? 150;
  final src = await _open(b, '$base.pdf');
  try {
    final out = <OutFile>[];
    for (final i in idx) {
      final png = await renderPng(src.pages[i], scale: dpi / 72);
      if (png == null) throw Exception('render failed');
      out.add(OutFile('${base}_p${i + 1}.png', png, 'image/png'));
    }
    return out;
  } finally {
    await src.dispose();
  }
}
